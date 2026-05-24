import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';

class ScreenHome extends StatelessWidget {
  final double totalDonated;
  final List<Transaction> transactions;
  final VoidCallback onHunger;
  final VoidCallback onEducation;
  final VoidCallback onCapital;
  final VoidCallback onChooseCause;
  final VoidCallback onWallet;
  final VoidCallback onDisbursed;
  final VoidCallback onRequests;

  const ScreenHome({
    super.key,
    required this.totalDonated,
    required this.transactions,
    required this.onHunger,
    required this.onEducation,
    required this.onCapital,
    required this.onChooseCause,
    required this.onWallet,
    required this.onDisbursed,
    required this.onRequests,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.volunteer_activism,
                                color: AppColors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vaseela',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                'Making a difference',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: AppColors.white, size: 22),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Total donated card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Donated',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PKR ${totalDonated.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${transactions.length} transactions',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Donate
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Donate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickDonateCard(
                        icon: Icons.restaurant,
                        label: 'Hunger',
                        color: const Color(0xFFE53935),
                        onTap: onHunger,
                      ),
                      const SizedBox(width: 10),
                      _QuickDonateCard(
                        icon: Icons.school,
                        label: 'Education',
                        color: const Color(0xFF1976D2),
                        onTap: onEducation,
                      ),
                      const SizedBox(width: 10),
                      _QuickDonateCard(
                        icon: Icons.account_balance,
                        label: 'Capital',
                        color: AppColors.gold,
                        onTap: onCapital,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.favorite_outline,
                    title: 'Choose a Cause',
                    subtitle: 'Browse and select causes to support',
                    onTap: onChooseCause,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'My Wallet',
                    subtitle: 'View transactions & balance',
                    onTap: onWallet,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.verified_outlined,
                    title: 'Disbursements',
                    subtitle: 'Track where your money goes',
                    onTap: onDisbursed,
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.list_alt,
                    title: 'Donation Requests',
                    subtitle: 'View & fulfill active requests',
                    onTap: onRequests,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickDonateCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickDonateCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
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
            const Icon(Icons.chevron_right,
                color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
