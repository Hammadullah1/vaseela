import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../models/disbursement_model.dart';
import '../../constants/app_colors.dart';

class MyDisbursementsScreen extends StatelessWidget {
  final VoidCallback onBack;
  const MyDisbursementsScreen({super.key, required this.onBack});

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
            const Text('How Your Money Was Used', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<DisbursementModel>>(
            stream: FirestoreService.allDisbursements(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
              final list = snap.data!;
              if (list.isEmpty) return const Center(child: Text('No disbursements yet', style: TextStyle(color: AppColors.textGrey)));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _DisbCard(d: list[i]),
              );
            },
          ),
        ),
      ]),
      ),
    );
  }
}

class _DisbCard extends StatefulWidget {
  final DisbursementModel d;
  const _DisbCard({required this.d});
  @override
  State<_DisbCard> createState() => _DisbCardState();
}

class _DisbCardState extends State<_DisbCard> {
  UserAllocation? _myAlloc;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await FirestoreService.myAllocation(widget.d.id);
    if (mounted) setState(() { _myAlloc = a; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (d.billImageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: CachedNetworkImage(
              imageUrl: d.billImageUrl, height: 150, width: double.infinity, fit: BoxFit.cover,
              placeholder: (_, p1) => Container(height: 150, color: AppColors.lightGreen,
                child: const Center(child: Icon(Icons.receipt_long, color: AppColors.primaryGreen, size: 36))),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark))),
              if (d.verified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified, color: AppColors.accentGreen, size: 12),
                    SizedBox(width: 3),
                    Text('Verified', style: TextStyle(color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _chip(d.cause, AppColors.lightGreen, AppColors.primaryGreen),
              const SizedBox(width: 8),
              _chip('Total: PKR ${d.totalAmount.toStringAsFixed(0)}', const Color(0xFFFFF3E0), AppColors.gold),
            ]),
            const SizedBox(height: 14),
            if (!_loaded)
              const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen)))
            else if (_myAlloc != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your contribution was used here', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('PKR ${_myAlloc!.allocatedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('from ${_myAlloc!.donationIds.length} donation(s)',
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('Your donations were not used in this disbursement',
                    style: TextStyle(color: Colors.black38, fontSize: 12)),
              ),
          ]),
        ),
      ]),
    );
  }
}

Widget _chip(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
  child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
);
