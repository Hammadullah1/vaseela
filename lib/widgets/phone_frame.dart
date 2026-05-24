import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 390,
        height: 844,
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(color: Colors.black12, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
