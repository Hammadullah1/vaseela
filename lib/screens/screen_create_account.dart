import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ScreenCreateAccount extends StatefulWidget {
  final VoidCallback onAccountCreated;
  final VoidCallback onAdminLogin;

  const ScreenCreateAccount({
    super.key,
    required this.onAccountCreated,
    required this.onAdminLogin,
  });

  @override
  State<ScreenCreateAccount> createState() => _ScreenCreateAccountState();
}

class _ScreenCreateAccountState extends State<ScreenCreateAccount>
    with SingleTickerProviderStateMixin {
  // User fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Admin fields
  final _adminIdController = TextEditingController();
  final _adminPassController = TextEditingController();

  bool _obscure = true;
  bool _obscureAdmin = true;
  bool _isAdmin = false;
  String? _adminError;

  // Simulated admin credentials
  static const String _adminId = 'admin';
  static const String _adminPass = 'admin123';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _adminIdController.dispose();
    _adminPassController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleAdmin(bool value) {
    setState(() {
      _isAdmin = value;
      _adminError = null;
    });
    if (value) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _attemptAdminLogin() {
    if (_adminIdController.text.trim() == _adminId &&
        _adminPassController.text.trim() == _adminPass) {
      setState(() => _adminError = null);
      widget.onAdminLogin();
    } else {
      setState(() => _adminError = 'Invalid Admin ID or Password');
    }
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool isPassword = false,
      bool obscure = true,
      VoidCallback? onToggle,
      TextInputType? keyboardType,
      IconData? prefixIcon}) {
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
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboardType,
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
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: _isAdmin ? Colors.white30 : AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildUserForm() {
    return Column(
      children: [
        _buildField('Full Name', _nameController,
            prefixIcon: Icons.person_outline),
        _buildField('Email Address', _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined),
        _buildField('Phone Number', _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined),
        _buildField('Password', _passwordController,
            isPassword: true,
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
            prefixIcon: Icons.lock_outline),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.onAccountCreated,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
              shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Already have an account? ',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            GestureDetector(
              onTap: widget.onAccountCreated,
              child: const Text(
                'Sign In',
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
    );
  }

  Widget _buildAdminForm() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // Admin shield icon
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25), width: 1.5),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: AppColors.gold, size: 32),
          ),
          _buildField('Admin ID', _adminIdController,
              prefixIcon: Icons.badge_outlined),
          _buildField('Admin Password', _adminPassController,
              isPassword: true,
              obscure: _obscureAdmin,
              onToggle: () =>
                  setState(() => _obscureAdmin = !_obscureAdmin),
              prefixIcon: Icons.lock_outline),

          // Error message
          if (_adminError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    child: Text(
                      _adminError!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.errorRed),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _attemptAdminLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColors.gold.withValues(alpha: 0.4),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Login as Admin',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Default: admin / admin123',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isAdmin ? AppColors.darkBg : AppColors.lightGreen,
      body: Column(
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
                  _isAdmin ? 'Admin Login' : 'Create Account',
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
                      : 'Join Vaseela and start making a difference',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isAdmin
                    ? const Color(0xFF1E1E1E)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isAdmin ? 0.2 : 0.06),
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
                      _isAdmin
                          ? Icons.shield_outlined
                          : Icons.person_outline,
                      color: _isAdmin
                          ? AppColors.gold
                          : AppColors.primaryGreen,
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
                            color: _isAdmin
                                ? Colors.white38
                                : AppColors.textGrey,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isAdmin
                    ? _buildAdminForm()
                    : _buildUserForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
