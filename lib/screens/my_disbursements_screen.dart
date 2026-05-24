import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../models/disbursement_model.dart';

const _green = Color(0xFF1A6B3C);
const _accent = Color(0xFF28A745);
const _lightGreen = Color(0xFFE8F5EE);
const _gold = Color(0xFFF5A623);

/// Shows all disbursements. For each one where the current user was
/// allocated funds, it shows their specific share + bill image.
class MyDisbursementsScreen extends StatelessWidget {
  const MyDisbursementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D3D21), Color(0xFF1A6B3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('How Your Money Was Used',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<DisbursementModel>>(
        stream: FirestoreService.allDisbursements(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: _green));
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(
              child: Text('No disbursements yet',
                  style: TextStyle(color: Colors.black38, fontSize: 13)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _DisbCard(d: list[i]),
          );
        },
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Bill image (if available)
        if (d.billImageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: CachedNetworkImage(
              imageUrl: d.billImageUrl,
              height: 150, width: double.infinity, fit: BoxFit.cover,
              placeholder: (_, p1) => Container(height: 150, color: _lightGreen,
                child: const Center(child: Icon(Icons.receipt_long, color: _green, size: 36))),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title + verified badge
            Row(children: [
              Expanded(child: Text(d.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87))),
              if (d.verified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified, color: _accent, size: 12),
                    SizedBox(width: 3),
                    Text('Verified', style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _chip(d.cause, _lightGreen, _green),
              const SizedBox(width: 8),
              _chip('Total: PKR ${_fmt(d.totalAmount)}', const Color(0xFFFFF3E0), _gold),
            ]),
            const SizedBox(height: 14),
            // My allocation
            if (!_loaded)
              const Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _green)))
            else if (_myAlloc != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D3D21), Color(0xFF1A6B3C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Your contribution was used here',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('PKR ${_fmt(_myAlloc!.allocatedAmount)}',
                      style: const TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('from ${_myAlloc!.donationIds.length} donation(s)',
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              ),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
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

String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2)
    .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
