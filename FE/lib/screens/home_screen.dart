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

        return Scaffold(
          backgroundColor: const Color(0xFFFDFDFD), // Very light clean background
          body: RefreshIndicator(
            onRefresh: _fetchData,
            color: const Color(0xFF6B4EFF),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopSection(user),
                  const SizedBox(height: 24),
                  _buildActionPills(),
                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hasDeclared)
                          _buildPromoCard(
                            title: 'Khai báo thói quen',
                            subtitle: 'Cá nhân hoá hành trình của bạn ngay hôm nay',
                            icon: CupertinoIcons.doc_text,
                            iconColor: const Color(0xFFFFA23A),
                            bgColor: const Color(0xFFFFF7ED),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.smokingStatus).then((_) => _fetchData()),
                          )
                        else if (!hasSelectedPlan)
                          _buildPromoCard(
                            title: 'Chọn kế hoạch cai thuốc',
                            subtitle: 'Hệ thống sẽ theo dõi và hỗ trợ bạn mỗi ngày',
                            icon: CupertinoIcons.flag,
                            iconColor: const Color(0xFFE11D48),
                            bgColor: const Color(0xFFFFF1F2),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.planSelection).then((_) => _fetchData()),
                          )
                        else
                          _buildPromoCard(
                            title: 'Check-in hôm nay',
                            subtitle: 'Ghi nhận tiến trình và cảm xúc của bạn',
                            icon: CupertinoIcons.checkmark_seal_fill,
                            iconColor: const Color(0xFF6B4EFF),
                            bgColor: const Color(0xFFF3F0FF),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.dailyCheckin).then((_) => _fetchData()),
                          ),

                        const SizedBox(height: 32),
                        const Text(
                          'Tiến độ Tuần này',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWeeklySection(user),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  //  TOP SECTION: HEADER + FLOATING CARD
  // ─────────────────────────────────────────
  Widget _buildTopSection(Map<String, dynamic>? user) {
    final fullname = ((user?['fullname'] as String?) ?? '').trim();
    final initials = _getUserInitials(user);

    return SizedBox(
      height: 380, // Total height to accommodate header + overlapping card
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Background Image / Color
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE8E2FA),
                image: DecorationImage(
                  image: AssetImage('assets/images/home_header_landscape.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // 2. User Info Row
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF6B4EFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullname.isNotEmpty ? fullname : 'Bạn mới',
                    style: const TextStyle(
                      color: Color(0xFF1E293B), // Dark text for light background
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Main Floating Card
          Positioned(
            bottom: 0,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Số ngày không hút thuốc',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_streak',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          'ngày',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Small badge for total avoided
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.nosign, size: 14, color: Color(0xFFEF4444)),
                            const SizedBox(width: 4),
                            Text(
                              '$_totalAvoided điếu',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Bottom metrics row (Money saved, etc)
                  Row(
                    children: [
                      _buildMiniStat(
                        icon: CupertinoIcons.money_dollar_circle_fill,
                        iconColor: const Color(0xFF10B981),
                        label: 'Tiết kiệm',
                        value: _formatMoney(_moneySaved),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _buildMiniStat(
                        icon: CupertinoIcons.heart_fill,
                        iconColor: const Color(0xFFF43F5E),
                        label: 'Sức khỏe',
                        value: 'Đang phục hồi',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({required IconData icon, required Color iconColor, required String label, required String value}) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  PILL ACTION BUTTONS
  // ─────────────────────────────────────────
  Widget _buildActionPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildPillBtn(
            icon: CupertinoIcons.calendar,
            label: 'Đặt lịch',
            bgColor: const Color(0xFF1E293B), // Dark pill
            textColor: Colors.white,
            iconColor: Colors.white,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingDoctorScreen())),
          ),
          const SizedBox(width: 12),
          _buildPillBtn(
            icon: CupertinoIcons.chart_bar_alt_fill,
            label: 'Tiến trình',
            bgColor: Colors.white,
            textColor: const Color(0xFF1E293B),
            iconColor: const Color(0xFF6B4EFF),
            onTap: () => Navigator.pushNamed(context, AppRoutes.tienTrinh),
          ),
          const SizedBox(width: 12),
          _buildPillBtn(
            icon: CupertinoIcons.person_2_fill,
            label: 'Cộng đồng',
            bgColor: Colors.white,
            textColor: const Color(0xFF1E293B),
            iconColor: const Color(0xFFF59E0B),
            onTap: () => Navigator.pushNamed(context, AppRoutes.congDong),
          ),
          const SizedBox(width: 12),
          _buildPillBtn(
            icon: CupertinoIcons.rosette,
            label: 'Xếp hạng',
            bgColor: Colors.white,
            textColor: const Color(0xFF1E293B),
            iconColor: const Color(0xFFF43F5E),
            onTap: () => Navigator.pushNamed(context, AppRoutes.bangXepHang),
          ),
          const SizedBox(width: 12),
          _buildPillBtn(
            icon: CupertinoIcons.doc_text_fill,
            label: 'Kế hoạch',
            bgColor: Colors.white,
            textColor: const Color(0xFF1E293B),
            iconColor: const Color(0xFF0EA5E9),
            onTap: () => Navigator.pushNamed(context, AppRoutes.keHoachCuaToi),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBtn({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: bgColor == Colors.white
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  PROMO / BANNER CARD
  // ─────────────────────────────────────────
  Widget _buildPromoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.arrow_right, color: Color(0xFF475569), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  WEEKLY SECTION
  // ─────────────────────────────────────────
  Widget _buildWeeklySection(Map<String, dynamic>? user) {
    final profile = user?['smokingProfile'] as Map<String, dynamic>?;
    final daily = (profile?['cigarettesPerDay'] as int?) ?? 10;

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

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      days[i % 7],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == todayIdx ? FontWeight.w800 : FontWeight.w600,
                        color: i == todayIdx ? const Color(0xFF6B4EFF) : const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1.5, dashArray: [4, 4]),
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
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  color: val == 0
                      ? const Color(0xFFF1F5F9)
                      : isToday
                          ? const Color(0xFF6B4EFF)
                          : const Color(0xFFCBD5E1),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 1.0,
                    color: const Color(0xFFF8FAFC),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
