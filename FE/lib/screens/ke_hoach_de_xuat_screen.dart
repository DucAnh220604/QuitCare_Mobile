import 'package:flutter/material.dart';
import '../constants/colors.dart';

class KeHoachDeXuatScreen extends StatelessWidget {
  const KeHoachDeXuatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Kế hoạch được đề xuất'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kế hoạch tùy chỉnh cho bạn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dựa trên hồ sơ và mục tiêu của bạn, chúng tôi đề xuất các kế hoạch phù hợp nhất.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilter(context, label: 'Tất cả', isActive: true),
                _buildFilter(context, label: 'Nhanh', isActive: false),
                _buildFilter(context, label: 'Từ từ', isActive: false),
                _buildFilter(context, label: 'Nghiêm ngặt', isActive: false),
              ],
            ),
            const SizedBox(height: 24),

            // Plans
            Text(
              'Gợi ý cho bạn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPlanCard(
                    context,
                    title: [
                      'Kế hoạch Từ Từ',
                      'Kế hoạch Nhanh',
                      'Kế hoạch Cân Bằng',
                    ][index],
                    description: [
                      'Giảm dần lượng thuốc theo thời gian',
                      'Bỏ thuốc hoàn toàn trong 30 ngày',
                      'Cân bằng giữa từ từ và nhanh',
                    ][index],
                    duration: ['90 ngày', '30 ngày', '60 ngày'][index],
                    difficulty: ['Dễ', 'Khó', 'Trung bình'][index],
                    successRate: ['85%', '65%', '78%'][index],
                    onStart: () {},
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter(
    BuildContext context, {
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: AppColors.divider, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String description,
    required String duration,
    required String difficulty,
    required String successRate,
    required VoidCallback onStart,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.star, color: AppColors.warning, size: 24),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(context, label: 'Thời gian', value: duration),
              _buildStat(context, label: 'Độ khó', value: difficulty),
              _buildStat(context, label: 'Thành công', value: successRate),
            ],
          ),
          const SizedBox(height: 16),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Bắt đầu kế hoạch',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
