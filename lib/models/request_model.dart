import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String title;
  final double goalAmount;
  double collectedAmount;
  final String cause;
  final String status; // 'open' | 'fulfilled'
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.title,
    required this.goalAmount,
    required this.collectedAmount,
    required this.cause,
    required this.status,
    required this.createdAt,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      title: d['title'] ?? '',
      goalAmount: (d['goalAmount'] ?? 0).toDouble(),
      collectedAmount: (d['collectedAmount'] ?? 0).toDouble(),
      cause: d['cause'] ?? '',
      status: d['status'] ?? 'open',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'goalAmount': goalAmount,
    'collectedAmount': collectedAmount,
    'cause': cause,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
