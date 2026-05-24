import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/audit_service.dart';

/// Widget that guards admin screens with real-time access monitoring.
/// 
/// When an admin's privileges are revoked (isAdmin/isSuper becomes false),
/// this widget immediately shows a restricted view and prevents access
/// to admin functionality.
///
/// Usage:
/// ```dart
/// AdminAccessGuard(
///   child: YourAdminScreenContent(),
/// )
/// ```
class AdminAccessGuard extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdminAccessGuard({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  State<AdminAccessGuard> createState() => _AdminAccessGuardState();
}

class _AdminAccessGuardState extends State<AdminAccessGuard> {
  bool _accessRevoked = false;
  bool _isLoggingOut = false;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _userId = FirestoreService.getCurrentUid();
  }

  Future<void> _performLogout({bool revoked = false}) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      if (!revoked) {
        // Normal logout - try to log audit
        try {
          final userData = await FirestoreService.getUser(_userId);
          if (userData != null) {
            await AuditService.logAction(
              action: AuditActionType.logout,
              actorId: _userId,
              actorName: userData['name'] ?? 'Unknown',
              actorRole: userData['role'] ?? (userData['isAdmin'] == true ? 'Admin' : 'User'),
            );
          }
        } catch (e) {
          // Silent fail
        }
      }
      await AuthService.logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    } finally {
      _isLoggingOut = false;
    }
  }

  void _handleAccessRevoked() {
    if (!_accessRevoked && mounted) {
      setState(() => _accessRevoked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your admin access has been revoked. You will be logged out.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildRestrictedView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Revoked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your admin privileges have been removed by another administrator. You no longer have access to this area.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _performLogout(revoked: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Return to Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService.getUserStream(_userId),
      builder: (context, snapshot) {
        // Monitor for access revocation
        if (snapshot.hasData && snapshot.data != null && !_accessRevoked) {
          final userData = snapshot.data!;
          final hasAdminAccess = userData['isAdmin'] == true || userData['isSuper'] == true;

          if (!hasAdminAccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAccessRevoked();
            });
          }
        }

        if (_accessRevoked) {
          return _buildRestrictedView();
        }

        return Scaffold(
          appBar: widget.appBar,
          body: widget.child,
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }
}
