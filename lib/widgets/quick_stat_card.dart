import 'package:flutter/material.dart';
import '../constants/colors.dart';

const _shadowList = [
  BoxShadow(
    color: Color.fromRGBO(25, 28, 29, 0.06),
    blurRadius: 10,
    offset: Offset(0, 2),
  ),
];

const _border = Border(
  top: BorderSide(color: Color(0xFFE9ECEF), width: 0.5),
  bottom: BorderSide(color: Color(0xFFE9ECEF), width: 0.5),
  left: BorderSide(color: Color(0xFFE9ECEF), width: 0.5),
  right: BorderSide(color: Color(0xFFE9ECEF), width: 0.5),
);

class QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _shadowList,
          border: _border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
