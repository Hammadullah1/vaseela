import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ChooseCauseScreen extends StatelessWidget {
  final Function(String) onCauseSelected;
  final VoidCallback onBack;

  const ChooseCauseScreen({
    super.key,
    required this.onCauseSelected,
    required this.onBack,
  });

  static const List<Map<String, dynamic>> _causes = [
    {'title': 'Hunger Relief', 'desc': 'Provide meals to those in need', 'icon': Icons.restaurant, 'color': Color(0xFFE53935), 'key': 'hunger'},
    {'title': 'Education', 'desc': "Support children's education", 'icon': Icons.school, 'color': Color(0xFF1976D2), 'key': 'education'},
    {'title': 'Capital Fund', 'desc': 'Help small businesses grow', 'icon': Icons.account_balance, 'color': Color(0xFFF5A623), 'key': 'capital'},
    {'title': 'Healthcare', 'desc': 'Medical aid for the underprivileged', 'icon': Icons.local_hospital, 'color': Color(0xFF43A047), 'key': 'healthcare'},
    {'title': 'Shelter', 'desc': 'Build homes for the homeless', 'icon': Icons.home, 'color': Color(0xFF8E24AA), 'key': 'shelter'},
    {'title': 'Clean Water', 'desc': 'Provide clean drinking water', 'icon': Icons.water_drop, 'color': Color(0xFF0288D1), 'key': 'water'},
  ];

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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: AppColors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose a Cause', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                    SizedBox(height: 2),
                    Text('Select where you want to donate', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 1.05, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                itemCount: _causes.length,
                itemBuilder: (context, index) {
                  final cause = _causes[index];
                  return GestureDetector(
                    onTap: () => onCauseSelected(cause['key'] as String),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: (cause['color'] as Color).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(cause['icon'] as IconData, color: cause['color'] as Color, size: 26),
                          ),
                          const SizedBox(height: 10),
                          Text(cause['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          const SizedBox(height: 3),
                          Text(cause['desc'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
