import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header with User Profile
        SliverToBoxAdapter(child: _buildModernHeader(context)),

        // Main Content
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),
              _buildProgressCard(context),
              const SizedBox(height: 20),
              _buildMotivationalCard(context),
              const SizedBox(height: 24),
              _buildStatsSection(context),
              const SizedBox(height: 24),
              _buildFeaturedSection(context),
              const SizedBox(height: 24),
              _buildQuickActionsSection(context),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  /// Modern Header with Profile
  Widget _buildModernHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.darkGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, Bạn 👋',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hôm nay là một ngày tuyệt vời để tiếp tục',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // User Avatar Placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress Card with Day Counter and Savings
  Widget _buildProgressCard(BuildContext context) {
    const currentDay = 45;
    const totalDays = 365;
    const int saved = 2300000;
    final progressPercent = currentDay / totalDays;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.blueGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ hành trình',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Days Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày bỏ thuốc',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$currentDay ngày',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Tiền tiết kiệm',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(saved / 1000000).toStringAsFixed(1)}M',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progressPercent * 100).toStringAsFixed(1)}% Hoàn thành',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Mục tiêu: $totalDays ngày',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.warning.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Motivational Card with Tips
  Widget _buildMotivationalCard(BuildContext context) {
    const tips = [
      '💪 Mỗi ngày là một bước tiến. Bạn đang làm rất tốt!',
      '🎯 Hãy nhớ lý do bạn bắt đầu hành trình này.',
      '🌟 Những khó khăn sẽ qua đi, nhưng kết quả sẽ ở lại.',
      '✨ Bạn đủ mạnh mẽ để vượt qua nó!',
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.emeraldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandEmerald.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
              Text(
                'Lời động viên hôm nay',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('✨', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tips[0],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Stats Section with Enhanced Cards
  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê chi tiết',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildStatItem(
              context,
              icon: Icons.calendar_today,
              color: AppColors.primaryBlue,
              value: '45',
              label: 'Ngày thứ',
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            ),
            _buildStatItem(
              context,
              icon: Icons.attach_money,
              color: AppColors.success,
              value: '2.3M',
              label: 'Tiền tiết kiệm',
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
            ),
            _buildStatItem(
              context,
              icon: Icons.trending_up,
              color: AppColors.brandPurple,
              value: '12',
              label: 'Cấp độ',
              backgroundColor: AppColors.brandPurple.withValues(alpha: 0.1),
            ),
            _buildStatItem(
              context,
              icon: Icons.favorite,
              color: AppColors.brandPink,
              value: 'A+',
              label: 'Xếp hạng',
              backgroundColor: AppColors.brandPink.withValues(alpha: 0.1),
            ),
          ],
        ),
      ],
    );
  }

  /// Single Stat Item
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.mediumGrey.withValues(alpha: 0.3),
          width: 1,
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Featured Section
  Widget _buildFeaturedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khám phá',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItemEnhanced(
          context,
          gradient: AppColors.purpleGradient,
          icon: Icons.lightbulb_outline,
          title: 'Kế hoạch được đề xuất',
          description: 'Kế hoạch tùy chỉnh phù hợp với bạn',
          route: '/ke-hoach-de-xuat',
        ),
        const SizedBox(height: 12),
        _buildFeatureItemEnhanced(
          context,
          gradient: AppColors.orangeGradient,
          icon: Icons.people_outline,
          title: 'Khám phá cộng đồng',
          description: 'Kết nối với những người cùng chí hướng',
          route: '/cong-dong',
        ),
      ],
    );
  }

  /// Enhanced Feature Item
  Widget _buildFeatureItemEnhanced(
    BuildContext context, {
    required LinearGradient gradient,
    required IconData icon,
    required String title,
    required String description,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Actions Section
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hành động nhanh',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.calendar_month,
                label: 'Đặt lịch',
                color: AppColors.primaryBlue,
                route: '/dat-lich-hen',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.poll,
                label: 'Khảo sát',
                color: AppColors.success,
                route: '/khao-sat',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.trending_up,
                label: 'Tiến trình',
                color: AppColors.brandPurple,
                route: '/tien-trinh',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.emoji_events,
                label: 'Xếp hạng',
                color: AppColors.brandPink,
                route: '/bang-xep-hang',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickActionButton(
          context,
          icon: Icons.card_membership,
          label: 'Gói thành viên',
          color: AppColors.warning,
          route: AppRoutes.goiThanhVien,
          isFullWidth: true,
        ),
      ],
    );
  }

  /// Quick Action Button
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String route,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: isFullWidth
            ? const EdgeInsets.symmetric(vertical: 14, horizontal: 16)
            : const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
