import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ScreenPayment extends StatefulWidget {
  final String cause;
  final double amount;
  final VoidCallback onPaymentDone;
  final VoidCallback onBack;

  const ScreenPayment({
    super.key,
    required this.cause,
    required this.amount,
    required this.onPaymentDone,
    required this.onBack,
  });

  @override
  State<ScreenPayment> createState() => _ScreenPaymentState();
}

class _ScreenPaymentState extends State<ScreenPayment> {
  String _selectedMethod = 'card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Complete your donation',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cause',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey)),
                            Text(widget.cause,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey)),
                            Text(
                                'PKR ${widget.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _PaymentOption(
                    icon: Icons.credit_card,
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, Mastercard',
                    value: 'card',
                    selected: _selectedMethod,
                    onTap: () =>
                        setState(() => _selectedMethod = 'card'),
                  ),
                  const SizedBox(height: 10),
                  _PaymentOption(
                    icon: Icons.account_balance,
                    title: 'Bank Transfer',
                    subtitle: 'Direct bank payment',
                    value: 'bank',
                    selected: _selectedMethod,
                    onTap: () =>
                        setState(() => _selectedMethod = 'bank'),
                  ),
                  const SizedBox(height: 10),
                  _PaymentOption(
                    icon: Icons.account_balance_wallet,
                    title: 'Mobile Wallet',
                    subtitle: 'JazzCash, EasyPaisa',
                    value: 'wallet',
                    selected: _selectedMethod,
                    onTap: () =>
                        setState(() => _selectedMethod = 'wallet'),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: widget.onPaymentDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.gold.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        'Donate PKR ${widget.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14,
                            color: AppColors.textGrey.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Secured by 256-bit encryption',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppColors.textGrey.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.textGrey,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.textLight,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: AppColors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
