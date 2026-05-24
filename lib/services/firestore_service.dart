import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/donation_model.dart';
import '../models/disbursement_model.dart';
import '../models/request_model.dart';
import 'notification_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ─── Collections ────────────────────────────────────────────
  static CollectionReference get _users => _db.collection('users');
  static CollectionReference get _donations => _db.collection('donations');
  static CollectionReference get _causes => _db.collection('causes');
  static CollectionReference get _settings => _db.collection('settings');
  static CollectionReference get _disbursements => _db.collection('disbursements');

  static String getCurrentUid() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    return user.uid;
  }

  // ─── User ────────────────────────────────────────────────────
  static Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    // Check if there is a pre-assigned role for this email
    final inviteSnap = await _db.collection('invites').doc(email).get();
    bool isAdmin = false;
    String? role;
    bool isSuper = false;

    if (inviteSnap.exists) {
      isAdmin = true;
      role = inviteSnap.data()?['role'];
      // Check if this is a boss invite
      if (role == 'Boss') {
        isSuper = true;
        // Activate the boss invite
        await activateBossOnLogin(email, uid);
      }
      // Delete the invite after use
      await _db.collection('invites').doc(email).delete();
    }

    await _users.doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'isAdmin': isAdmin,
      'isSuper': isSuper,
      'role': role ?? 'Volunteer',
      'totalDonated': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> preAssignRole(String email, String role) async {
    try {
      await _db.collection('invites').doc(email).set({
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You may not have admin privileges to add team members.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in as an admin to add team members.');
      } else if (e.code == 'network-request-failed') {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Failed to create invite: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to create invite: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      return null;
    }
  }

  /// Real-time stream of user document - use for admin access monitoring
  static Stream<Map<String, dynamic>?> getUserStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    });
  }

  static Future<bool> isAdmin(String uid) async {
    final data = await getUser(uid);
    return data?['isAdmin'] == true || data?['isSuper'] == true;
  }

  static Future<bool> isSuperAdmin(String uid) async {
    final data = await getUser(uid);
    return data?['isSuper'] == true;
  }

  static Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _users.limit(100).snapshots().map((s) {
      final list = s.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['uid'] = d.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final ta = a['createdAt'] as Timestamp?;
        final tb = b['createdAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  static Future<void> toggleAdminAccess(String uid, bool isAdmin, {String role = 'Employee'}) async {
    await _users.doc(uid).update({
      'isAdmin': isAdmin,
      if (isAdmin) 'role': role,
    });
  }

  // ─── Boss Management ─────────────────────────────────────────

  /// Get count of current bosses (isSuper == true)
  static Future<int> getBossCount() async {
    try {
      final snap = await _users
          .where('isSuper', isEqualTo: true)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (e) {
      // Fallback: fetch and count
      final snap = await _users.where('isSuper', isEqualTo: true).get();
      return snap.docs.length;
    }
  }

  /// Check if a user can be removed as boss (must keep at least one boss)
  static Future<bool> canRemoveBoss(String uidToRemove) async {
    final currentBossCount = await getBossCount();
    // Can only remove if there's more than one boss
    return currentBossCount > 1;
  }

  /// Add a new boss by email
  /// If user exists, promote to boss. If not, create pending boss invite.
  static Future<Map<String, dynamic>> addBossByEmail(String email) async {
    try {
      // Check if user with this email already exists
      final userQuery = await _users.where('email', isEqualTo: email).limit(1).get();

      if (userQuery.docs.isNotEmpty) {
        // User exists - promote to boss
        final userDoc = userQuery.docs.first;
        final userId = userDoc.id;
        final userData = userDoc.data() as Map<String, dynamic>;

        await _users.doc(userId).update({
          'isSuper': true,
          'isAdmin': true,
          'role': 'Boss',
          'bossPromotedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'status': 'existing_user_promoted',
          'userId': userId,
          'name': userData['name'] ?? 'Unknown',
          'message': 'Existing user promoted to Boss',
        };
      } else {
        // User doesn't exist - create pending boss invite
        await _db.collection('boss_invites').doc(email).set({
          'email': email,
          'role': 'Boss',
          'isSuper': true,
          'status': 'pending_login',
          'createdAt': FieldValue.serverTimestamp(),
          'firstLoginAt': null,
        });

        // Also create regular invite
        await _db.collection('invites').doc(email).set({
          'role': 'Boss',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'status': 'pending_login',
          'email': email,
          'message': 'Boss invite created. User will become boss on first login.',
        };
      }
    } on FirebaseException catch (e) {
      throw Exception('Failed to add boss: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add boss: $e');
    }
  }

  /// Get all pending boss invites
  static Stream<List<Map<String, dynamic>>> getPendingBosses() {
    return _db.collection('boss_invites').snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>?;
        if (data == null) return <String, dynamic>{};
        data['id'] = d.id;
        return data;
      }).toList();
    });
  }

  /// Remove a boss (demote to regular admin or remove completely)
  static Future<void> removeBoss(String uid, {bool deleteAccount = false}) async {
    try {
      // Check if this is the last boss
      final canRemove = await canRemoveBoss(uid);
      if (!canRemove) {
        throw Exception('Cannot remove the last boss. At least one boss must remain.');
      }

      if (deleteAccount) {
        // Remove admin privileges completely
        await _users.doc(uid).update({
          'isSuper': false,
          'isAdmin': false,
          'role': FieldValue.delete(),
        });
      } else {
        // Demote to Manager
        await _users.doc(uid).update({
          'isSuper': false,
          'role': 'Manager',
        });
      }
    } on FirebaseException catch (e) {
      throw Exception('Failed to remove boss: ${e.message}');
    } catch (e) {
      throw Exception('Failed to remove boss: $e');
    }
  }

  /// Mark boss invite as activated when user first logs in
  static Future<void> activateBossOnLogin(String email, String uid) async {
    try {
      final inviteDoc = await _db.collection('boss_invites').doc(email).get();
      if (inviteDoc.exists) {
        await _db.collection('boss_invites').doc(email).update({
          'status': 'active',
          'userId': uid,
          'firstLoginAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silent fail - not critical
      debugPrint('Failed to activate boss invite: $e');
    }
  }

  // ─── Donations ───────────────────────────────────────────────
  // Free tier: Document size limit is 1MB
  static const int _maxDocumentSizeBytes = 900 * 1024; // 900KB safety limit
  
  static Future<void> addDonation({
    required String cause,
    required double amount,
    required String adminIban,
    required String screenshotBase64,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      
      // Validate document won't exceed free tier limit (1MB)
      final estimatedSize = screenshotBase64.length * 2; // Approximate UTF-16 size
      if (estimatedSize > _maxDocumentSizeBytes) {
        throw Exception('Image too large. Please use a smaller image (max ~200KB).');
      }
      
      await _donations.add({
        'userId': uid,
        'cause': cause,
        'amount': amount,
        'remainingAmount': amount,
        'adminIban': adminIban,
        'screenshotBase64': screenshotBase64,
        'status': 'pending_verification',
        'paymentMethod': 'raast',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Cannot add donation.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in to make a donation.');
      } else if (e.code == 'resource-exhausted') {
        throw Exception('Free tier quota exceeded. Please try again later.');
      } else if (e.code == 'invalid-argument' && e.message?.contains('document') == true) {
        throw Exception('Image too large for free tier. Use a smaller image.');
      } else {
        throw Exception('Failed to add donation: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
      throw Exception('Failed to add donation: $e');
    }
  }

  static Stream<List<DonationModel>> userDonations() {
    final uid = _auth.currentUser!.uid;
    return _donations
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final docs = s.docs.map(DonationModel.fromFirestore).toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  static Stream<List<DonationModel>> allDonations() {
    return _donations
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DonationModel.fromFirestore).toList());
  }

  static Stream<List<DonationModel>> pendingVerifications() {
    return _donations
        .where('status', isEqualTo: 'pending_verification')
        .snapshots()
        .map((s) {
          final docs = s.docs.map(DonationModel.fromFirestore).toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }
  
  static Stream<List<DonationModel>> pendingDisbursements() {
    return _donations
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) {
          final docs = s.docs.map(DonationModel.fromFirestore).toList();
          docs.sort((a, b) {
            if (a.verifiedAt == null || b.verifiedAt == null) return 0;
            return b.verifiedAt!.compareTo(a.verifiedAt!);
          });
          return docs;
        });
  }

  static Future<void> updateDonationStatus(String donationId, String newStatus) async {
    try {
      final Map<String, dynamic> updates = {'status': newStatus};
      if (newStatus == 'verified') {
        updates['verifiedAt'] = FieldValue.serverTimestamp();
        
        // When verified, also update the user's totalDonated
        final doc = await _donations.doc(donationId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'];
          final amount = data['amount'];
          if (userId != null && amount != null) {
            await _users.doc(userId).update({
              'totalDonated': FieldValue.increment(amount),
            });
          }
        }
      } else if (newStatus == 'disbursed') {
        updates['disbursedAt'] = FieldValue.serverTimestamp();
      }
      
      await _donations.doc(donationId).update(updates);
    } on FirebaseException catch (e) {
      throw Exception('Failed to update donation status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update donation status: $e');
    }
  }

  static Future<void> rejectDonation(String donationId, String reason) async {
    try {
      await _donations.doc(donationId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Cannot reject donation.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in as admin to reject donations.');
      } else if (e.code == 'resource-exhausted') {
        throw Exception('Free tier quota exceeded. Please try again later.');
      } else {
        throw Exception('Failed to reject donation: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
      throw Exception('Failed to reject donation: $e');
    }
  }

  // ─── Cancel Donation (Boss Only) ────────────────────────────────
  static Future<void> cancelDonation(String donationId, String reason) async {
    try {
      final doc = await _donations.doc(donationId).get();
      if (!doc.exists) {
        throw Exception('Donation not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;

      // Only allow cancelling pending_verification donations
      if (status != 'pending_verification') {
        throw Exception('Can only cancel pending verification donations. Status: $status');
      }

      await _donations.doc(donationId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': _auth.currentUser?.uid,
      }).timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only Boss can cancel donations.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in to cancel donations.');
      } else if (e.code == 'resource-exhausted') {
        throw Exception('Free tier quota exceeded. Please try again later.');
      } else {
        throw Exception('Failed to cancel donation: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
      throw Exception('Failed to cancel donation: $e');
    }
  }

  static Future<void> disburseFunds(String cause, double amountToDisburse, String proofBase64, String reason) async {
    try {
      // Validate image size before processing
      if (proofBase64.length * 2 > _maxDocumentSizeBytes) {
        throw Exception('Proof image too large. Max ~200KB allowed on free tier.');
      }
      
      // Get donations with remaining amount > 0 for this cause
      // Only include fully verified donations (status = 'verified')
      final snap = await _donations
          .where('cause', isEqualTo: cause)
          .where('status', isEqualTo: 'verified')
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 15));

      // Filter donations that have available funds (only verified donations)
      final docs = snap.docs
          .map(DonationModel.fromFirestore)
          .where((d) =>
            d.status == 'verified' &&
            d.remainingAmount > 0.01)
          .toList();

      if (docs.isEmpty) {
        throw Exception('No donations with available funds found for this cause');
      }
      
      docs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      double remainingToDisburse = amountToDisburse;
      double totalDisbursed = 0;
      final affectedDonationIds = <String>[];
      final userAllocations = <String, double>{};
      
      final batch = _db.batch();
      int batchCount = 0;
      const maxBatchSize = 20; // Firestore free tier batch limit
      
      for (var d in docs) {
        if (remainingToDisburse <= 0 || batchCount >= maxBatchSize) break;
        
        // Skip if remaining amount is null or already fully used
        double remaining = d.remainingAmount;
        if (remaining <= 0.01) continue;
        
        double canTake = remaining;
        double toTake = remainingToDisburse > canTake ? canTake : remainingToDisburse;
        
        double newRemaining = remaining - toTake;
        remainingToDisburse -= toTake;
        totalDisbursed += toTake;
        
        affectedDonationIds.add(d.id);
        userAllocations[d.userId] = (userAllocations[d.userId] ?? 0) + toTake;
        
        batch.update(_donations.doc(d.id), {
          'remainingAmount': newRemaining,
          'status': newRemaining <= 0.01 ? 'disbursed' : 'verified',
          'disbursementProof': proofBase64,
          'disbursementReason': reason,
          if (newRemaining <= 0.01) 'disbursedAt': FieldValue.serverTimestamp(),
        });
        batchCount++;
      }
      
      // Create disbursement record
      final disbursementRef = _disbursements.doc();
      final currentUser = _auth.currentUser;
      final adminId = currentUser?.uid ?? 'unknown';
      final adminData = currentUser != null ? await getUser(adminId) : null;
      
      batch.set(disbursementRef, {
        'title': reason,
        'cause': cause,
        'totalAmount': totalDisbursed,
        'billImageUrl': '',
        'billImageBase64': proofBase64,
        'verified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'affectedDonationIds': affectedDonationIds,
        'userAllocations': userAllocations.map((userId, amount) => 
          MapEntry(userId, {'amount': amount})),
        'disbursedBy': adminId,
        'disbursedByName': adminData?['name'] ?? 'Unknown Admin',
        'disbursedByRole': adminData?['role'] ?? 'Admin',
      });
      
      await batch.commit().timeout(const Duration(seconds: 15));

      // 4. Notify affected donors about the impact
      for (var entry in userAllocations.entries) {
        final userId = entry.key;
        final allocatedAmount = entry.value;
        
        await NotificationService.createAdminNotification(
          adminId: userId, // Re-using admin notification logic for user impact
          title: 'Your Donation in Action! 🌟',
          message: 'PKR ${allocatedAmount.toStringAsFixed(0)} of your donation for $cause has been disbursed: $reason',
          type: 'disbursement',
          data: {
            'cause': cause,
            'amount': allocatedAmount,
          },
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Cannot disburse funds.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in as admin to disburse funds.');
      } else if (e.code == 'resource-exhausted') {
        throw Exception('Free tier quota exceeded. Please try again later.');
      } else {
        throw Exception('Disbursement failed: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection and try again.');
    } catch (e) {
      throw Exception('Failed to disburse funds: $e');
    }
  }

  // ─── Settings ──────────────────────────────────────────────
  static Stream<Map<String, dynamic>> paymentSettings() {
    return _settings.doc('payment').snapshots().map((doc) {
      if (!doc.exists) return {'iban': '', 'recipientName': ''};
      return doc.data() as Map<String, dynamic>;
    });
  }

  static Future<void> updatePaymentSettings(String iban, String recipientName) async {
    try {
      await _settings.doc('payment').set({
        'iban': iban,
        'recipientName': recipientName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Failed to update payment settings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update payment settings: $e');
    }
  }
  
  // ─── Causes ──────────────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> allCauses() {
    return _causes.snapshots().map((s) {
      return s.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList();
    });
  }

  // ─── Disbursements ──────────────────────────────────────────
  static Stream<List<DisbursementModel>> allDisbursements() {
    // Note: Removed orderBy to avoid composite index requirement in free tier.
    // Fetch all and sort in memory instead.
    return _disbursements
        .snapshots()
        .map((s) {
          final docs = s.docs.map((d) {
            final data = d.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return DisbursementModel(
              id: d.id,
              title: data['title'] ?? '',
              cause: data['cause'] ?? '',
              totalAmount: (data['totalAmount'] ?? 0).toDouble(),
              billImageUrl: data['billImageBase64'] ?? data['billImageUrl'] ?? '',
              verified: data['verified'] ?? true,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              disbursedAt: (data['createdAt'] as Timestamp?)?.toDate(),
              disbursedBy: data['disbursedBy'] ?? '',
              disbursedByName: data['disbursedByName'] ?? '',
              disbursedByRole: data['disbursedByRole'] ?? '',
            );
          }).where((d) => d != null).cast<DisbursementModel>().toList();
          
          // Sort in memory by createdAt descending
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }
  
  static Future<UserAllocation?> myAllocation(String disbursementId) async {
    try {
      final uid = getCurrentUid();
      final doc = await _disbursements.doc(disbursementId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      final userAllocations = data['userAllocations'] as Map<String, dynamic>?;
      
      if (userAllocations == null || !userAllocations.containsKey(uid)) {
        return null;
      }
      
      final myAlloc = userAllocations[uid] as Map<String, dynamic>;
      final affectedDonationIds = List<String>.from(data['affectedDonationIds'] ?? []);
      
      // Get user name
      final userDoc = await _users.doc(uid).get();
      final userName = (userDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown';
      
      return UserAllocation(
        userId: uid,
        userName: userName,
        allocatedAmount: (myAlloc['amount'] ?? 0).toDouble(),
        donationIds: affectedDonationIds,
        billImageUrl: data['billImageBase64'] ?? data['billImageUrl'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }
  
  static Future<List<UserAllocation>> allAllocations(String disbursementId) async {
    try {
      final doc = await _disbursements.doc(disbursementId).get();
      if (!doc.exists) return [];
      
      final data = doc.data() as Map<String, dynamic>;
      final userAllocations = data['userAllocations'] as Map<String, dynamic>?;
      final affectedDonationIds = List<String>.from(data['affectedDonationIds'] ?? []);
      
      if (userAllocations == null) return [];
      
      final allocations = <UserAllocation>[];
      for (final entry in userAllocations.entries) {
        final userId = entry.key;
        final allocData = entry.value as Map<String, dynamic>;
        
        // Get user name
        final userDoc = await _users.doc(userId).get();
        final userName = (userDoc.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown';
        
        allocations.add(UserAllocation(
          userId: userId,
          userName: userName,
          allocatedAmount: (allocData['amount'] ?? 0).toDouble(),
          donationIds: affectedDonationIds.where((id) => id.isNotEmpty).toList(),
          billImageUrl: data['billImageBase64'] ?? data['billImageUrl'] ?? '',
        ));
      }
      
      return allocations;
    } catch (e) {
      return [];
    }
  }
  
  // ─── Requests (placeholder for future implementation) ─────────
  static Stream<List<RequestModel>> allRequests() {
    return const Stream.empty();
  }
  static Future<void> contributeToRequest(String id, double amount, String cause) async {
    return;
  }
  static Future<void> createRequest({required String title, required double goalAmount, required String cause}) async {
    return;
  }
  static Future<void> verifyDisbursement(String id) async {
    try {
      await _disbursements.doc(id).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': _auth.currentUser?.uid,
      }).timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You need admin privileges to verify disbursements.');
      } else if (e.code == 'unauthenticated') {
        throw Exception('You must be logged in to verify disbursements.');
      } else if (e.code == 'not-found') {
        throw Exception('Disbursement not found. It may have been deleted.');
      } else if (e.code == 'resource-exhausted') {
        throw Exception('Free tier quota exceeded. Please try again later.');
      } else {
        throw Exception('Failed to verify disbursement: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
      throw Exception('Failed to verify disbursement: $e');
    }
  }
  
  /// Legacy method for admin_panel.dart - creates a disbursement record
  static Future<void> createDisbursement({
    required String title,
    required String cause,
    required double totalAmount,
    required String billImageUrl,
  }) async {
    await _disbursements.add({
      'title': title,
      'cause': cause,
      'totalAmount': totalAmount,
      'billImageUrl': billImageUrl,
      'billImageBase64': '',
      'verified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'affectedDonationIds': [],
      'userAllocations': {},
    });
  }
}
