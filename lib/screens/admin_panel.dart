import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../models/disbursement_model.dart';
import '../../models/request_model.dart';

const _green = Color(0xFF1A6B3C);
const _accent = Color(0xFF28A745);
const _lightGreen = Color(0xFFE8F5EE);
const _gold = Color(0xFFF5A623);

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

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
        title: const Text('Admin Panel',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Donation Requests'),
            Tab(text: 'Disbursements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _RequestsTab(),
          _DisbursementsTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Donation Requests ────────────────────────────────────

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _cause = 'hunger';
  bool _loading = false;

  Widget _causeDropdown() => InputDecorator(
    decoration: _inputDecoration('Cause'),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isDense: true,
        isExpanded: true,
        value: _cause,
        items: ['hunger', 'education', 'capital', 'healthcare']
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _cause = v!),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Create Donation Request',
          child: Column(children: [
            _field(_titleCtrl, 'Title (e.g. Hospital Bill)'),
            const SizedBox(height: 10),
            _field(_amountCtrl, 'Goal Amount (PKR)', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _causeDropdown(),
            const SizedBox(height: 14),
            _primaryBtn(
              label: _loading ? 'Creating…' : 'Create Request',
              onTap: _loading ? null : _create,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('All Requests',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _green)),
        const SizedBox(height: 10),
        StreamBuilder<List<RequestModel>>(
          stream: FirestoreService.allRequests(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            if (list.isEmpty) return _emptyState('No requests yet');
            return Column(
              children: list.map((r) => _RequestCard(request: r)).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirestoreService.createRequest(
        title: _titleCtrl.text.trim(),
        goalAmount: double.parse(_amountCtrl.text.trim()),
        cause: _cause,
      );
      _titleCtrl.clear();
      _amountCtrl.clear();
      if (mounted) _toast('Request created');
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final pct = request.goalAmount > 0
        ? (request.collectedAmount / request.goalAmount).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(request.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _green)),
        const SizedBox(height: 6),
        Row(children: [
          _chip(request.cause, _lightGreen, _green),
          const SizedBox(width: 8),
          _chip(request.status, request.status == 'open' ? _lightGreen : Colors.grey.shade200,
              request.status == 'open' ? _accent : Colors.grey),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Goal: PKR ${_fmt(request.goalAmount)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text('Collected: PKR ${_fmt(request.collectedAmount)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: _lightGreen,
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }
}

// ─── Tab 2: Disbursements ────────────────────────────────────────

class _DisbursementsTab extends StatefulWidget {
  const _DisbursementsTab();

  @override
  State<_DisbursementsTab> createState() => _DisbursementsTabState();
}

class _DisbursementsTabState extends State<_DisbursementsTab> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _cause = 'hunger';
  File? _billImage;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          title: 'Add Disbursement',
          child: Column(children: [
            _field(_titleCtrl, 'Title (e.g. School Fees)'),
            const SizedBox(height: 10),
            _field(_amountCtrl, 'Total Amount (PKR)', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _causeDropdown(),
            const SizedBox(height: 12),
            _billPickerWidget(),
            const SizedBox(height: 14),
            _primaryBtn(
              label: _loading ? 'Processing…' : 'Disburse & Allocate',
              onTap: _loading ? null : _disburse,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('All Disbursements',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _green)),
        const SizedBox(height: 10),
        StreamBuilder<List<DisbursementModel>>(
          stream: FirestoreService.allDisbursements(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            if (list.isEmpty) return _emptyState('No disbursements yet');
            return Column(
              children: list.map((d) => _DisbursementCard(d: d)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _billPickerWidget() => GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: double.infinity,
      height: _billImage != null ? 160 : 56,
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withValues(alpha: 0.5)),
      ),
      child: _billImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_billImage!, fit: BoxFit.cover))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.upload_rounded, color: _green),
              SizedBox(width: 8),
              Text('Upload Bill / Receipt', style: TextStyle(color: _green, fontSize: 12)),
            ]),
    ),
  );

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _billImage = File(img.path));
  }

  Future<void> _disburse() async {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      _toast('Fill all fields'); return;
    }
    setState(() => _loading = true);
    try {
      String imageUrl = '';
      if (_billImage != null) {
        final ref = FirebaseStorage.instance
            .ref('bills/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_billImage!);
        imageUrl = await ref.getDownloadURL();
      }
      await FirestoreService.createDisbursement(
        title: _titleCtrl.text.trim(),
        cause: _cause,
        totalAmount: double.parse(_amountCtrl.text.trim()),
        billImageUrl: imageUrl,
      );
      _titleCtrl.clear();
      _amountCtrl.clear();
      setState(() { _billImage = null; });
      if (mounted) _toast('Disbursement created & allocated to users!');
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _causeDropdown() => InputDecorator(
    decoration: _inputDecoration('Cause'),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isDense: true,
        isExpanded: true,
        value: _cause,
        items: ['hunger', 'education', 'capital', 'healthcare']
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _cause = v!),
      ),
    ),
  );

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _DisbursementCard extends StatefulWidget {
  final DisbursementModel d;
  const _DisbursementCard({required this.d});

  @override
  State<_DisbursementCard> createState() => _DisbursementCardState();
}

class _DisbursementCardState extends State<_DisbursementCard> {
  List<UserAllocation> _allocs = [];
  bool _expanded = false;
  bool _verifying = false;

  Future<void> _loadAllocs() async {
    final a = await FirestoreService.allAllocations(widget.d.id);
    setState(() { _allocs = a; _expanded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Bill image
        if (d.billImageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: d.billImageUrl,
              height: 140, width: double.infinity, fit: BoxFit.cover,
              placeholder: (_, p1) => Container(height: 140, color: _lightGreen),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _green)),
            const SizedBox(height: 4),
            Row(children: [
              _chip(d.cause, _lightGreen, _green),
              const SizedBox(width: 8),
              _chip('PKR ${_fmt(d.totalAmount)}', const Color(0xFFFFF3E0), _gold),
            ]),
            const SizedBox(height: 10),
            // Verify button
            if (!d.verified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _verifying
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_rounded, size: 16),
                  label: Text(_verifying ? 'Verifying…' : 'Verify Disbursement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _verifying ? null : () async {
                    setState(() => _verifying = true);
                    try {
                      await FirestoreService.verifyDisbursement(d.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Disbursement verified successfully'),
                            backgroundColor: _accent,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _verifying = false);
                    }
                  },
                ),
              )
            else
              Row(children: const [
                Icon(Icons.check_circle, color: _accent, size: 16),
                SizedBox(width: 4),
                Text('Verified', style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            const SizedBox(height: 10),
            // Show allocations
            TextButton.icon(
              icon: Icon(_expanded ? Icons.expand_less : Icons.people_outline, color: _green, size: 16),
              label: Text(_expanded ? 'Hide Allocations' : 'View User Allocations',
                  style: const TextStyle(color: _green, fontSize: 12)),
              onPressed: _expanded ? () => setState(() => _expanded = false) : _loadAllocs,
            ),
            if (_expanded) ..._allocs.map((a) => _AllocationRow(a: a)),
          ]),
        ),
      ]),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final UserAllocation a;
  const _AllocationRow({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: _green,
          child: Text(a.userName.isNotEmpty ? a.userName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.userName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _green)),
          Text('${a.donationIds.length} donation(s) used',
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ])),
        Text('PKR ${_fmt(a.allocatedAmount)}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _green, fontSize: 13)),
      ]),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────

Widget _sectionCard({required String title, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDeco(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _green)),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

BoxDecoration _cardDeco() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
);

Widget _field(TextEditingController c, String hint, {TextInputType? keyboard}) =>
    TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: _inputDecoration(hint),
      style: const TextStyle(fontSize: 13),
    );

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
  filled: true,
  fillColor: const Color(0xFFF4F8F5),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
);

Widget _primaryBtn({required String label, VoidCallback? onTap}) =>
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );

Widget _chip(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
  child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
);

Widget _emptyState(String msg) => Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Text(msg, style: const TextStyle(color: Colors.black38, fontSize: 13)),
  ),
);

String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
