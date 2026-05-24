import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/disbursement.dart';

class ScreenDisbursed extends StatelessWidget {
  final List<Disbursement> disbursements;
  final VoidCallback onBack;

  const ScreenDisbursed({
    super.key,
    required this.disbursements,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount =
        disbursements.fold<double>(0, (sum, d) => sum + d.amount);
    final verifiedCount = disbursements.where((d) => d.verified).length;

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
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
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
                    const Text(
                      'Disbursements',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Disbursed',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.white
                                      .withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PKR ${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Verified',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.white
                                      .withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$verifiedCount / ${disbursements.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Disbursement list
          Expanded(
            child: disbursements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 48,
                            color: AppColors.textGrey.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'No disbursements yet',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: disbursements.length,
                    itemBuilder: (context, index) {
                      final d = disbursements[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Image placeholder
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.lightGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.primaryGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PKR ${d.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: d.verified
                                    ? AppColors.lightGreen
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    d.verified
                                        ? Icons.verified
                                        : Icons.schedule,
                                    size: 14,
                                    color: d.verified
                                        ? AppColors.accentGreen
                                        : const Color(0xFFFFA726),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    d.verified ? 'Verified' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: d.verified
                                          ? AppColors.accentGreen
                                          : const Color(0xFFFFA726),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
