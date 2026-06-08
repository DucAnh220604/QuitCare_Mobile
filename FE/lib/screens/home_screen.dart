import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';
import '../services/auth_provider.dart';
import '../services/plan_service.dart';
import '../services/progress_service.dart';
import '../screens/booking_doctor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlanService _planService = PlanService();
  final ProgressService _progressService = ProgressService();

  Map<String, dynamic>? _recommendedPlan;
  int _streak = 0;
  int _moneySaved = 0;
  int _totalAvoided = 0;
  List<Map<String, dynamic>> _weeklyLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchRecommendedPlan(),
      _fetchProgressStats(),
      _fetchWeeklyHistory(),
    ]);
  }

  Future<void> _fetchProgressStats() async {
    final result = await _progressService.getProgressStats();
    if (result['success'] && mounted) {
      setState(() {
        _streak = result['data']['streak'] ?? 0;
        _moneySaved = result['data']['moneySaved'] ?? 0;
        _totalAvoided = result['data']['totalAvoided'] ?? 0;
      });
    }
  }

  Future<void> _fetchWeeklyHistory() async {
    final result = await _progressService.getHistory();
    if (result['success'] && mounted) {
      final logs = (result['data'] as List? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() => _weeklyLogs = logs);
    }
  }

  Future<void> _fetchRecommendedPlan() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.user?['smokingProfile'];
    if (profile != null && (profile['cigarettesPerDay'] ?? 0) > 0) {
      final result = await _planService.getRecommendedPlan();
      if (result['success'] && mounted) {
        setState(() => _recommendedPlan = result['recommendedPlan']);
      }
    }
  }

  bool _hasDeclaredProfile(Map<String, dynamic>? user) {
    final profile = user?['smokingProfile'] as Map<String, dynamic>?;
    return profile != null && ((profile['cigarettesPerDay'] as int?) ?? 0) > 0;
  }

  bool _hasSelectedPlan(Map<String, dynamic>? user) {
    final profile = user?['smokingProfile'] as Map<String, dynamic>?;
    if (profile == null) return false;
    return profile['currentPlan'] != null || profile['activeQuitPlanId'] != null;
  }

  String _getTimeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    return '$amount ₫';
  }

  String _getUserInitials(Map<String, dynamic>? user) {
    final name = ((user?['fullname'] as String?) ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((String p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final hasDeclared = _hasDeclaredProfile(user);
        final hasSelectedPlan = _hasSelectedPlan(user);

        return RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(user)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!hasDeclared)
                      _buildStepCard(
                        step: '01',
                        title: 'Khai báo thói quen',
                        subtitle:
                            'Cho chúng tôi biết tình trạng hút thuốc hiện tại để cá nhân hoá hành trình của bạn.',
                        buttonLabel: 'Bắt đầu khai báo',
                        icon: CupertinoIcons.doc_text,
                        color: AppColors.primaryBlue,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.smokingStatus)
                            .then((_) => _fetchData()),
                      )
                    else if (!hasSelectedPlan)
                      _buildStepCard(
                        step: '02',
                        title: 'Chọn kế hoạch cai thuốc',
                        subtitle:
                            'Chọn kế hoạch phù hợp với bản thân để hệ thống theo dõi và hỗ trợ bạn mỗi ngày.',
                        buttonLabel: 'Xem kế hoạch',
                        icon: CupertinoIcons.flag,
                        color: AppColors.brandOrange,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.planSelection)
                            .then((_) => _fetchData()),
                      )
                    else ...[
                      _buildProgressCard(user),
                      const SizedBox(height: 16),
                      _buildCheckinCard(context),
                      const SizedBox(height: 24),
                      _buildWeeklySection(context, user),
                    ],

                    const SizedBox(height: 24),
                    _buildActionsSection(context),
                    const SizedBox(height: 20),
                    _buildCommunityCard(context),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────

  Widget _buildHeader(Map<String, dynamic>? user) {
    final fullname = ((user?['fullname'] as String?) ?? '').trim();
    final nameParts = fullname.split(' ').where((String p) => p.isNotEmpty).toList();
    final name = nameParts.isNotEmpty ? nameParts.last : 'bạn';
    final initials = _getUserInitials(user);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002D6E), Color(0xFF0057CC)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Background decorative illustration (right side)
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 180,
                child: CustomPaint(
                  painter: _LungsPainter(color: Colors.white),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTimeGreeting(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification
                      _headerIconBtn(CupertinoIcons.bell),
                      const SizedBox(width: 8),
                      // Avatar
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.hoSo),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Streak/status chip
                  _buildHeaderChip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildHeaderChip() {
    if (_streak == 0) {
      return _chip(
        icon: CupertinoIcons.rocket,
        color: Colors.white,
        label: 'Sẵn sàng bắt đầu hành trình',
        bg: Colors.white.withValues(alpha: 0.15),
      );
    }
    return _chip(
      icon: CupertinoIcons.flame,
      color: const Color(0xFFFFB020),
      label: '$_streak ngày không hút thuốc',
      bg: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _chip({
    required IconData icon,
    required Color color,
    required String label,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  ONBOARDING STEP CARD
  // ─────────────────────────────────────────

  Widget _buildStepCard({
    required String step,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bước $step',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  PROGRESS CARD
  // ─────────────────────────────────────────

  Widget _buildProgressCard(Map<String, dynamic>? user) {
    final totalDays = (_recommendedPlan?['durationDays'] ?? 365) as int;
    final progressPercent = totalDays > 0 ? (_streak / totalDays).clamp(0.0, 1.0) : 0.0;
    final daysRemaining = (totalDays - _streak).clamp(0, totalDays);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TIẾN ĐỘ KẾ HOẠCH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tienTrinh),
                  child: Row(
                    children: [
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 11, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Big day counter + progress
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_streak',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ngày',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'không hút thuốc',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Percent badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progressPercent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEEF2FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mục tiêu: $totalDays ngày',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFFF0F0F0)),

          // Bottom 3 metrics
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _metricCell(
                  icon: CupertinoIcons.money_dollar_circle,
                  iconColor: const Color(0xFF16A34A),
                  value: _formatMoney(_moneySaved),
                  label: 'Tiết kiệm',
                ),
                _verticalDivider(),
                _metricCell(
                  icon: CupertinoIcons.nosign,
                  iconColor: AppColors.brandPurple,
                  value: '$_totalAvoided',
                  label: 'Điếu né tránh',
                ),
                _verticalDivider(),
                _metricCell(
                  icon: CupertinoIcons.flag,
                  iconColor: AppColors.brandOrange,
                  value: '$daysRemaining',
                  label: 'Ngày còn lại',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        height: 44,
        color: const Color(0xFFF0F0F0),
      );

  // ─────────────────────────────────────────
  //  CHECK-IN CARD
  // ─────────────────────────────────────────

  Widget _buildCheckinCard(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.dailyCheckin).then((_) => _fetchData()),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in hôm nay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ghi nhận tiến trình và cảm xúc của bạn',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Bắt đầu',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  WEEKLY CHART SECTION
  // ─────────────────────────────────────────

  Widget _buildWeeklySection(BuildContext context, Map<String, dynamic>? user) {
    final profile = user?['smokingProfile'] as Map<String, dynamic>?;
    final daily = (profile?['cigarettesPerDay'] as int?) ?? 10;

    // Build weekData from real API history: 7 days Mon→Sun of current week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final weekData = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final dayStr = day.toIso8601String().substring(0, 10);
      final log = _weeklyLogs.firstWhere(
        (l) => ((l['date'] as String?) ?? '').startsWith(dayStr),
        orElse: () => {},
      );
      if (log.isEmpty) return 0.0;
      final smoked = (log['cigarettesSmoked'] as int?) ?? 0;
      if (daily == 0) return 0.0;
      return ((daily - smoked) / daily).clamp(0.0, 1.0);
    });

    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final todayIdx = (now.weekday - 1) % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TUẦN NÀY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'Điếu/ngày: $daily',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          days[i % 7],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == todayIdx ? FontWeight.w800 : FontWeight.w500,
                            color: i == todayIdx
                                ? AppColors.primaryBlue
                                : AppColors.textTertiary,
                          ),
                        ),
                      );
                    },
                    reservedSize: 26,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.5,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: const Color(0xFFF0F0F0),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final val = weekData[i % weekData.length];
                final isToday = i == todayIdx;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: val > 0 ? val : 0.05,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      color: val == 0
                          ? const Color(0xFFE8ECF4)
                          : isToday
                              ? AppColors.brandPurple
                              : AppColors.primaryBlue,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 1.0,
                        color: const Color(0xFFF5F7FF),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  //  QUICK ACTIONS
  // ─────────────────────────────────────────

  Widget _buildActionsSection(BuildContext context) {
    final items = [
      _Action(icon: CupertinoIcons.calendar, label: 'Đặt lịch',
          color: AppColors.primaryBlue, onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BookingDoctorScreen()))),
      _Action(icon: CupertinoIcons.chart_bar_alt_fill, label: 'Tiến trình',
          color: AppColors.brandPurple,
          onTap: () => Navigator.pushNamed(context, AppRoutes.tienTrinh)),
      _Action(icon: CupertinoIcons.doc_text, label: 'Kế hoạch',
          color: const Color(0xFF0EA5E9),
          onTap: () => Navigator.pushNamed(context, AppRoutes.keHoachCuaToi)),
      _Action(icon: CupertinoIcons.rosette, label: 'Xếp hạng',
          color: AppColors.brandPink,
          onTap: () => Navigator.pushNamed(context, AppRoutes.bangXepHang)),
      _Action(icon: CupertinoIcons.person_2, label: 'Cộng đồng',
          color: AppColors.brandOrange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.congDong)),
      _Action(icon: CupertinoIcons.rosette, label: 'VIP',
          color: const Color(0xFFD97706),
          onTap: () => Navigator.pushNamed(context, AppRoutes.goiThanhVien)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRUY CẬP NHANH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildActionTile(items[i]),
        ),
      ],
    );
  }

  Widget _buildActionTile(_Action a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(a.icon, color: a.color, size: 22),
            ),
            const SizedBox(height: 9),
            Text(
              a.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  COMMUNITY CARD
  // ─────────────────────────────────────────

  Widget _buildCommunityCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.congDong),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandOrange.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
                  ),
                ),
              ),
              // Decorative circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.person_2,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Khám phá cộng đồng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Kết nối với người cùng hành trình',
                            style: TextStyle(
                              color: Color(0xEEFFFFFF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.arrow_right,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  DATA CLASSES
// ─────────────────────────────────────────

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// ─────────────────────────────────────────
//  CUSTOM PAINTER — LUNGS ILLUSTRATION
// ─────────────────────────────────────────

class _LungsPainter extends CustomPainter {
  final Color color;
  const _LungsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Fill paint (lung shapes) ---
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.07);

    // --- Stroke paint ---
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.3);

    // Left lung
    final leftLung = Path()
      ..moveTo(w * 0.48, h * 0.72)
      ..cubicTo(w * 0.48, h * 0.88, w * 0.05, h * 0.88, w * 0.05, h * 0.55)
      ..cubicTo(w * 0.05, h * 0.3, w * 0.25, h * 0.2, w * 0.42, h * 0.34)
      ..cubicTo(w * 0.46, h * 0.38, w * 0.48, h * 0.5, w * 0.48, h * 0.72)
      ..close();
    canvas.drawPath(leftLung, fill);
    canvas.drawPath(leftLung, stroke);

    // Right lung
    final rightLung = Path()
      ..moveTo(w * 0.52, h * 0.72)
      ..cubicTo(w * 0.52, h * 0.88, w * 0.95, h * 0.88, w * 0.95, h * 0.55)
      ..cubicTo(w * 0.95, h * 0.3, w * 0.75, h * 0.2, w * 0.58, h * 0.34)
      ..cubicTo(w * 0.54, h * 0.38, w * 0.52, h * 0.5, w * 0.52, h * 0.72)
      ..close();
    canvas.drawPath(rightLung, fill);
    canvas.drawPath(rightLung, stroke);

    // Trachea
    final trachea = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35);
    canvas.drawLine(Offset(w * 0.5, h * 0.06), Offset(w * 0.5, h * 0.34), trachea);

    // Bronchi
    canvas.drawLine(Offset(w * 0.5, h * 0.34), Offset(w * 0.33, h * 0.46), trachea);
    canvas.drawLine(Offset(w * 0.5, h * 0.34), Offset(w * 0.67, h * 0.46), trachea);

    // Branch subdivisions (left)
    final branch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.22);

    canvas.drawLine(Offset(w * 0.33, h * 0.46), Offset(w * 0.22, h * 0.56), branch);
    canvas.drawLine(Offset(w * 0.33, h * 0.46), Offset(w * 0.35, h * 0.58), branch);
    canvas.drawLine(Offset(w * 0.22, h * 0.56), Offset(w * 0.18, h * 0.65), branch);
    canvas.drawLine(Offset(w * 0.22, h * 0.56), Offset(w * 0.26, h * 0.66), branch);

    // Branch subdivisions (right)
    canvas.drawLine(Offset(w * 0.67, h * 0.46), Offset(w * 0.78, h * 0.56), branch);
    canvas.drawLine(Offset(w * 0.67, h * 0.46), Offset(w * 0.65, h * 0.58), branch);
    canvas.drawLine(Offset(w * 0.78, h * 0.56), Offset(w * 0.82, h * 0.65), branch);
    canvas.drawLine(Offset(w * 0.78, h * 0.56), Offset(w * 0.74, h * 0.66), branch);

    // Small leaf accents (top of each lung — growing leaves symbolising recovery)
    _drawLeaf(canvas, Offset(w * 0.2, h * 0.24), math.pi * 0.2, color, size);
    _drawLeaf(canvas, Offset(w * 0.8, h * 0.24), math.pi * 0.8, color, size);
  }

  void _drawLeaf(
      Canvas canvas, Offset origin, double angle, Color c, Size size) {
    final leafFill = Paint()
      ..style = PaintingStyle.fill
      ..color = c.withValues(alpha: 0.2);
    final leafStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = c.withValues(alpha: 0.4);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(-8, -14, 8, -14, 0, 0);

    canvas.drawPath(leaf, leafFill);
    canvas.drawPath(leaf, leafStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
