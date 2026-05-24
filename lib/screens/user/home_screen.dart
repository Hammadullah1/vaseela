import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/donation_model.dart';
import '../../models/notification_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onHunger;
  final VoidCallback onEducation;
  final VoidCallback onCapital;
  final VoidCallback onHealthcare;
  final VoidCallback onShelter;
  final VoidCallback onWater;
  final VoidCallback onChooseCause;
  final VoidCallback onWallet;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.onHunger,
    required this.onEducation,
    required this.onCapital,
    required this.onHealthcare,
    required this.onShelter,
    required this.onWater,
    required this.onChooseCause,
    required this.onWallet,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SafeArea(
        child: StreamBuilder<List<DonationModel>>(
          stream: FirestoreService.userDonations(),
          builder: (context, snapshot) {
            final donations = snapshot.data ?? [];
            final totalDonated = donations
                .where((d) => d.status == 'verified' || d.status == 'pending' || d.status == 'disbursed')
                .fold<double>(0, (acc, d) => acc + d.amount);

            return SingleChildScrollView(
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
                        // User Info Row with Actions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.volunteer_activism,
                                  color: AppColors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            // User Name Section
                            Expanded(
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Loading...',
                                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                        SizedBox(height: 2),
                                        Text('Ready to help someone today?',
                                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                                      ],
                                    );
                                  }
                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  final name = data['name'] ?? 'User';
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      const Text('Ready to help someone today? 🌿',
                                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Action Buttons
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logout button
                                Material(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: widget.onLogout,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.logout,
                                            color: AppColors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Notifications button
                                StreamBuilder<int>(
                                  stream: NotificationService.getUnreadCount(),
                                  builder: (context, snapshot) {
                                    final unreadCount = snapshot.data ?? 0;
                                    return Material(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => _showNotificationOverlay(unreadCount),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Stack(
                                            children: [
                                              const Icon(
                                                Icons.notifications_outlined,
                                                color: AppColors.white,
                                                size: 22,
                                              ),
                                              if (unreadCount > 0)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 14,
                                                      minHeight: 14,
                                                    ),
                                                    child: Text(
                                                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                                    color:
                                        AppColors.white.withValues(alpha: 0.7)),
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
                                '${donations.length} transactions',
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        AppColors.white.withValues(alpha: 0.6)),
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
                              onTap: widget.onHunger,
                            ),
                            const SizedBox(width: 10),
                            _QuickDonateCard(
                              icon: Icons.school,
                              label: 'Education',
                              color: const Color(0xFF1976D2),
                              onTap: widget.onEducation,
                            ),
                            const SizedBox(width: 10),
                            _QuickDonateCard(
                              icon: Icons.account_balance,
                              label: 'Capital',
                              color: AppColors.gold,
                              onTap: widget.onCapital,
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
                          onTap: widget.onChooseCause,
                        ),
                        const SizedBox(height: 10),
                        _ActionTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'My Wallet',
                          subtitle: 'View transactions & balance',
                          onTap: widget.onWallet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showNotificationOverlay(int currentUnread) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: currentUnread > 0 ? () {
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                NotificationService.markAllAsRead(uid);
                                Navigator.pop(context);
                              }
                            } : null,
                            child: Text(
                              currentUnread > 0 ? 'Mark all read' : 'All caught up',
                              style: TextStyle(
                                fontSize: 12, 
                                color: currentUnread > 0 ? AppColors.primaryGreen : AppColors.textGrey,
                                fontWeight: currentUnread > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textGrey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildNotificationsPanel(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsPanel() {
    return StreamBuilder<List<NotificationModel>>(
      stream: NotificationService.getUserNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryGreen),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_none, color: AppColors.primaryGreen.withValues(alpha: 0.4), size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your donation updates will appear here',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Only show relevant user notifications (verified, rejected, disbursement)
        // AND optionally only show unread ones if that's what the user prefers, 
        // but typically we show all and highlight unread.
        // The user mentioned "read all then it does not again", 
        // implying they might want unread ones to be the focus.
        final notifications = snapshot.data!.where((n) {
          final isUserType = n.type != 'team_change' && n.type != 'new_payment';
          return isUserType;
        }).toList();

        if (notifications.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No relevant notifications', style: TextStyle(color: AppColors.textGrey)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
          itemBuilder: (context, index) {
            final n = notifications[index];
            IconData icon;
            Color iconColor;

            switch (n.type) {
              case 'payment_verified':
                icon = Icons.check_circle_outline;
                iconColor = AppColors.primaryGreen;
                break;
              case 'payment_rejected':
                icon = Icons.error_outline;
                iconColor = Colors.red;
                break;
              case 'disbursement':
                icon = Icons.volunteer_activism_outlined;
                iconColor = AppColors.gold;
                break;
              default:
                icon = Icons.notifications_outlined;
                iconColor = AppColors.primaryGreen;
            }

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon, 
                  color: n.isRead ? AppColors.textGrey : iconColor, 
                  size: 22,
                ),
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                  color: n.isRead ? AppColors.textGrey : AppColors.textDark,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  n.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: n.isRead ? AppColors.textLight : AppColors.textDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
              onTap: () {
                NotificationService.markAsRead(n.id);
                // Optionally show detail or just stay in list
              },
            );
          },
        );
      },
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
              child: Icon(icon, color: AppColors.primaryGreen, size: 20),
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
