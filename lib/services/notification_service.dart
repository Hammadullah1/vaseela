import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications stream for current user
  static Stream<List<NotificationModel>> getUserNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Get admin-specific notifications stream for current user (only if admin)
  static Stream<List<NotificationModel>> getAdminNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Get unread notification count
  static Stream<int> getUnreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get unread admin notification count
  static Stream<int> getAdminUnreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .where((n) => n.type == 'team_change' || n.type == 'new_payment')
            .length);
  }

  // Create payment verification notification
  static Future<void> createPaymentVerifiedNotification({
    required String userId,
    required double amount,
    required String cause,
    required String donationId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': 'Payment Verified ✅',
      'message': 'Your donation of PKR ${amount.toStringAsFixed(0)} for $cause has been verified.',
      'type': 'payment_verified',
      'data': {
        'amount': amount,
        'cause': cause,
        'donationId': donationId,
      },
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create disbursement notification
  static Future<void> createDisbursementNotification({
    required String userId,
    required double amount,
    required String cause,
    required String? recipientName,
    required String disbursementId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': 'Funds Disbursed 🌿',
      'message': recipientName != null
          ? 'PKR ${amount.toStringAsFixed(0)} has been disbursed to $recipientName for $cause.'
          : 'PKR ${amount.toStringAsFixed(0)} has been disbursed for $cause.',
      'type': 'disbursement',
      'data': {
        'amount': amount,
        'cause': cause,
        'recipientName': recipientName,
        'disbursementId': disbursementId,
      },
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create admin notification (for new donations, etc.)
  static Future<void> createAdminNotification({
    required String adminId,
    required String title,
    required String message,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': adminId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all as read
  static Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // ─── Team Notifications ───────────────────────────────────────────

  /// Notify all team members about a team change
  static Future<void> notifyTeamChange({
    required String actionType, // 'added', 'removed', 'role_changed'
    required String targetUserName,
    required String? oldRole,
    required String? newRole,
    required String actorName, // Who made the change
  }) async {
    try {
      // Get all admin users (team members)
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();
      
      String title;
      String message;
      
      switch (actionType) {
        case 'added':
          title = 'New Team Member 👋';
          message = '$targetUserName has joined the team as $newRole.';
          break;
        case 'removed':
          title = 'Team Member Removed 🚪';
          message = '$targetUserName ($oldRole) has been removed from the team by $actorName.';
          break;
        case 'role_changed':
          title = 'Role Updated 📋';
          message = '$targetUserName changed from $oldRole to $newRole by $actorName.';
          break;
        default:
          title = 'Team Update';
          message = 'Team member $targetUserName has been updated.';
      }
      
      // Send notification to all admins except the actor
      final batch = _firestore.batch();
      for (final adminDoc in adminsSnapshot.docs) {
        final adminId = adminDoc.id;
        
        // Create notification for each admin
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': adminId,
          'title': title,
          'message': message,
          'type': 'team_change',
          'data': {
            'actionType': actionType,
            'targetUserName': targetUserName,
            'oldRole': oldRole,
            'newRole': newRole,
            'actorName': actorName,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error sending team notification: $e');
    }
  }

  /// Create payment notification for admins (when new payment is submitted)
  static Future<void> createNewPaymentNotification({
    required String donorName,
    required double amount,
    required String cause,
    required String donationId,
  }) async {
    try {
      // Get all admin users
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();
      
      final batch = _firestore.batch();
      for (final adminDoc in adminsSnapshot.docs) {
        final adminId = adminDoc.id;
        
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': adminId,
          'title': 'New Payment Submitted 💰',
          'message': '$donorName submitted PKR ${amount.toStringAsFixed(0)} for $cause. Please verify.',
          'type': 'new_payment',
          'data': {
            'amount': amount,
            'cause': cause,
            'donorName': donorName,
            'donationId': donationId,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error sending admin payment notification: $e');
    }
  }

  /// Create payment rejected notification
  static Future<void> createPaymentRejectedNotification({
    required String userId,
    required double amount,
    required String cause,
    required String reason,
    required String donationId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': 'Payment Not Received ❌',
      'message': 'Your payment of PKR ${amount.toStringAsFixed(0)} for $cause was not received. Reason: $reason',
      'type': 'payment_rejected',
      'data': {
        'amount': amount,
        'cause': cause,
        'reason': reason,
        'donationId': donationId,
      },
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
