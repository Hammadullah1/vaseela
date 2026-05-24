import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';

class ScreenWallet extends StatelessWidget {
  final List<Transaction> transactions;
  final double totalDonated;
  final VoidCallback onBack;

  const ScreenWallet({
    super.key,
    required this.transactions,
    required this.totalDonated,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pending =
        transactions.where((t) => t.status == 'pending').toList();
    final disbursed =
        transactions.where((t) => t.status == 'disbursed').toList();

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
                      'My Wallet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WalletStat(
                          label: 'Total',
                          value: 'PKR ${totalDonated.toStringAsFixed(0)}',
                          color: AppColors.gold),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _WalletStat(
                          label: 'Pending',
                          value: '${pending.length}',
                          color: const Color(0xFFFFA726)),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _WalletStat(
                          label: 'Disbursed',
                          value: '${disbursed.length}',
                          color: AppColors.accentGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transactions
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48,
                            color: AppColors.textGrey.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final isPending = t.status == 'pending';
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isPending
                                    ? const Color(0xFFFFF3E0)
                                    : AppColors.lightGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPending
                                    ? Icons.schedule
                                    : Icons.check_circle_outline,
                                color: isPending
                                    ? const Color(0xFFFFA726)
                                    : AppColors.accentGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${t.date.day}/${t.date.month}/${t.date.year}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'PKR ${t.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? const Color(0xFFFFF3E0)
                                        : AppColors.lightGreen,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPending ? 'Pending' : 'Disbursed',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: isPending
                                          ? const Color(0xFFFFA726)
                                          : AppColors.accentGreen,
                                    ),
                                  ),
                                ),
                              ],
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

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WalletStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: AppColors.white.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
