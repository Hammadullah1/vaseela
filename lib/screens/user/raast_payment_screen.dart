import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/reference_generator.dart';
import '../../constants/app_colors.dart';
import '../../widgets/payment_slip.dart';
import 'dart:convert';

const _green = Color(0xFF1A6B3C);
const _accent = Color(0xFF28A745);
const _lightGreen = Color(0xFFE8F5EE);

class RaastPaymentScreen extends StatefulWidget {
  final double amount;
  final String cause;
  final VoidCallback onPaymentDone;
  final VoidCallback onBack;

  const RaastPaymentScreen({
    super.key,
    required this.amount,
    required this.cause,
    required this.onPaymentDone,
    required this.onBack,
  });

  @override
  State<RaastPaymentScreen> createState() =>
      _RaastPaymentScreenState();
}

class _RaastPaymentScreenState
    extends State<RaastPaymentScreen> {

  // State
  bool _loadingSettings = true;
  bool _creatingRecord = false;
  bool _uploading = false;
  bool _submitted = false;

  // Data
  String _adminIban = '';
  String _adminName = 'Vaseela Foundation';
  String? _reference;
  String? _donationId;

  // Screenshot
  File? _screenshot;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ── Load admin IBAN from Firestore ──────────────────────
  void _loadSettings() {
    FirestoreService.paymentSettings().listen(
      (settings) async {
        if (!mounted) return;

        final iban = (settings['iban'] as String?)
                ?.trim()
                .isNotEmpty ==
            true
            ? settings['iban'] as String
            : '';

        final name =
            (settings['recipientName'] as String?)
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? settings['recipientName'] as String
                : 'Vaseela Foundation';

        setState(() {
          _adminIban = iban;
          _adminName = name;
          _loadingSettings = false;
        });

        // Create donation record and reference number
        if (iban.isNotEmpty && _donationId == null) {
          await _createRecord();
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _loadingSettings = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Settings error: $e'),
                backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  // ── Create donation record with reference ───────────────
  Future<void> _createRecord() async {
    if (_creatingRecord || _donationId != null) return;
    setState(() => _creatingRecord = true);

    try {
      final result =
          await ReferenceGenerator.createDonationRecord(
        amount: widget.amount,
        cause: widget.cause,
        adminIban: _adminIban,
      );
      if (mounted) {
        setState(() {
          _donationId = result['donationId'];
          _reference = result['reference'];
          _creatingRecord = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creatingRecord = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Copy IBAN and show snackbar ─────────────────────────
  void _copyIban() {
    Clipboard.setData(ClipboardData(text: _adminIban));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle,
              color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('IBAN copied — open your banking app and paste'),
        ]),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Pick screenshot ─────────────────────────────────────
  Future<void> _pickImage() async {
    setState(() => _imageError = null);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.length();
        if (bytes > 300 * 1024) {
          setState(() {
            _imageError =
                'Image too large. Please pick a smaller screenshot.';
          });
          return;
        }
        setState(() => _screenshot = file);
      }
    } catch (e) {
      setState(() => _imageError = 'Could not pick image: $e');
    }
  }

  // ── Submit payment with screenshot ──────────────────────
  Future<void> _submit() async {
    if (_screenshot == null || _donationId == null) return;
    setState(() => _uploading = true);

    try {
      final bytes = await _screenshot!.readAsBytes();
      final base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('donations')
          .doc(_donationId)
          .update({
        'screenshotBase64': base64Image,
        'status': 'pending_verification',
        'paymentConfirmedAt':
            FieldValue.serverTimestamp(),
      });

      // Notify all admins about new payment
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        final donorName = userData?['name'] ?? 'A donor';
        
        await NotificationService.createNewPaymentNotification(
          donorName: donorName,
          amount: widget.amount,
          cause: widget.cause,
          donationId: _donationId!,
        );
      }

      if (mounted) {
        setState(() {
          _uploading = false;
          _submitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: SafeArea(
        child: Column(children: [
        _buildHeader(),
        Expanded(
          child: _loadingSettings
              ? const Center(
                  child: CircularProgressIndicator(
                      color: _green))
              : _adminIban.isEmpty
                  ? _buildNoIban()
                  : _buildBody(),
        ),
      ]),
    ));
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: widget.onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16),
          ),
        ),
        const SizedBox(width: 14),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bank Transfer',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(
                  'PKR ${widget.amount.toStringAsFixed(0)} · ${widget.cause}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70)),
            ]),
      ]),
    );
  }

  // ── Main body ───────────────────────────────────────────
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // Payment slip
        PaymentSlip(
          amount: widget.amount,
          cause: widget.cause,
          reference: _reference ?? 'Generating...',
          adminIban: _adminIban,
          adminName: _adminName,
        ),

        const SizedBox(height: 20),

        // Big copy IBAN button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _copyIban,
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: const Text('Copy IBAN and Open Banking App',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // After payment section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('After Paying',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 4),
            const Text(
                'Upload a screenshot of your payment confirmation.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45)),
            const SizedBox(height: 16),

            // Image error
            if (_imageError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_imageError!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red))),
                ]),
              ),

            // Pick screenshot
            if (_screenshot == null)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 24),
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            _accent.withValues(alpha: 0.4)),
                  ),
                  child: const Column(children: [
                    Icon(Icons.upload_file_rounded,
                        color: _green, size: 32),
                    SizedBox(height: 8),
                    Text('Tap to upload screenshot',
                        style: TextStyle(
                            color: _green,
                            fontWeight:
                                FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('From your gallery',
                        style: TextStyle(
                            color: Colors.black38,
                            fontSize: 12)),
                  ]),
                ),
              )
            else
              Column(children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child: Image.file(
                    _screenshot!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _screenshot = null),
                        icon: const Icon(Icons.close,
                            size: 16,
                            color: Colors.red),
                        label: const Text('Remove',
                            style: TextStyle(
                                color: Colors.red)),
                      ),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.refresh,
                            size: 16),
                        label: const Text('Change'),
                        style: TextButton.styleFrom(
                            foregroundColor: _green),
                      ),
                    ]),
              ]),

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_screenshot == null ||
                        _uploading)
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Text('Submit Payment Proof',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700)),
              ),
            ),

          ]),
        ),

        const SizedBox(height: 30),
      ]),
    );
  }

  // ── No IBAN configured ──────────────────────────────────
  Widget _buildNoIban() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          const Icon(Icons.account_balance,
              color: Colors.black26, size: 48),
          const SizedBox(height: 16),
          const Text('Payment not configured yet',
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
              'Admin needs to set the IBAN in Admin Panel → Settings',
              style: TextStyle(
                  color: Colors.black38, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: widget.onBack,
            child: const Text('Go Back'),
          ),
        ]),
      ),
    );
  }

  // ── Success screen ──────────────────────────────────────
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.check_rounded,
                  color: _accent, size: 44),
            ),
            const SizedBox(height: 24),
            const Text('JazakAllah Khair! 🌿',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _green)),
            const SizedBox(height: 8),
            Text(
                'PKR ${widget.amount.toStringAsFixed(0)} for ${widget.cause}',
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            if (_reference != null)
              Text('Reference: $_reference',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                      letterSpacing: 1)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFF5A623)
                        .withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.hourglass_top_rounded,
                    color: Color(0xFFF5A623), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your donation is pending verification. Admin will confirm your transfer shortly.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onPaymentDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home',
                    style: TextStyle(
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      )),
    );
  }
}
