import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'audit_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  /// Current Firebase user (null if not logged in)
  static User? get currentUser => _auth.currentUser;

  /// Register a new user with email & password, then create Firestore profile
  /// Returns null on success, or error message. On success, user is signed out
  /// and must verify email before logging in.
  static Future<String?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) return 'Registration failed. Please try again.';

      final uid = user.uid;

      // 🔥 Send verification email BEFORE creating Firestore doc
      // This ensures email is sent even if Firestore fails
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        // If email fails, delete the user and return error
        await user.delete();
        return 'Failed to send verification email: ${e.message}. Please try again.';
      }

      // Check if there is a pre-assigned role for this email
      final inviteSnap = await FirebaseFirestore.instance.collection('invites').doc(email.trim()).get();
      bool isAdmin = false;
      String? role;
      
      if (inviteSnap.exists) {
        isAdmin = true;
        role = inviteSnap.data()?['role'];
        // Delete the invite after use
        await FirebaseFirestore.instance.collection('invites').doc(email.trim()).delete();
      }

      // Create Firestore profile
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'isAdmin': isAdmin,
        if (isAdmin) 'role': role,
        'totalDonated': 0,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔴 CRITICAL: Sign out immediately so user cannot access app without verification
      await _auth.signOut();

      return null; // Success - verification email sent
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use': return 'This email is already registered. Please log in instead.';
        case 'weak-password': return 'Password must be at least 6 characters.';
        case 'invalid-email': return 'Please enter a valid email address.';
        default: return 'Registration failed: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Login with email & password - blocks unverified users
  static Future<String?> loginUser({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null && !user.emailVerified) {
        // User not verified - sign them out and block login
        await _auth.signOut();
        return 'Please verify your email before logging in. Check your inbox for the verification link.';
      }

      // Update emailVerified status in Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'emailVerified': true,
        });

        // Log login
        final userData = await FirestoreService.getUser(user.uid);
        if (userData != null) {
          await AuditService.logAction(
            action: AuditActionType.login,
            actorId: user.uid,
            actorName: userData['name'] ?? 'Unknown',
            actorRole: userData['role'] ?? (userData['isAdmin'] == true ? 'Admin' : 'User'),
          );
        }
      }

      return null; 
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found': return 'No account found with this email. Please register first.';
        case 'wrong-password': return 'Incorrect password. Please try again.';
        case 'invalid-credential': return 'Invalid email or password.';
        case 'user-disabled': return 'This account has been disabled.';
        case 'too-many-requests': return 'Too many attempts. Please try again later.';
        default: return 'Login failed: ${e.message}';
      }
    }
  }

  /// Check if current user's email is verified
  static bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Resend verification email
  static Future<String?> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';
      if (user.emailVerified) return 'Email already verified';
      
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return 'Failed to send: ${e.message}';
    }
  }

  /// Refresh user data and check verification status
  static Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    await user.reload();
    return user.emailVerified;
  }

  /// Check if the current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return await FirestoreService.isAdmin(user.uid);
  }

  /// Sign out
  static Future<void> logout() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await FirestoreService.getUser(user.uid);
        if (userData != null) {
          await AuditService.logAction(
            action: AuditActionType.logout,
            actorId: user.uid,
            actorName: userData['name'] ?? 'Unknown',
            actorRole: userData['role'] ?? (userData['isAdmin'] == true ? 'Admin' : 'User'),
          );
        }
      } catch (e) {
        // Silent fail for logout logging
      }
    }
    await _auth.signOut();
  }

  /// Listen to auth state changes
  static Stream<User?> authStateChanges() => _auth.authStateChanges();
}
