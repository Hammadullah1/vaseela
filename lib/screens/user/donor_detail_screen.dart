import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/donation_model.dart';

class DonorDetailScreen extends StatefulWidget {
  final String userId;

  const DonorDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<DonorDetailScreen> createState() => _DonorDetailScreenState();
}

class _DonorDetailScreenState extends State<DonorDetailScreen> {
  Map<String, dynamic>? _userData;
  List<DonationModel> _donations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      // Load donations
      final donationsSnap = await FirebaseFirestore.instance
          .collection('donations')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .get();

      final donations = donationsSnap.docs
          .map((doc) => DonationModel.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _donations = donations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Widget _statusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'verified':
        color = Colors.blue;
        text = 'Verified';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Partially Disbursed';
        break;
      case 'pending_verification':
        color = Colors.amber;
        text = 'Verifying';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      case 'disbursed':
        color = Colors.green;
        text = 'Disbursed';
        break;
      case 'awaiting_payment':
        color = Colors.grey;
        text = 'Awaiting Payment';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(_userData?['name'] ?? 'Donor Details'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primaryGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userData!['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        _userData!['email'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Phone', _userData!['phone'] ?? 'N/A'),
                            _buildInfoRow('Total Donated', 'PKR ${(_userData!['totalDonated'] ?? 0).toStringAsFixed(0)}'),
                            _buildInfoRow('Member Since', _userData!['createdAt'] != null 
                                ? DateFormat('MMM dd, yyyy').format((_userData!['createdAt'] as Timestamp).toDate())
                                : 'N/A'),
                            _buildInfoRow('Admin Status', _userData!['isAdmin'] == true ? 'Yes' : 'No'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Donations History
                      const Text(
                        'Donation History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _donations.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Center(
                                child: Text(
                                  'No donations found',
                                  style: TextStyle(color: AppColors.textGrey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _donations.length,
                              itemBuilder: (context, index) {
                                final donation = _donations[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'PKR ${donation.amount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryGreen,
                                            ),
                                          ),
                                          _statusChip(donation.status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        donation.cause,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy - hh:mm a').format(donation.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      if (donation.remainingAmount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Remaining: PKR ${donation.remainingAmount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textGrey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
