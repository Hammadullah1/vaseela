import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/audit_service.dart';
import '../../models/donation_model.dart';
import '../../models/notification_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/admin_access_guard.dart';
import '../user/donor_detail_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isSuper = false;
  String _myRole = 'Volunteer';
  String _myName = '';
  String _myId = '';

  void _showAdminNotifications() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Admin Notifications',
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
                padding: const EdgeInsets.all(20),
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
                            'Admin Updates',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              NotificationService.markAllAsRead(_myId);
                              Navigator.pop(context);
                            },
                            child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
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
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: StreamBuilder<List<NotificationModel>>(
                          stream: NotificationService.getAdminNotifications(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryGreen),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
                            }
                            final notifs = snapshot.data ?? [];
                            if (notifs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.notifications_none, size: 48, color: AppColors.textGrey.withValues(alpha: 0.3)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No team updates', 
                                      style: TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Team changes and new payments will appear here',
                                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              itemCount: notifs.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
                              itemBuilder: (context, i) {
                                final n = notifs[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: n.isRead ? Colors.grey.shade100 : AppColors.primaryGreen.withValues(alpha: 0.1),
                                    child: Icon(
                                      n.type == 'team_change' ? Icons.group_outlined : Icons.payments_outlined,
                                      color: n.isRead ? Colors.grey : AppColors.primaryGreen,
                                      size: 18,
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
                                  subtitle: Text(
                                    n.message, 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis, 
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: n.isRead ? AppColors.textLight : AppColors.textDark.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  onTap: () {
                                    NotificationService.markAsRead(n.id);
                                    _showAdminNotificationDetail(n);
                                  },
                                );
                              },
                            );
                          },
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

  void _showAdminNotificationDetail(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                  child: Icon(
                    notification.type == 'team_change' ? Icons.group_outlined : Icons.payments_outlined,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              notification.message,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Received on: ${notification.createdAt.toString().split('.')[0]}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirestoreService.getCurrentUid();
    _myId = uid;
    final data = await FirestoreService.getUser(uid);
    if (mounted && data != null) {
      setState(() {
        _isSuper = data['isSuper'] == true;
        _myRole = data['role'] ?? 'Volunteer';
        _myName = data['name'] ?? 'Admin';
      });
    }
  }

  Future<String> _getCurrentUserName() async {
    final uid = FirestoreService.getCurrentUid();
    final data = await FirestoreService.getUser(uid);
    return data?['name'] ?? 'Admin';
  }

  Future<void> _performLogout() async {
    try {
      final userData = await FirestoreService.getUser(_myId);
      if (userData != null) {
        await AuditService.logAdminLogout(
          actorId: _myId,
          actorName: userData['name'] ?? 'Unknown',
          actorRole: _myRole,
        );
      }
    } catch (e) {
      // Silent fail for audit logging
    }
    await AuthService.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminAccessGuard(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D3D21), Color(0xFF1A6B3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Admin Panel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Admin Notifications
          StreamBuilder<int>(
            stream: NotificationService.getAdminUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: _showAdminNotifications,
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // User Mode Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text(
                'User Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Logout Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: _performLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Verifications'),
            Tab(text: 'Disbursements'),
            Tab(text: 'Settings'),
            Tab(text: 'Team'),
            Tab(text: 'Donors'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (context, _) {
          final isTeamTab = _tab.index == 3;
          final canAdd = _isSuper || _myRole == 'Manager';
          if (isTeamTab && canAdd) {
            return FloatingActionButton(
              backgroundColor: AppColors.primaryGreen,
              child: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () => _showAddMemberDialog(context),
            );
          }
          return const SizedBox();
        },
      ),
      child: SafeArea(
        child: TabBarView(
          controller: _tab,
          children: [
            _PendingVerificationsTab(myId: _myId, myRole: _myRole),
            _DisbursementsTab(myId: _myId, myRole: _myRole),
            const _SettingsTab(),
            _TeamTab(
                isSuper: _isSuper, myRole: _myRole, myName: _myName, myId: _myId),
            const _DonorsTab(),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Employee';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Team Member', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Assign Role'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: selectedRole,
                    items: (_isSuper ? ['Manager', 'Employee', 'Volunteer'] : ['Employee', 'Volunteer'])
                        .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => selectedRole = v!),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
                  );
                  return;
                }
                try {
                  await FirestoreService.preAssignRole(emailCtrl.text.trim(), selectedRole);
                  
                  // Notify all team members about new member
                  final actorName = await _getCurrentUserName();
                  await NotificationService.notifyTeamChange(
                    actionType: 'added',
                    targetUserName: nameCtrl.text.trim(),
                    oldRole: null,
                    newRole: selectedRole,
                    actorName: actorName,
                  );
                  
                  // Log team member added
                  await AuditService.logTeamMemberAdded(
                    actorId: _myId,
                    actorName: actorName,
                    actorRole: _myRole,
                    newMemberId: emailCtrl.text.trim(), // Using email as placeholder until they register
                    newMemberEmail: emailCtrl.text.trim(),
                    newMemberRole: selectedRole,
                  );
                  
                  if (mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$selectedRole role reserved! Please ask ${nameCtrl.text.trim()} to register using ${emailCtrl.text.trim()} in the app.'),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Create Member'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Dispose controllers after dialog closes
      nameCtrl.dispose();
      emailCtrl.dispose();
      passCtrl.dispose();
    });
  }
}

// ─── Tab 1: Pending Verifications ────────────────────────────────

class _PendingVerificationsTab extends StatelessWidget {
  final String myId;
  final String myRole;
  const _PendingVerificationsTab({required this.myId, required this.myRole});

  Future<Map<String, dynamic>> _loadDonorDetails(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() ?? {};
  }

  void _showScreenshot(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    child: Image.memory(
                      base64Decode(url),
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.error, color: Colors.red),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String donationId, String userId, String myId, String myRole) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Not Received', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason why the payment was not received:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Screenshot unclear, payment not found in account, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason'), backgroundColor: Colors.red),
                );
                return;
              }
              // Pop dialog immediately before async
              Navigator.pop(ctx);
              try {
                await FirestoreService.rejectDonation(donationId, reasonCtrl.text.trim());
                
                // Get donation details and send notification to user
                final donationDoc = await FirebaseFirestore.instance.collection('donations').doc(donationId).get();
                if (donationDoc.exists) {
                  final donationData = donationDoc.data() as Map<String, dynamic>;
                  await NotificationService.createPaymentRejectedNotification(
                    userId: userId,
                    amount: (donationData['amount'] ?? 0).toDouble(),
                    cause: donationData['cause'] ?? 'Unknown',
                    reason: reasonCtrl.text.trim(),
                    donationId: donationId,
                  );
                  // Log the rejection
                  final actorData = await FirestoreService.getUser(myId);
                  await AuditService.logPaymentRejected(
                    actorId: myId,
                    actorName: actorData?['name'] ?? 'Unknown',
                    actorRole: myRole,
                    donationId: donationId,
                    donorName: donationData['donorName'] ?? 'Unknown',
                    amount: (donationData['amount'] ?? 0).toDouble(),
                    cause: donationData['cause'] ?? 'Unknown',
                    reason: reasonCtrl.text.trim(),
                  );
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Donation marked as not received. User notified.'), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    ).then((_) {
      reasonCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DonationModel>>(
      stream: FirestoreService.pendingVerifications(),
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error: ${snap.error}', textAlign: TextAlign.center)));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Center(child: Text('No pending verifications',
              style: TextStyle(color: AppColors.textGrey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final d = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with amount and action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PKR ${d.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primaryGreen)),
                            Text(d.cause,
                                style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      // Compact action buttons using icons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // View Screenshot
                          IconButton(
                            icon: const Icon(Icons.image, color: AppColors.primaryGreen, size: 20),
                            tooltip: 'View Screenshot',
                            onPressed: () => _showScreenshot(context, d.screenshotBase64),
                          ),
                          // Verify
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                            tooltip: 'Verify Payment',
                            onPressed: () async {
                              await FirestoreService.updateDonationStatus(
                                  d.id, 'verified');
                              await NotificationService.createPaymentVerifiedNotification(
                                userId: d.userId,
                                amount: d.amount,
                                cause: d.cause,
                                donationId: d.id,
                              );
                              // Log the verification
                              final actorData = await FirestoreService.getUser(myId);
                              final actorName = actorData?['name'] ?? 'Admin';
                              final donorData = await FirestoreService.getUser(d.userId);
                              await AuditService.logPaymentVerified(
                                actorId: myId,
                                actorName: actorName,
                                actorRole: myRole,
                                donationId: d.id,
                                donorName: donorData?['name'] ?? 'Unknown',
                                amount: d.amount,
                                cause: d.cause,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Payment verified and user notified'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                          // Reject
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.orange, size: 24),
                            tooltip: 'Mark Not Received',
                            onPressed: () => _showRejectDialog(context, d.id, d.userId, myId, myRole),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // Donor info with screenshot indicator
                  FutureBuilder<Map<String, dynamic>>(
                    future: _loadDonorDetails(d.userId),
                    builder: (ctx, snap) {
                      final user = snap.data ?? {};
                      return Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text('${user['email'] ?? ''} • ${user['phone'] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                          // Screenshot badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.image, size: 12, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Screenshot',
                                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// ─── Tab 2: Disbursements ────────────────────────────────────────

class _DisbursementsTab extends StatefulWidget {
  final String myId;
  final String myRole;
  const _DisbursementsTab({this.myId = '', this.myRole = ''});

  @override
  State<_DisbursementsTab> createState() => _DisbursementsTabState();
}

class _DisbursementsTabState extends State<_DisbursementsTab> {
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _selectedCause = 'hunger';
  File? _proofImage;
  bool _processing = false;
  String? _imageError;
  static const int _maxImageSizeBytes = 200 * 1024; // 200KB limit for free tier

  Future<void> _exportAuditLogs() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating audit report...')),
      );

      try {
        final logs = await AuditService.getAuditLogsForExport(
          startDate: picked.start,
          endDate: picked.end.add(const Duration(days: 1)),
        );

        if (logs.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No logs found for selected range')),
            );
          }
          return;
        }

        // Prepare CSV data
        List<List<dynamic>> csvData = [
          ['Timestamp', 'Action', 'Actor', 'Role', 'Target', 'Amount', 'Cause', 'Details']
        ];

        for (var log in logs) {
          final ts = (log['timestamp'] as Timestamp?)?.toDate();
          final action = AuditService.getActionDisplayName(log['action'] ?? '');
          final actor = log['actorName'] ?? 'Unknown';
          final role = log['actorRole'] ?? '';
          final target = log['targetName'] ?? '';
          final amount = log['amount']?.toString() ?? '';
          final cause = log['cause'] ?? '';
          final details = jsonEncode(log['details'] ?? {});

          csvData.add([
            ts != null ? DateFormat('yyyy-MM-dd HH:mm').format(ts) : '',
            action,
            actor,
            role,
            target,
            amount,
            cause,
            details,
          ]);
        }

        String csvString = const ListToCsvConverter().convert(csvData);
        final directory = await getTemporaryDirectory();
        final path = "${directory.path}/audit_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";
        final file = File(path);
        await file.writeAsString(csvString);

        await Share.shareXFiles([XFile(path)], text: 'Vaseela Audit Report');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _pickProof() async {
    setState(() => _imageError = null);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Aggressive compression for free tier
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.length();
        
        if (bytes > _maxImageSizeBytes) {
          setState(() {
            _imageError = 'Image too large (${(bytes / 1024).toStringAsFixed(0)}KB). Max size is 200KB for free tier.';
            _proofImage = null;
          });
          return;
        }
        
        setState(() => _proofImage = file);
      }
    } catch (e) {
      setState(() => _imageError = 'Failed to pick image: $e');
    }
  }

  void _clearImage() {
    setState(() {
      _proofImage = null;
      _imageError = null;
    });
  }

  Stream<Map<String, double>> _causeBalancesStream() {
    // Real-time stream of donations with available remaining amount
    // Only count fully verified donations (status = 'verified')
    return FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: 'verified')
        .snapshots()
        .map((snapshot) {
      final Map<String, double> balances = {
        'hunger': 0, 'education': 0, 'capital': 0, 'healthcare': 0, 'shelter': 0, 'water': 0,
      };

      for (final doc in snapshot.docs) {
        final d = doc.data();
        final status = d['status'] as String? ?? '';
        
        // Only count funds that have been fully verified by an admin
        if (status != 'verified') continue;

        final rawCause = (d['cause'] as String? ?? '').toLowerCase().trim();
        final amount = (d['amount'] as num? ?? 0).toDouble();
        final remaining = (d['remainingAmount'] as num? ?? amount).toDouble();
        
        // Find matching key even if it's slightly different
        String? matchKey;
        if (balances.containsKey(rawCause)) {
          matchKey = rawCause;
        } else if (rawCause.contains('hunger')) {
          matchKey = 'hunger';
        } else if (rawCause.contains('edu')) {
          matchKey = 'education';
        } else if (rawCause.contains('cap')) {
          matchKey = 'capital';
        } else if (rawCause.contains('health')) {
          matchKey = 'healthcare';
        } else if (rawCause.contains('shelter')) {
          matchKey = 'shelter';
        } else if (rawCause.contains('water')) {
          matchKey = 'water';
        }

        if (matchKey != null && remaining > 0.01) {
          balances[matchKey] = balances[matchKey]! + remaining;
        }
      }
      return balances;
    });
  }

  Widget _causeChip(String label, String cause, Map<String, double> balances) {
    final balance = balances[cause] ?? 0;
    final isSelected = _selectedCause == cause;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedCause = cause),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PKR ${balance.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white70 : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadDonorsForCause(String cause) async {
    // Note: Removed orderBy to avoid composite index requirement.
    // Firestore doesn't allow inequality + orderBy on different fields without index.
    final snap = await FirebaseFirestore.instance
        .collection('donations')
        .where('cause', isEqualTo: cause)
        .where('status', isEqualTo: 'verified')
        .get();

    // Sort by createdAt in memory to avoid composite index
    final sortedDocs = snap.docs.toList()
      ..sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return aTime.compareTo(bTime);
      });

    final Map<String, double> userTotals = {};
    final Map<String, List<String>> userDonIds = {};

    for (final doc in sortedDocs) {
      final d = doc.data();
      final uid = d['userId'] as String?;
      if (uid == null) continue;
      
      final amount = (d['amount'] as num? ?? 0).toDouble();
      final remaining = (d['remainingAmount'] as num? ?? amount).toDouble();
      
      userTotals[uid] = (userTotals[uid] ?? 0) + remaining;
      userDonIds.putIfAbsent(uid, () => []).add(doc.id);
    }

    final result = <Map<String, dynamic>>[];
    for (final uid in userTotals.keys) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      result.add({
        'userId': uid,
        'name': userData['name'] ?? 'Unknown',
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'availableBalance': userTotals[uid],
        'donationIds': userDonIds[uid],
      });
    }
    return result;
  }

  Future<void> _handleDisburse() async {
    final amt = double.tryParse(_amountCtrl.text) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload proof of disbursement')));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a disbursement reason')));
      return;
    }
    
    setState(() => _processing = true);
    try {
      final bytes = await _proofImage!.readAsBytes();
      
      // Validate image can be encoded
      String base64Proof;
      try {
        base64Proof = base64Encode(bytes);
        if (base64Proof.isEmpty) {
          throw Exception('Image encoding failed');
        }
      } catch (e) {
        throw Exception('Invalid image file. Please try another image.');
      }
      
      await FirestoreService.disburseFunds(_selectedCause, amt, base64Proof, _reasonCtrl.text.trim());
      
      // Note: Donor notifications are already sent inside disburseFunds()
      // with exact per-donor allocation amounts
      
      // Log the disbursement with actual disbursement ID
      final actorData = await FirestoreService.getUser(widget.myId);
      // Get the latest disbursement to get the ID
      final disbursementsSnap = await FirebaseFirestore.instance
          .collection('disbursements')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      String disbursementId = 'unknown';
      if (disbursementsSnap.docs.isNotEmpty) {
        disbursementId = disbursementsSnap.docs.first.id;
      }
      
      await AuditService.logFundsDisbursed(
        actorId: widget.myId,
        actorName: actorData?['name'] ?? 'Unknown',
        actorRole: widget.myRole,
        disbursementId: disbursementId,
        amount: amt,
        cause: _selectedCause,
        reason: _reasonCtrl.text.trim(),
        donorCount: 0, // This could be calculated from affected donations
      );

      _amountCtrl.clear();
      _reasonCtrl.clear();
      setState(() => _proofImage = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Funds disbursed successfully! Donors have been notified.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cause Summary Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Funds by Cause', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              const SizedBox(height: 12),
              StreamBuilder<Map<String, double>>(
                stream: _causeBalancesStream(),
                builder: (context, snapshot) {
                  final balances = snapshot.data ?? {};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Available Balances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textGrey)),
                          TextButton.icon(
                            onPressed: _exportAuditLogs,
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export Audit', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _causeChip('Hunger', 'hunger', balances),
                          _causeChip('Education', 'education', balances),
                          _causeChip('Capital', 'capital', balances),
                          _causeChip('Healthcare', 'healthcare', balances),
                          _causeChip('Shelter', 'shelter', balances),
                          _causeChip('Water', 'water', balances),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Disburse Verified Funds', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isDense: true,
                          isExpanded: true,
                          value: _selectedCause,
                          items: ['hunger', 'education', 'capital', 'healthcare', 'shelter', 'water'].map((c) => DropdownMenuItem(value: c, child: Text(c.capitalize()))).toList(),
                          onChanged: (v) => setState(() => _selectedCause = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Amount', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(hintText: 'Disbursement Reason (e.g. Bought 20 Bags of Flour)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              ),
              const SizedBox(height: 10),
              // Image Preview Section
              if (_proofImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _proofImage!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<int>(
                              future: _proofImage!.length(),
                              builder: (context, snapshot) {
                                final size = snapshot.data ?? 0;
                                return Text(
                                  'Size: ${(size / 1024).toStringAsFixed(1)} KB',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                );
                              },
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _clearImage,
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Error Message
              if (_imageError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _imageError!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _pickProof,
                      icon: Icon(
                        _proofImage != null ? Icons.refresh : Icons.camera_alt,
                        color: _proofImage != null ? AppColors.primaryGreen : null,
                      ),
                      label: Text(_proofImage != null ? 'Change Image' : 'Upload Proof Image'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_processing || _proofImage == null) ? null : _handleDisburse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: _processing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Disburse'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadDonorsForCause(_selectedCause),
            builder: (ctx, snap) {
              if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error: ${snap.error}', textAlign: TextAlign.center)));
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final donors = snap.data!;
              if (donors.isEmpty) {
                return Center(child: Text('No donors found for $_selectedCause',
                    style: TextStyle(color: AppColors.textGrey)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: donors.length,
                itemBuilder: (ctx, i) {
                  final donor = donors[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(donor['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textDark)),
                                  Text(donor['email'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  Text(donor['phone'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PKR ${(donor['availableBalance'] as double).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryGreen),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('$_selectedCause • ${(donor['donationIds'] as List).length} donations',
                            style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tab 3: Settings ─────────────────────────────────────────────

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _ibanCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    FirestoreService.paymentSettings().listen(
      (settings) {
        if (mounted) {
          _ibanCtrl.text = settings['iban'] ?? '';
          _nameCtrl.text = settings['recipientName'] ?? '';
        }
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Settings load failed: $e')),
          );
        }
      },
    );
  }

  Future<void> _save() async {
    final iban = _ibanCtrl.text.trim().toUpperCase();
    if (!iban.startsWith('PK') || iban.length != 24) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid IBAN. Must start with PK and be 24 characters.')));
      }
      return;
    }
    
   setState(() {
  _loading = true;
  _error = null;
  _success = null;
});
    try {
      await FirestoreService.updatePaymentSettings(
          iban, _nameCtrl.text.trim());
      if (!context.mounted) return; // CRASH PREVENTER
      setState(() => _success = 'Settings updated successfully');
    } catch (e) {
      if (!context.mounted) return; // CRASH PREVENTER
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen)),
          const SizedBox(height: 8),
          const Text(
              'These details will be shown to donors during the payment process.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),
          if (_success != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_success!, style: const TextStyle(color: Colors.green, fontSize: 13)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _ibanCtrl,
            decoration: const InputDecoration(
              labelText: 'Admin IBAN (24 chars)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Recipient Name',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Settings',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 4: Team Management ────────────────────────────────────

class _TeamTab extends StatefulWidget {
  final bool isSuper;
  final String myRole;
  final String myName;
  final String myId;
  const _TeamTab({required this.isSuper, required this.myRole, required this.myName, required this.myId});

  @override
  State<_TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<_TeamTab> {
  String _searchQuery = '';

  Future<String> _getCurrentUserName() async {
    final uid = FirestoreService.getCurrentUid();
    final data = await FirestoreService.getUser(uid);
    return data?['name'] ?? 'Admin';
  }

  // Hierarchy: Boss (Super) > Manager > Employee > Volunteer
  // Boss can fire anyone (including other bosses, but must keep at least one)
  // Manager can fire Employee and Volunteer
  // Employee can fire Volunteer
  // Volunteer cannot fire anyone (read-only)
  bool _canFire(bool targetIsSuper, String targetRole, String targetUid) {
    // Boss (Super Admin) can fire anyone including other bosses
    // But cannot fire self if they're the last boss
    if (widget.isSuper) {
      // If target is also a boss, check if we can remove them
      if (targetIsSuper) {
        // Boss can remove other bosses, or themselves if not the last one
        return true;
      }
      return true;
    }
    
    // Cannot fire the Boss
    if (targetIsSuper) return false;
    
    // Define hierarchy levels
    const levels = {'Manager': 3, 'Employee': 2, 'Volunteer': 1};
    final myLevel = levels[widget.myRole] ?? 0;
    final targetLevel = levels[targetRole] ?? 0;
    
    // Can only fire people below your level
    return myLevel > targetLevel;
  }
  
  bool _canChangeRole(bool targetIsSuper, String targetRole, String targetUid) {
    // Same logic as fire
    return _canFire(targetIsSuper, targetRole, targetUid);
  }

  /// Show dialog to add a new boss
  Future<void> _showAddBossDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => const _AddBossDialog(),
    );
  }

  /// Show confirmation dialog for removing a boss
  Future<bool> _showRemoveBossConfirmDialog(String bossName, bool isSelf) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(isSelf ? 'Remove Yourself as Boss?' : 'Remove Boss?', style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSelf
                  ? 'Are you sure you want to remove yourself as Boss? You will be demoted to Manager.'
                  : 'Are you sure you want to remove $bossName as Boss? They will be demoted to Manager.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Stepping down, Policy change',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: At least one Boss must remain in the system.',
              style: TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    return confirm == true;
  }

  Future<void> _editMyProfile(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['name']);
    final emailCtrl = TextEditingController(text: user['email']);
    final phoneCtrl = TextEditingController(text: user['phone']);
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit My Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Changing email here only updates your display info. To change login email, use Firebase settings.',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                setDialogState(() => loading = true);
                try {
                  await FirebaseFirestore.instance.collection('users').doc(user['uid']).update({
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Update failed: $e')),
                    );
                  }
                } finally {
                  setDialogState(() => loading = false);
                }
              },
              child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        // Add Boss button for current bosses
        if (widget.isSuper)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddBossDialog,
                icon: const Icon(Icons.star, color: Colors.white),
                label: const Text('Add New Boss', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        // Pending Bosses Section
        if (widget.isSuper)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.getPendingBosses(),
            builder: (ctx, pendingSnap) {
              if (!pendingSnap.hasData || pendingSnap.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final pendingBosses = pendingSnap.data!;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hourglass_empty, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Pending Bosses (${pendingBosses.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...pendingBosses.map((boss) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              boss['email'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              boss['status'] == 'pending_login' ? 'Pending Login' : boss['status'] ?? 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        // Team Members List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.getAllUsers(),
            builder: (ctx, snap) {
              if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error: ${snap.error}', textAlign: TextAlign.center)));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              
              final users = snap.data!.where((u) {
                final isAdmin = u['isAdmin'] == true;
                final isSuper = u['isSuper'] == true;
                final hasRole = u.containsKey('role') && u['role'] != null;
                if (!isAdmin && !isSuper && !hasRole) return false;
                
                final name = (u['name'] ?? '').toString().toLowerCase();
                final email = (u['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();
              
              if (users.isEmpty) return const Center(child: Text('No matching members found'));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (ctx, i) {
                  final user = users[i];
                  final uid = user['uid'] ?? '';
                  final isAdmin = user['isAdmin'] == true;
                  final isSuperUser = user['isSuper'] == true;
                  final role = user['role'] ?? 'Volunteer';
                  final canIFire = _canFire(isSuperUser, role, uid);
                  final canIChangeRole = _canChangeRole(isSuperUser, role, uid);
                  final isMe = uid == widget.myId;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSuperUser ? AppColors.gold : (isAdmin ? AppColors.primaryGreen : Colors.grey.shade200),
                        child: Icon(isSuperUser ? Icons.star : Icons.person, color: isAdmin || isSuperUser ? Colors.white : Colors.grey),
                      ),
                      title: Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: isAdmin && !isSuperUser 
                        ? DropdownButton<String>(
                            value: role,
                            isDense: true,
                            underline: const SizedBox(),
                            disabledHint: Text(role, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            style: const TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                            items: canIChangeRole 
                              ? ['Manager', 'Employee', 'Volunteer'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList()
                              : null,
                            onChanged: canIChangeRole ? (newRole) async {
                              if (newRole != null && newRole != role) {
                                final actorName = await _getCurrentUserName();
                                
                                await FirestoreService.toggleAdminAccess(user['uid'], true, role: newRole);
                                
                                // Log role change
                                await AuditService.logRoleChanged(
                                  actorId: widget.myId,
                                  actorName: actorName,
                                  actorRole: widget.myRole,
                                  targetId: user['uid'],
                                  targetName: user['name'] ?? 'Unknown',
                                  oldRole: role,
                                  newRole: newRole,
                                );
                                
                                // Notify all team members about role change
                                await NotificationService.notifyTeamChange(
                                  actionType: 'role_changed',
                                  targetUserName: user['name'] ?? 'Unknown',
                                  oldRole: role,
                                  newRole: newRole,
                                  actorName: actorName,
                                );
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${user['name']}\'s role changed from $role to $newRole. Team notified.')),
                                  );
                                }
                              }
                            } : null,
                          )
                        : Text(user['email'] ?? 'No Email', style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSuperUser && isMe)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen),
                              tooltip: 'Edit my profile',
                              onPressed: () => _editMyProfile(user),
                            ),
                          // Boss removal button (for bosses to remove themselves or other bosses)
                          if (isSuperUser && widget.isSuper && canIFire)
                            IconButton(
                              icon: const Icon(Icons.star_border, color: Colors.orange),
                              tooltip: isMe ? 'Remove yourself as Boss' : 'Remove Boss status',
                              onPressed: () async {
                                final confirm = await _showRemoveBossConfirmDialog(user['name'] ?? 'Unknown', isMe);
                                if (confirm == true) {
                                  try {
                                    // Check if this is the last boss
                                    final canRemove = await FirestoreService.canRemoveBoss(uid);
                                    if (!canRemove) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cannot remove the last Boss. At least one Boss must remain.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    
                                    final actorName = await _getCurrentUserName();
                                    
                                    // Log boss removal
                                    await AuditService.logAction(
                                      action: AuditActionType.bossRemoved,
                                      actorId: widget.myId,
                                      actorName: actorName,
                                      actorRole: widget.myRole,
                                      targetId: uid,
                                      targetName: user['name'] ?? 'Unknown',
                                      targetRole: 'Boss',
                                      details: {'isSelf': isMe},
                                    );
                                    
                                    // Remove boss status (demote to Manager)
                                    await FirestoreService.removeBoss(uid, deleteAccount: false);
                                    
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isMe 
                                            ? 'You have been demoted from Boss to Manager'
                                            : '${user['name']} has been demoted from Boss to Manager'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          // Regular team member removal
                          if (!isSuperUser && canIFire)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Remove from team',
                              onPressed: () async {
                                final reasonCtrl = TextEditingController();
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove Team Member'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Remove ${user['name']} from the team?'),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: reasonCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Reason (optional)',
                                            hintText: 'e.g., Inactive, Policy violation',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  final actorName = await _getCurrentUserName();
                                  final reason = reasonCtrl.text.trim();
                                  
                                  // Record deleted user for audit trail
                                  await AuditService.recordDeletedUser(
                                    userId: user['uid'],
                                    name: user['name'] ?? 'Unknown',
                                    email: user['email'] ?? '',
                                    role: role,
                                    deletedById: widget.myId,
                                    deletedByName: actorName,
                                    reason: reason.isEmpty ? 'No reason provided' : reason,
                                  );
                                  
                                  await AuditService.logTeamMemberRemoved(
                                    actorId: widget.myId,
                                    actorName: actorName,
                                    actorRole: widget.myRole,
                                    removedMemberId: user['uid'],
                                    removedMemberName: user['name'] ?? 'Unknown',
                                    removedMemberRole: role,
                                    reason: reason.isEmpty ? 'No reason provided' : reason,
                                  );
                                  
                                  await FirebaseFirestore.instance.collection('users').doc(user['uid']).update({
                                    'isAdmin': false,
                                    'role': FieldValue.delete(),
                                  });
                                  
                                  // Notify all team members about removal
                                  await NotificationService.notifyTeamChange(
                                    actionType: 'removed',
                                    targetUserName: user['name'] ?? 'Unknown',
                                    oldRole: role,
                                    newRole: null,
                                    actorName: actorName,
                                  );
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${user['name']} removed from team. Team notified.')),
                                    );
                                  }
                                  reasonCtrl.dispose();
                                } else {
                                  reasonCtrl.dispose();
                                }
                              },
                            ),
                          if (isSuperUser)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'BOSS',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Switch(
                              value: isAdmin,
                              activeThumbColor: AppColors.primaryGreen,
                              onChanged: canIChangeRole ? (val) async {
                                await FirestoreService.toggleAdminAccess(user['uid'], val, role: role);
                              } : null,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tab 5: Donors List ────────────────────────────────────

class _DonorsTab extends StatefulWidget {
  const _DonorsTab();

  @override
  State<_DonorsTab> createState() => _DonorsTabState();
}

class _DonorsTabState extends State<_DonorsTab> {
  // Cache the stream to avoid recreating it on every build
  late final Stream<List<QueryDocumentSnapshot>> _donorStream;
  Set<String> _previousDonorIds = {};

  @override
  void initState() {
    super.initState();
    // Note: Removed orderBy to avoid composite index requirement.
    // Fetch all users and filter/sort in memory instead.
    _donorStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
          // Filter users with donations and sort in memory
          final docs = snapshot.docs.where((d) {
            final data = d.data();
            final total = (data['totalDonated'] ?? 0).toDouble();
            return total > 0;
          }).toList();
          
          // Sort by totalDonated descending
          docs.sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aTotal = (aData['totalDonated'] ?? 0).toDouble();
            final bTotal = (bData['totalDonated'] ?? 0).toDouble();
            return bTotal.compareTo(aTotal); // descending
          });
          
          return docs;
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _donorStream,
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error: ${snap.error}', textAlign: TextAlign.center)));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final donors = snap.data!;
        
        // Check for new donors and show snackbar
        final currentDonorIds = donors.map((d) => d.id).toSet();
        if (_previousDonorIds.isNotEmpty) {
          final newDonors = currentDonorIds.difference(_previousDonorIds);
          if (newDonors.isNotEmpty && mounted) {
            // Find the new donor name
            final newDonorDoc = donors.firstWhere((d) => newDonors.contains(d.id));
            final newDonorData = newDonorDoc.data() as Map<String, dynamic>;
            final newDonorName = newDonorData['name'] ?? 'A new donor';
            final newDonorAmount = (newDonorData['totalDonated'] ?? 0).toDouble();
            
            // Show snackbar after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 $newDonorName just donated PKR ${newDonorAmount.toStringAsFixed(0)}!'),
                    backgroundColor: AppColors.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            });
          }
        }
        _previousDonorIds = currentDonorIds;
        
        if (donors.isEmpty) {
          return const Center(child: Text('No donors found', style: TextStyle(color: AppColors.textGrey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donors.length,
          itemBuilder: (ctx, i) {
            final donor = donors[i];
            final data = donor.data() as Map<String, dynamic>;
            final totalDonated = (data['totalDonated'] ?? 0).toDouble();

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonorDetailScreen(userId: donor.id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['phone'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'PKR ${totalDonated.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (data['isAdmin'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Add Boss Dialog Widget ────────────────────────────────────

class _AddBossDialog extends StatefulWidget {
  const _AddBossDialog();

  @override
  State<_AddBossDialog> createState() => _AddBossDialogState();
}

class _AddBossDialogState extends State<_AddBossDialog> {
  late final TextEditingController _emailCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<String> _getCurrentUserName() async {
    final uid = FirestoreService.getCurrentUid();
    final data = await FirestoreService.getUser(uid);
    return data?['name'] ?? 'Admin';
  }

  Future<void> _addBoss() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await FirestoreService.addBossByEmail(_emailCtrl.text.trim());
      final actorName = await _getCurrentUserName();
      final myId = FirestoreService.getCurrentUid();
      final myData = await FirestoreService.getUser(myId);
      final myRole = myData?['role'] ?? 'Admin';

      // Log boss added action
      await AuditService.logAction(
        action: AuditActionType.bossAdded,
        actorId: myId,
        actorName: actorName,
        actorRole: myRole,
        targetName: _emailCtrl.text.trim(),
        targetRole: 'Boss',
        details: {'status': result['status']},
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        final status = result['status'];
        final message = status == 'existing_user_promoted'
            ? '${result['name']} has been promoted to Boss!'
            : 'Boss invite sent to ${result['email']}. They will become a Boss on first login.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: status == 'existing_user_promoted' ? AppColors.gold : Colors.grey,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.star, color: AppColors.gold),
          SizedBox(width: 8),
          Text('Add New Boss', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter the email of the user you want to promote to Boss. If the user already exists, they will be promoted immediately. If not, they will become a Boss on their first login.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'boss@example.com',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
          ),
          onPressed: _loading ? null : _addBoss,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add Boss'),
        ),
      ],
    );
  }
}
