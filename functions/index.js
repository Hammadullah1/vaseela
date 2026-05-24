const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Groq = require("groq-sdk");

admin.initializeApp();

exports.verifyPaymentScreenshot = functions
  .runWith({ timeoutSeconds: 60, memory: "512MB" })
  .https.onCall(async (data, context) => {

  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required");
  }

  const {
    imageBase64,
    mimeType,
    expectedAmount,
    expectedIban,
    donationId,
  } = data;

  if (!imageBase64 || !donationId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing image or donationId");
  }

  const groq = new Groq({ apiKey: functions.config().groq.key });

  const prompt = `You are a payment verification assistant for a Pakistani charity app called Vaseela.

A user uploaded a screenshot claiming to show a completed bank transfer.

Expected payment details:
- Amount: PKR ${expectedAmount}
- Recipient IBAN: ${expectedIban}

Carefully examine the screenshot and check ALL five things:
1. Does it look like a real Pakistani banking app UI? (HBL, Meezan, UBL, MCB, JazzCash, Easypaisa, SadaPay, NayaPay, Faysal, Bank Alfalah, etc.)
2. Does it clearly show a SUCCESSFUL or COMPLETED status? (Not pending, not failed, not processing)
3. Does the transfer amount match PKR ${expectedAmount}? (Allow up to 2% difference for rounding)
4. Does the recipient IBAN, account number, or name match or partially match "${expectedIban}"?
5. Is the transaction date today or within the last 24 hours?

You MUST respond with ONLY this JSON. No explanation, no markdown, no backticks, no extra text:
{"verdict":"approved","confidence":90,"amountMatch":true,"recipientMatch":true,"statusSuccess":true,"looksAuthentic":true,"dateValid":true,"reason":"All five checks passed. HBL app, PKR 2500 confirmed, IBAN matches, status completed, dated today."}

Rules for verdict:
- "approved" = looksAuthentic AND statusSuccess AND amountMatch AND confidence >= 80
- "review" = looksAuthentic is true but some other check is unclear or confidence is 60-79
- "rejected" = looksAuthentic is false OR statusSuccess is false OR amount is clearly wrong`;

  try {
    const response = await groq.chat.completions.create({
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      max_tokens: 250,
      temperature: 0.1,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image_url",
              image_url: {
                url: `data:${mimeType || "image/jpeg"};base64,${imageBase64}`,
              },
            },
            {
              type: "text",
              text: prompt,
            },
          ],
        },
      ],
    });

    const raw = response.choices[0].message.content.trim();
    const clean = raw.replace(/```json|```/g, "").trim();

    let result;
    try {
      result = JSON.parse(clean);
    } catch (parseError) {
      result = {
        verdict: "review",
        confidence: 50,
        amountMatch: false,
        recipientMatch: false,
        statusSuccess: false,
        looksAuthentic: false,
        dateValid: false,
        reason: "AI response could not be parsed. Sent for manual review.",
      };
    }

    // Enforce verdict logic server-side as a safety check
    if (result.verdict === "approved" && result.confidence < 80) {
      result.verdict = "review";
      result.reason += " (confidence too low for auto-approval)";
    }

    const newStatus =
      result.verdict === "approved"
        ? "pending"
        : result.verdict === "review"
        ? "pending_verification"
        : "screenshot_rejected";

    await admin.firestore()
      .collection("donations")
      .doc(donationId)
      .update({
        aiVerification: result,
        screenshotStatus: result.verdict,
        screenshotVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: newStatus,
      });

    return result;

  } catch (e) {
    console.error("Groq error:", e.message);

    await admin.firestore()
      .collection("donations")
      .doc(donationId)
      .update({
        screenshotStatus: "review",
        status: "pending_verification",
        aiError: e.message,
      });

    return {
      verdict: "review",
      confidence: 0,
      amountMatch: false,
      recipientMatch: false,
      statusSuccess: false,
      looksAuthentic: false,
      dateValid: false,
      reason: "Verification service unavailable. Sent for manual review.",
    };
  }
});
