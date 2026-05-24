import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../services/reference_generator.dart';
import '../../models/request_model.dart';

class RequestsScreen extends StatelessWidget {
  final VoidCallback onBack;
  const RequestsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SafeArea(
        top: false,
        child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Donation Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
              SizedBox(height: 2),
              Text('Help fulfill these needs', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<RequestModel>>(
            stream: FirestoreService.allRequests(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
              final reqs = snap.data!;
              if (reqs.isEmpty) return const Center(child: Text('No active requests', style: TextStyle(color: AppColors.textGrey)));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reqs.length,
                itemBuilder: (_, i) => _ReqCard(r: reqs[i]),
              );
            },
          ),
        ),
      ]),
      ),
    );
  }
}

class _ReqCard extends StatefulWidget {
  final RequestModel r;
  const _ReqCard({required this.r});
  @override
  State<_ReqCard> createState() => _ReqCardState();
}

class _ReqCardState extends State<_ReqCard> {
  bool _busy = false;

  Future<void> _donate() async {
    setState(() => _busy = true);
    try {
      await ReferenceGenerator.createDonationRecord(
        amount: 500,
        cause: widget.r.cause,
        adminIban: 'request_donation',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PKR 500 donated!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final pct = r.goalAmount > 0 ? (r.collectedAmount / r.goalAmount).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.volunteer_activism, color: AppColors.primaryGreen, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(r.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark))),
        ]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Goal: PKR ${r.goalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          Text('Collected: PKR ${r.collectedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentGreen)),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 40,
          child: ElevatedButton(
            onPressed: _busy ? null : _donate,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Donate PKR 500', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
