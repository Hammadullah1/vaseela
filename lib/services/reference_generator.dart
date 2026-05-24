import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ReferenceGenerator {
  // Generates unique reference like VSL-2025-00142
  static String generate() {
    final year = DateTime.now().year;
    final random = DateTime.now().millisecondsSinceEpoch % 100000;
    final number = random.toString().padLeft(5, '0');
    return 'VSL-$year-$number';
  }

  // Save reference to Firestore and return donation ID
  static Future<Map<String, String>> createDonationRecord({
    required double amount,
    required String cause,
    required String adminIban,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final reference = generate();

      final docRef = await FirebaseFirestore.instance
          .collection('donations')
          .add({
        'userId': uid,
        'cause': cause,
        'amount': amount,
        'remainingAmount': amount, // Initialize remaining amount
        'adminIban': adminIban,
        'reference': reference,
        'status': 'awaiting_payment',
        'paymentMethod': 'raast',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify all admins about new payment
      await _notifyAdminsOfNewDonation(amount, cause, reference);

      return {
        'donationId': docRef.id,
        'reference': reference,
      };
    } on FirebaseException catch (e) {
      throw Exception('Failed to create donation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create donation: $e');
    }
  }

  // Send notification to all admins when new donation is created
  static Future<void> _notifyAdminsOfNewDonation(
    double amount,
    String cause,
    String reference,
  ) async {
    try {
      // Get all admin users
      final adminQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      for (var adminDoc in adminQuery.docs) {
        final adminId = adminDoc.id;
        
        // Create notification for each admin
        await NotificationService.createAdminNotification(
          adminId: adminId,
          title: 'New Donation Received 💰',
          message:
              'A donation of PKR ${amount.toStringAsFixed(0)} for $cause has been initiated. Reference: $reference',
          type: 'new_donation',
          data: {
            'amount': amount,
            'cause': cause,
            'reference': reference,
          },
        );
      }
    } catch (e) {
      // Silently fail - don't block donation creation if notification fails
      print('Failed to notify admins: $e');
    }
  }
}
