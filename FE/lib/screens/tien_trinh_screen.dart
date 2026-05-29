import 'package:flutter/material.dart';
import '../constants/colors.dart';

class TienTrinhScreen extends StatelessWidget {
  const TienTrinhScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Tiến trình của bạn'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Stats
            _buildMainStatCard(context),
            const SizedBox(height: 32),

            // Milestones
            Text(
              'Cột mốc chính',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildMilestonesList(context),
            const SizedBox(height: 32),

            // Benefits
            Text(
              'Lợi ích sức khỏe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildBenefitsGrid(context),
            const SizedBox(height: 32),

            // Daily Tips
            Text(
              'Lời khuyên hôm nay',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppColors.warning, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hãy uống nhiều nước',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Uống nước giúp giảm cơn thèm. Hãy cố gắng uống ít nhất 8 cốc nước mỗi ngày.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Ngày thứ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '45',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                label: 'Tiền tiết kiệm',
                value: '2.3M đ',
                color: AppColors.white,
              ),
              _buildStatColumn(
                context,
                label: 'Cập độ',
                value: '12',
                color: AppColors.white,
              ),
              _buildStatColumn(
                context,
                label: 'Tuổi thêm',
                value: '1.5 năm',
                color: AppColors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildMilestonesList(BuildContext context) {
    List<Map<String, dynamic>> milestones = [
      {
        'day': '7',
        'title': 'Một tuần',
        'description': 'Hệ hô hấp bắt đầu phục hồi',
        'icon': Icons.check_circle,
        'achieved': true,
      },
      {
        'day': '30',
        'title': 'Một tháng',
        'description': 'Khứu giác và vị giác cải thiện',
        'icon': Icons.check_circle,
        'achieved': true,
      },
      {
        'day': '90',
        'title': 'Ba tháng',
        'description': 'Chức năng phổi tăng 30%',
        'icon': Icons.schedule,
        'achieved': false,
      },
      {
        'day': '365',
        'title': 'Một năm',
        'description': 'Giảm 50% nguy cơ bệnh tim',
        'icon': Icons.lock_clock,
        'achieved': false,
      },
    ];

    return Column(
      children: milestones
          .map(
            (milestone) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMilestoneCard(context, milestone: milestone),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context, {
    required Map<String, dynamic> milestone,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milestone['achieved'] ? AppColors.success : AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            milestone['icon'],
            color: milestone['achieved']
                ? AppColors.success
                : AppColors.primaryBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone['title'],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestone['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid(BuildContext context) {
    List<Map<String, String>> benefits = [
      {'title': 'Khứu giác', 'icon': '👃'},
      {'title': 'Vị giác', 'icon': '👅'},
      {'title': 'Phổi', 'icon': '💨'},
      {'title': 'Tim', 'icon': '❤️'},
      {'title': 'Năng lực', 'icon': '⚡'},
      {'title': 'Da', 'icon': '✨'},
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: benefits
          .map(
            (benefit) => Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(benefit['icon']!, style: const TextTheme().displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    benefit['title']!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
