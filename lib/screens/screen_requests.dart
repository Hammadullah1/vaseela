import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/donation_request.dart';

class ScreenRequests extends StatelessWidget {
  final List<DonationRequest> requests;
  final Function(int, double) onDonate;
  final VoidCallback onBack;

  const ScreenRequests({
    super.key,
    required this.requests,
    required this.onDonate,
    required this.onBack,
  });

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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donation Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Help fulfill these needs',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Request list
          Expanded(
            child: requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt,
                            size: 48,
                            color: AppColors.textGrey.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'No active requests',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      final progress =
                          r.amount > 0 ? (r.donated / r.amount) : 0.0;
                      final clampedProgress =
                          progress > 1.0 ? 1.0 : progress;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.volunteer_activism,
                                      color: AppColors.primaryGreen,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    r.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: clampedProgress,
                                minHeight: 8,
                                backgroundColor: AppColors.primaryGreen
                                    .withValues(alpha: 0.1),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.accentGreen),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Goal: PKR ${r.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textGrey),
                                ),
                                Text(
                                  'Collected: PKR ${r.donated.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () =>
                                    onDonate(index, 500),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primaryGreen,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                  shadowColor: AppColors.primaryGreen
                                      .withValues(alpha: 0.3),
                                ),
                                child: const Text(
                                  'Donate PKR 500',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
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
