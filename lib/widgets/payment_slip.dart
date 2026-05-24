import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class PaymentSlip extends StatelessWidget {
  final double amount;
  final String cause;
  final String reference;
  final String adminIban;
  final String adminName;

  const PaymentSlip({
    super.key,
    required this.amount,
    required this.cause,
    required this.reference,
    required this.adminIban,
    required this.adminName,
  });

  String get _formattedAmount {
    return 'PKR ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('$label copied to clipboard'),
        ]),
        backgroundColor: const Color(0xFF28A745),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6B3C).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(children: [
              const Text('🌿',
                  style: TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              const Text('Payment Slip',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('Reference: $reference',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1)),
            ]),
          ),

          // Donation details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // Cause and amount row
              _detailRow('Cause', cause),
              const SizedBox(height: 12),
              _amountRow(context),
              const SizedBox(height: 16),

              const Divider(height: 1, color: Color(0xFFE8F5EE)),
              const SizedBox(height: 16),

              // Transfer to section
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Transfer To',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(height: 10),
              _detailRow('Name', adminName),
              const SizedBox(height: 12),

              // IBAN with copy button
              _ibanRow(context),
              const SizedBox(height: 16),

              const Divider(height: 1, color: Color(0xFFE8F5EE)),
              const SizedBox(height: 16),

              // Instructions
              _instructions(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.black45)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
      ],
    );
  }

  Widget _amountRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF28A745).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amount to Transfer',
                    style: TextStyle(
                        fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 2),
                Text(_formattedAmount,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A6B3C))),
              ]),
          GestureDetector(
            onTap: () => _copy(
                context,
                amount.toStringAsFixed(0),
                'Amount'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A6B3C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.copy_rounded,
                    color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Copy',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ibanRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IBAN',
              style: TextStyle(
                  fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  adminIban,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A6B3C),
                      letterSpacing: 1.2),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () =>
                    _copy(context, adminIban, 'IBAN'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6B3C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.copy_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Copy',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _instructions() {
    final steps = [
      ('1', 'Copy the IBAN above',
          Icons.copy_rounded),
      ('2', 'Open your banking app',
          Icons.phone_android_rounded),
      ('3', 'Go to Transfer → Enter IBAN → Enter amount',
          Icons.send_rounded),
      ('4', 'Use reference $reference in remarks',
          Icons.edit_note_rounded),
      ('5', 'Come back here and upload screenshot',
          Icons.upload_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How to Pay',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black45,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        ...steps.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6B3C),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(step.$1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Icon(step.$3,
                size: 16, color: Colors.black38),
            const SizedBox(width: 6),
            Expanded(
              child: Text(step.$2,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87)),
            ),
          ]),
        )),
      ],
    );
  }
}
