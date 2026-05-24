import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../models/donation_model.dart';

class WalletScreen extends StatelessWidget {
  final VoidCallback onBack;

  const WalletScreen({super.key, required this.onBack});

  void _showProof(BuildContext context, DonationModel d) {
    Widget imageWidget;
    
    if (d.disbursementProof.isEmpty) {
      imageWidget = const Center(
        child: Text('No proof image uploaded', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
      );
    } else {
      try {
        final decodedBytes = base64Decode(d.disbursementProof);
        if (decodedBytes.isEmpty) {
          throw Exception('Empty image data');
        }
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            decodedBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.broken_image, color: Colors.red, size: 48),
                    SizedBox(height: 8),
                    Text('Failed to load image', style: TextStyle(color: Colors.red)),
                  ],
                ),
              );
            },
          ),
        );
      } catch (e) {
        imageWidget = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text('Invalid image data: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: const Row(children: [
                  Icon(Icons.verified, color: AppColors.gold, size: 20),
                  SizedBox(width: 8),
                  Text('Disbursement Proof', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textGrey)),
                      const SizedBox(height: 4),
                      Text(d.disbursementReason.isEmpty ? 'No reason provided' : d.disbursementReason, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),
                      imageWidget,
                    ],
                  ),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SafeArea(
        child: StreamBuilder<List<DonationModel>>(
        stream: FirestoreService.userDonations(),
        builder: (context, snapshot) {
          final donations = snapshot.data ?? [];
          final totalDonated = donations
              .where((d) => d.status == 'verified' || d.status == 'pending' || d.status == 'disbursed')
              .fold<double>(0, (sum, d) => sum + d.amount);
          final verifying = donations.where((d) => d.status == 'pending_verification').length;
          final verified = donations.where((d) => d.status == 'verified' || d.status == 'pending').length;
          final disbursed = donations.where((d) => d.status == 'disbursed').length;
          final rejected = donations.where((d) => d.status == 'rejected').length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
                ),
                child: Column(children: [
                  Row(children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text('My Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _WalletStat(label: 'Total', value: 'PKR ${totalDonated.toStringAsFixed(0)}', color: AppColors.gold),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _WalletStat(label: 'Verifying', value: '$verifying', color: Colors.amber),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _WalletStat(label: 'Verified', value: '$verified', color: Colors.blue.shade300),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _WalletStat(label: 'Disbursed', value: '$disbursed', color: AppColors.accentGreen),
                      Container(width: 1, height: 36, color: Colors.white24),
                      _WalletStat(label: 'Rejected', value: '$rejected', color: Colors.red.shade300),
                    ]),
                  ),
                ]),
              ),
              Expanded(
                child: donations.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.receipt_long, size: 48, color: AppColors.textGrey.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        const Text('No transactions yet', style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: donations.length,
                        itemBuilder: (context, index) {
                          final d = donations[index];
                          
                          Color iconColor;
                          Color bgColor;
                          IconData icon;
                          String statusText;
                          
                          if (d.status == 'pending_verification') {
                            iconColor = Colors.amber.shade800;
                            bgColor = Colors.amber.shade100;
                            icon = Icons.hourglass_top;
                            statusText = 'Verifying';
                          } else if (d.status == 'pending') {
                            iconColor = Colors.blue.shade700;
                            bgColor = Colors.blue.shade50;
                            icon = Icons.verified;
                            statusText = 'Verified';
                          } else if (d.status == 'rejected') {
                            iconColor = Colors.red.shade700;
                            bgColor = Colors.red.shade50;
                            icon = Icons.cancel;
                            statusText = 'Rejected';
                          } else {
                            iconColor = AppColors.accentGreen;
                            bgColor = AppColors.lightGreen;
                            icon = Icons.check_circle;
                            statusText = 'Disbursed';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.white, borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(d.cause, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text('${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('PKR ${d.remainingAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                                if (d.remainingAmount < d.amount)
                                  Text('of PKR ${d.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: AppColors.textGrey, decoration: TextDecoration.lineThrough)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: iconColor),
                                  ),
                                ),
                                if (d.status == 'rejected' && d.rejectionReason.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Reason: ${d.rejectionReason}',
                                      style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (d.disbursementProof.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: GestureDetector(
                                      onTap: () => _showProof(context, d),
                                      child: const Text('View Proof', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryGreen, decoration: TextDecoration.underline)),
                                    ),
                                  ),
                              ]),
                            ]),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      )),
    );
  }
}

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _WalletStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: AppColors.white.withValues(alpha: 0.6))),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}
