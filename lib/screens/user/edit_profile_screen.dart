import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newEmailController = TextEditingController();
  
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        final data = userDoc.data();
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() {
  _loading = true;
  _error = null;
  _success = null;
});

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });

        if (!context.mounted) return; // CRASH PREVENTER

        setState(() => _success = 'Profile updated successfully');
      }
    } catch (e) {
      if (!context.mounted) return; // CRASH PREVENTER
      setState(() => _error = 'Error updating profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateEmail(String newEmail, String currentPassword) async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(newEmail);
      
      if (!context.mounted) return; // CRASH PREVENTER
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification sent to new email. Please verify to complete change.')));
    } catch (e) {
      if (!context.mounted) return; // CRASH PREVENTER
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showEmailUpdateDialog() {
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newEmailCtrl,
              decoration: const InputDecoration(
                labelText: 'New Email',
                hintText: 'Enter new email address',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                hintText: 'Enter your current password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newEmailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')));
                return;
              }
              Navigator.pop(ctx);
              _updateEmail(newEmailCtrl.text.trim(), passwordCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Update Email', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error/Success Messages
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

            // Profile Fields
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Your email address',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            TextButton.icon(
              onPressed: _showEmailUpdateDialog,
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('Change Email Address'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryGreen),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
