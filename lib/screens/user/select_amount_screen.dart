import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SelectAmountScreen extends StatefulWidget {
  final String cause;
  final Function(double) onAmountSelected;
  final VoidCallback onBack;

  const SelectAmountScreen({
    super.key,
    required this.cause,
    required this.onAmountSelected,
    required this.onBack,
  });

  @override
  State<SelectAmountScreen> createState() => _SelectAmountScreenState();
}

class _SelectAmountScreenState extends State<SelectAmountScreen> {
  double _amount = 500;
  final TextEditingController _amountCtrl = TextEditingController(text: '500');
  final List<double> _presets = [100, 500, 1000, 2500, 5000, 10000];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Select Amount', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                  const SizedBox(height: 2),
                  Text('Donating to ${widget.cause}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(children: [
                      const Text('Donation Amount (PKR)', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.black26),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _amount = double.tryParse(val) ?? 0;
                          });
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Adjust Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.primaryGreen,
                          inactiveTrackColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                          thumbColor: AppColors.primaryGreen,
                          overlayColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _amount.clamp(100.0, 50000.0), 
                          min: 100, max: 50000, divisions: 499, 
                          onChanged: (v) {
                            setState(() {
                              _amount = v;
                              _amountCtrl.text = v.toStringAsFixed(0);
                            });
                          }
                        ),
                      ),
                      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('PKR 100', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                        Text('PKR 50,000', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: _presets.map((preset) {
                    final selected = _amount == preset;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _amount = preset;
                          _amountCtrl.text = preset.toStringAsFixed(0);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryGreen : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.primaryGreen : AppColors.divider),
                          boxShadow: selected ? [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                        ),
                        child: Text('PKR ${preset.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.white : AppColors.textDark)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () => widget.onAmountSelected(_amount),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4, shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                      ),
                      child: const Text('Continue to Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
