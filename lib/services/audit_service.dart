import 'package:cloud_firestore/cloud_firestore.dart';

/// Audit Log Types
enum AuditActionType {
  paymentVerified,
  paymentRejected,
  donationCancelled,
  fundsDisbursed,
  disbursementVerified,
  teamMemberAdded,
  teamMemberRemoved,
  roleChanged,
  settingsChanged,
  login,
  logout,
  bossAdded,
  bossRemoved,
}

/// Audit Service for tracking all admin actions
class AuditService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _auditLogs = _db.collection('audit_logs');
  static final CollectionReference _deletedUsers = _db.collection('deleted_users');

  /// Log any action with full context
  static Future<void> logAction({
    required AuditActionType action,
    required String actorId,
    required String actorName,
    required String actorRole,
    String? targetId,
    String? targetName,
    String? targetRole,
    Map<String, dynamic>? details,
    double? amount,
    String? cause,
  }) async {
    try {
      await _auditLogs.add({
        'action': action.name,
        'actorId': actorId,
        'actorName': actorName,
        'actorRole': actorRole,
        'targetId': targetId,
        'targetName': targetName,
        'targetRole': targetRole,
        'details': details ?? {},
        'amount': amount,
        'cause': cause,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': null, // Would need additional package for IP
        'userAgent': 'flutter_app',
      });
    } catch (e) {
      // Silent fail - don't break main functionality if audit fails
      // Log error to crash reporting service if needed
    }
  }

  /// Log payment verification
  static Future<void> logPaymentVerified({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String donationId,
    required String donorName,
    required double amount,
    required String cause,
  }) async {
    await logAction(
      action: AuditActionType.paymentVerified,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      targetId: donationId,
      targetName: donorName,
      amount: amount,
      cause: cause,
      details: {'donationId': donationId, 'donorName': donorName},
    );
  }

  /// Log payment rejection
  static Future<void> logPaymentRejected({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String donationId,
    required String donorName,
    required double amount,
    required String cause,
    required String reason,
  }) async {
    await logAction(
      action: AuditActionType.paymentRejected,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      targetId: donationId,
      targetName: donorName,
      amount: amount,
      cause: cause,
      details: {'reason': reason},
    );
  }

  /// Log donation cancellation (Boss only)
  static Future<void> logDonationCancelled({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String donationId,
    required String donorName,
    required double amount,
    required String cause,
    required String reason,
  }) async {
    await logAction(
      action: AuditActionType.donationCancelled,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      targetId: donationId,
      targetName: donorName,
      amount: amount,
      cause: cause,
      details: {'reason': reason},
    );
  }

  /// Log funds disbursement
  static Future<void> logFundsDisbursed({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String disbursementId,
    required double amount,
    required String cause,
    required String reason,
    required int donorCount,
  }) async {
    await logAction(
      action: AuditActionType.fundsDisbursed,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      targetId: disbursementId,
      amount: amount,
      cause: cause,
      details: {'reason': reason, 'donorCount': donorCount},
    );
  }

  /// Log team member added
  static Future<void> logTeamMemberAdded({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String newMemberId,
    required String newMemberEmail,
    required String newMemberRole,
  }) async {
    await logAction(
      action: AuditActionType.teamMemberAdded,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      targetId: newMemberId,
      targetName: newMemberEmail,
      targetRole: newMemberRole,
    );
  }

  /// Log team member removed
  static Future<void> logTeamMemberRemoved({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String removedMemberId,
    required String removedMemberName,
    required String removedMemberRole,
    required String reason,
  }) async {
    await logAction(
      action: AuditActionType.teamMemberRemoved,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      targetId: removedMemberId,
      targetName: removedMemberName,
      targetRole: removedMemberRole,
      details: {'reason': reason},
    );
  }

  /// Log role change
  static Future<void> logRoleChanged({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String targetId,
    required String targetName,
    required String oldRole,
    required String newRole,
  }) async {
    await logAction(
      action: AuditActionType.roleChanged,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      targetId: targetId,
      targetName: targetName,
      targetRole: newRole,
      details: {'oldRole': oldRole, 'newRole': newRole},
    );
  }

  /// Log settings change
  static Future<void> logSettingsChanged({
    required String actorId,
    required String actorName,
    required String actorRole,
    required String settingName,
    required dynamic oldValue,
    required dynamic newValue,
  }) async {
    await logAction(
      action: AuditActionType.settingsChanged,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      details: {
        'settingName': settingName,
        'oldValue': oldValue?.toString(),
        'newValue': newValue?.toString(),
      },
    );
  }

  /// Log admin login
  static Future<void> logAdminLogin({
    required String actorId,
    required String actorName,
    required String actorRole,
  }) async {
    await logAction(
      action: AuditActionType.login,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      details: {'event': 'admin_login'},
    );
  }

  /// Log admin logout
  static Future<void> logAdminLogout({
    required String actorId,
    required String actorName,
    required String actorRole,
  }) async {
    await logAction(
      action: AuditActionType.logout,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      details: {'event': 'admin_logout'},
    );
  }

  /// Record deleted user for audit trail
  static Future<void> recordDeletedUser({
    required String userId,
    required String name,
    required String email,
    required String role,
    required String deletedById,
    required String deletedByName,
    required String reason,
  }) async {
    try {
      await _deletedUsers.add({
        'userId': userId,
        'name': name,
        'email': email,
        'role': role,
        'deletedById': deletedById,
        'deletedByName': deletedByName,
        'reason': reason,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail - don't break main functionality
    }
  }

  /// Get audit logs stream (for Boss only)
  static Stream<List<Map<String, dynamic>>> getAuditLogs({
    AuditActionType? filterAction,
    String? filterActorId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) {
    Query query = _auditLogs;

    if (filterAction != null) {
      query = query.where('action', isEqualTo: filterAction.name);
    }

    if (filterActorId != null) {
      query = query.where('actorId', isEqualTo: filterActorId);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort in memory by timestamp
      list.sort((a, b) {
        final t1 = a['timestamp'] as Timestamp?;
        final t2 = b['timestamp'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1); // descending
      });
      
      return list.take(limit).toList();
    });
  }

  /// Get audit logs for export (Future based)
  static Future<List<Map<String, dynamic>>> getAuditLogsForExport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _auditLogs;

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snap = await query.get();
    final list = snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    // Sort in memory
    list.sort((a, b) {
      final t1 = a['timestamp'] as Timestamp?;
      final t2 = b['timestamp'] as Timestamp?;
      if (t1 == null) return 1;
      if (t2 == null) return -1;
      return t2.compareTo(t1); // descending
    });

    return list;
  }

  /// Get deleted users (for Boss only)
  static Stream<List<Map<String, dynamic>>> getDeletedUsers() {
    return _deletedUsers
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort in memory
      list.sort((a, b) {
        final t1 = a['deletedAt'] as Timestamp?;
        final t2 = b['deletedAt'] as Timestamp?;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });
      
      return list;
    });
  }

  /// Get action type display name
  static String getActionDisplayName(String actionName) {
    final Map<String, String> displayNames = {
      'paymentVerified': 'Payment Verified',
      'paymentRejected': 'Payment Rejected',
      'donationCancelled': 'Donation Cancelled',
      'fundsDisbursed': 'Funds Disbursed',
      'disbursementVerified': 'Disbursement Verified',
      'teamMemberAdded': 'Team Member Added',
      'teamMemberRemoved': 'Team Member Removed',
      'roleChanged': 'Role Changed',
      'settingsChanged': 'Settings Changed',
      'broadcastSent': 'Broadcast Sent',
      'login': 'Login',
      'logout': 'Logout',
    };
    return displayNames[actionName] ?? actionName;
  }
}
