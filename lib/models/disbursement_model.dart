import 'package:cloud_firestore/cloud_firestore.dart';

class UserAllocation {
  final String userId;
  final String userName;
  final double allocatedAmount;
  final List<String> donationIds;
  final String billImageUrl;

  UserAllocation({
    required this.userId,
    required this.userName,
    required this.allocatedAmount,
    required this.donationIds,
    required this.billImageUrl,
  });

  factory UserAllocation.fromMap(Map<String, dynamic> d) => UserAllocation(
    userId: d['userId'] ?? '',
    userName: d['userName'] ?? '',
    allocatedAmount: (d['allocatedAmount'] ?? 0).toDouble(),
    donationIds: List<String>.from(d['donationIds'] ?? []),
    billImageUrl: d['billImageUrl'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'allocatedAmount': allocatedAmount,
    'donationIds': donationIds,
    'billImageUrl': billImageUrl,
  };
}

class DisbursementModel {
  final String id;
  final String title;
  final String cause;
  final double totalAmount;
  final String billImageUrl;
  bool verified;
  final DateTime createdAt;
  DateTime? disbursedAt;
  List<UserAllocation> allocations; // loaded separately
  final String disbursedBy;
  final String disbursedByName;
  final String disbursedByRole;

  DisbursementModel({
    required this.id,
    required this.title,
    required this.cause,
    required this.totalAmount,
    required this.billImageUrl,
    required this.verified,
    required this.createdAt,
    this.disbursedAt,
    this.allocations = const [],
    this.disbursedBy = '',
    this.disbursedByName = '',
    this.disbursedByRole = '',
  });

  factory DisbursementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DisbursementModel(
      id: doc.id,
      title: d['title'] ?? '',
      cause: d['cause'] ?? '',
      totalAmount: (d['totalAmount'] ?? 0).toDouble(),
      billImageUrl: d['billImageUrl'] ?? '',
      verified: d['verified'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      disbursedAt: (d['disbursedAt'] as Timestamp?)?.toDate(),
      disbursedBy: d['disbursedBy'] ?? '',
      disbursedByName: d['disbursedByName'] ?? '',
      disbursedByRole: d['disbursedByRole'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'cause': cause,
    'totalAmount': totalAmount,
    'billImageUrl': billImageUrl,
    'verified': verified,
    'createdAt': Timestamp.fromDate(createdAt),
    'disbursedAt': disbursedAt != null ? Timestamp.fromDate(disbursedAt!) : null,
    'disbursedBy': disbursedBy,
    'disbursedByName': disbursedByName,
    'disbursedByRole': disbursedByRole,
  };
}
