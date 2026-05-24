import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String userId;
  final String cause;
  final double amount;
  final double remainingAmount;
  final String adminIban;
  final String screenshotBase64;
  final String status;
  final String paymentMethod;
  final String disbursementProof;
  final String disbursementReason;
  final String rejectionReason;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? disbursedAt;
  final DateTime? rejectedAt;

  DonationModel({
    required this.id,
    required this.userId,
    required this.cause,
    required this.amount,
    required this.remainingAmount,
    required this.adminIban,
    required this.screenshotBase64,
    required this.status,
    required this.paymentMethod,
    this.disbursementProof = '',
    this.disbursementReason = '',
    this.rejectionReason = '',
    required this.createdAt,
    this.verifiedAt,
    this.disbursedAt,
    this.rejectedAt,
  });

  factory DonationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DonationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      cause: d['cause'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      remainingAmount: (d['remainingAmount'] ?? (d['amount'] ?? 0)).toDouble(),
      adminIban: d['adminIban'] ?? '',
      screenshotBase64: d['screenshotBase64'] ?? '',
      status: d['status'] ?? 'pending_verification',
      paymentMethod: d['paymentMethod'] ?? 'raast',
      disbursementProof: d['disbursementProof'] ?? '',
      disbursementReason: d['disbursementReason'] ?? '',
      rejectionReason: d['rejectionReason'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (d['verifiedAt'] as Timestamp?)?.toDate(),
      disbursedAt: (d['disbursedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (d['rejectedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'cause': cause,
    'amount': amount,
    'remainingAmount': remainingAmount,
    'adminIban': adminIban,
    'screenshotBase64': screenshotBase64,
    'status': status,
    'paymentMethod': paymentMethod,
    'disbursementProof': disbursementProof,
    'disbursementReason': disbursementReason,
    'rejectionReason': rejectionReason,
    'createdAt': Timestamp.fromDate(createdAt),
    if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
    if (disbursedAt != null) 'disbursedAt': Timestamp.fromDate(disbursedAt!),
    if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
  };
}
