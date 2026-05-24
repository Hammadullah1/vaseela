import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/audit_service.dart';
import '../../constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  final VoidCallback onAdminLoggedIn;
  final VoidCallback onSwitchToRegister;

  const LoginScreen({
    super.key,
    required this.onLoggedIn,
    required this.onAdminLoggedIn,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  bool _isAdmin = false;
  int _failedAttempts = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleAdmin(bool value) {
    setState(() {
      _isAdmin = value;
      _error = null;
    });
    if (value) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    
    final error = await AuthService.loginUser(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!context.mounted) return; // CRITICAL CRASH FIX

    if (error != null) {
      setState(() {
        _error = error;
        _loading = false;
        _failedAttempts++;
      });
      return;
    }

    // Reset failed attempts on successful login
    _failedAttempts = 0;

    if (_isAdmin) {
      final isAdmin = await AuthService.isCurrentUserAdmin();
      if (!context.mounted) return;

      if (isAdmin) {
        // Log admin login
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            final userData = userDoc.data();
            if (userData != null) {
              await AuditService.logAdminLogin(
                actorId: user.uid,
                actorName: userData['name'] ?? 'Unknown',
                actorRole: userData['role'] ?? 'Admin',
              );
            }
          }
        } catch (e) {
          // Silent fail for audit logging
          debugPrint('Failed to log admin login: $e');
        }

        if (mounted) setState(() => _loading = false);
        widget.onAdminLoggedIn();
      } else {
        await AuthService.logout();
        if (mounted) {
          setState(() {
            _error = 'This account does not have admin privileges.';
            _loading = false;
          });
        }
      }
      return;
    }

    if (mounted) setState(() => _loading = false);
    widget.onLoggedIn();
  }

  void _showForgotPasswordDialog(BuildContext context, bool isAdminCheck) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter your registered email',
            labelText: 'Email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;

              final email = emailCtrl.text.trim();
              
              // If admin side, verify user is admin and has permission
              if (isAdminCheck) {
                try {
                  // Check if user exists and is admin
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: email)
                      .get();
                  
                  if (userQuery.docs.isEmpty) {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No account found with this email.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                  final userData = userQuery.docs.first.data();
                  final isAdmin = userData['isAdmin'] == true;
                  final role = userData['role'] ?? 'Volunteer';
                  
                  if (!isAdmin) {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This email is not registered as an admin.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                  if (role == 'Revoked' || role == 'revoked') {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Your admin access has been revoked. Contact super admin.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                } catch (e) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error verifying admin: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }
              
              // For regular users, check if they exist in the database
              if (!isAdminCheck) {
                try {
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: email)
                      .get();
                  
                  if (userQuery.docs.isEmpty) {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No account found with this email. Please sign up first.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }
                } catch (e) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error checking account: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }
              
              Navigator.pop(ctx);

              // Show loading snackbar so user knows it is working
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sending reset email...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reset email sent. Check your inbox.'),
                      backgroundColor: Color(0xFF28A745),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((_) {
      emailCtrl.dispose();
    });
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool isPassword = false, IconData? prefixIcon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _isAdmin ? const Color(0xFF1E1E1E) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isAdmin ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword ? _obscure : false,
        style: TextStyle(
          fontSize: 14,
          color: _isAdmin ? AppColors.white : AppColors.textDark,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: _isAdmin ? Colors.white38 : AppColors.textGrey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _isAdmin ? const Color(0xFF1E1E1E) : AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  size: 20,
                  color: _isAdmin ? Colors.white24 : AppColors.textLight)
              : null,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: _isAdmin ? Colors.white30 : AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isAdmin ? AppColors.darkBg : AppColors.lightGreen,
      body: SafeArea(
        child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            decoration: BoxDecoration(
              gradient: _isAdmin
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A1A),
                        Colors.grey.shade900,
                      ],
                    )
                  : AppColors.headerGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isAdmin
                        ? AppColors.gold.withValues(alpha: 0.15)
                        : AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.volunteer_activism,
                    color: AppColors.gold,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isAdmin ? 'Admin Login' : 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isAdmin
                      ? 'Enter your admin credentials'
                      : 'Sign in to continue donating',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),

          // Admin toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isAdmin ? const Color(0xFF1E1E1E) : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: _isAdmin ? 0.2 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: _isAdmin
                    ? Border.all(
                        color: AppColors.gold.withValues(alpha: 0.25))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isAdmin
                          ? AppColors.gold.withValues(alpha: 0.12)
                          : AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isAdmin ? Icons.shield_outlined : Icons.person_outline,
                      color:
                          _isAdmin ? AppColors.gold : AppColors.primaryGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I am an Admin',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isAdmin
                                ? AppColors.white
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _isAdmin
                              ? 'Admin mode enabled'
                              : 'Toggle to login as admin',
                          style: TextStyle(
                            fontSize: 10,
                            color: _isAdmin ? Colors.white38 : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAdmin,
                    onChanged: _toggleAdmin,
                    activeThumbColor: AppColors.gold,
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
                    inactiveThumbColor: AppColors.textLight,
                    inactiveTrackColor: AppColors.divider,
                  ),
                ],
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  if (_isAdmin)
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.25),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.admin_panel_settings,
                            color: AppColors.gold, size: 32),
                      ),
                    ),

                  _buildField('Email', _emailController,
                      prefixIcon: Icons.email_outlined),
                  _buildField('Password', _passwordController,
                      isPassword: true, prefixIcon: Icons.lock_outline),

                  // Error message
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.errorRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.errorRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.errorRed)),
                          ),
                        ],
                      ),
                    ),

                  // Forgot Password suggestion after multiple failed attempts
                  if (_failedAttempts >= 3)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: AppColors.primaryGreen, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Forgot your password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _showForgotPasswordDialog(context, _isAdmin),
                            child: const Text(
                              'Tap here to reset your password',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isAdmin ? AppColors.gold : AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: (_isAdmin
                                ? AppColors.gold
                                : AppColors.primaryGreen)
                            .withValues(alpha: 0.4),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.white))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isAdmin)
                                  const Icon(Icons.login, size: 18),
                                if (_isAdmin) const SizedBox(width: 8),
                                Text(
                                  _isAdmin ? 'Login as Admin' : 'Sign In',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _showForgotPasswordDialog(context, _isAdmin),
                    style: TextButton.styleFrom(
                      foregroundColor: _isAdmin ? Colors.white : AppColors.primaryGreen,
                      overlayColor: _isAdmin ? Colors.yellow.withValues(alpha: 0.1) : AppColors.primaryGreen.withValues(alpha: 0.1),
                    ),
                    child: Text('Forgot Password?', 
                      style: TextStyle(color: _isAdmin ? Colors.white : AppColors.primaryGreen)),
                  ),
                  if (!_isAdmin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 12, color: AppColors.textGrey),
                        ),
                      GestureDetector(
                        onTap: widget.onSwitchToRegister,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}
