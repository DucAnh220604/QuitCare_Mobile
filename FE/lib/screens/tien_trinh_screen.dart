import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../constants/colors.dart';
import '../services/progress_service.dart';
import '../routes/app_routes.dart';

class TienTrinhScreen extends StatefulWidget {
  const TienTrinhScreen({super.key});

  @override
  State<TienTrinhScreen> createState() => _TienTrinhScreenState();
}

class _TienTrinhScreenState extends State<TienTrinhScreen> {
  final _progressService = ProgressService();

  bool _isLoading = true;
  bool _isHistoryLoading = false;
  int _streak = 0;
  int _moneySaved = 0;
  int _totalAvoided = 0;
  int _durationDays = 0;
  int _logsCount = 0;
  bool _hasCheckedInToday = false;
  bool _isCompleting = false;
  Map<String, dynamic>? _quitPlanInfo;

  // history & calendar
  List<Map<String, dynamic>> _history = [];
  Map<String, Map<String, dynamic>> _logsByDate = {};
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // ── static labels ─────────────────────────────────────────────────────────
  static const _weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _viMonths = [
    '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
    'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchStats(), _fetchHistory()]);
  }

  Future<void> _fetchStats() async {
    if (!_isLoading) setState(() => _isLoading = true);
    final result = await _progressService.getProgressStats();
    if (result['success'] && mounted) {
      setState(() {
        _streak = result['data']['streak'] ?? 0;
        _moneySaved = result['data']['moneySaved'] ?? 0;
        _totalAvoided = result['data']['totalAvoided'] ?? 0;
        _hasCheckedInToday = result['data']['hasCheckedInToday'] ?? false;
        _durationDays = result['data']['durationDays'] ?? 0;
        _logsCount = result['data']['logsCount'] ?? 0;
        _quitPlanInfo = result['data']['quitPlan'] as Map<String, dynamic>?;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchHistory() async {
    setState(() => _isHistoryLoading = true);
    final result = await _progressService.getHistory();
    if (result['success'] && mounted) {
      final logs = (result['data'] as List? ?? []).cast<Map<String, dynamic>>();
      final byDate = <String, Map<String, dynamic>>{};
      for (final log in logs) {
        final dt = DateTime.tryParse(log['date']?.toString() ?? '');
        if (dt != null) byDate[_key(dt)] = log;
      }
      setState(() {
        _history = logs;
        _logsByDate = byDate;
      });
    }
    if (mounted) setState(() => _isHistoryLoading = false);
  }

  // ── getters ───────────────────────────────────────────────────────────────

  bool get _hasPlan => _quitPlanInfo != null;
  bool get _isCompleted => _durationDays > 0 && _logsCount >= _durationDays;

  DateTime? get _planStart {
    final s = _quitPlanInfo?['overallStartDate'];
    return s != null ? DateTime.tryParse(s.toString()) : null;
  }

  DateTime? get _planEnd {
    final s = _quitPlanInfo?['overallEndDate'];
    return s != null ? DateTime.tryParse(s.toString()) : null;
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _key(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _fmtDate(dynamic v) {
    if (v == null) return '--';
    final dt = DateTime.tryParse(v.toString());
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _fmtMoney(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K đ';
    return '$amount đ';
  }

  String _viWeekday(int w) {
    const n = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return n[w.clamp(1, 7)];
  }

  String _moodEmoji(String? m) {
    if (m == 'Tốt') return '😊';
    if (m == 'Tệ') return '😔';
    return '😐';
  }

  String _cravingEmoji(String? c) {
    if (c == 'Không thèm') return '💪';
    if (c == 'Thèm nhiều') return '😰';
    return '😤';
  }

  bool _isWithinPlan(DateTime day) {
    final s = _planStart;
    final e = _planEnd;
    if (s == null || e == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(DateTime(s.year, s.month, s.day)) &&
        !d.isAfter(DateTime(e.year, e.month, e.day));
  }

  int? _targetForDate(DateTime date) {
    final stages = _quitPlanInfo?['stages'] as List?;
    if (stages == null) return null;
    for (final raw in stages) {
      final stage = raw as Map<String, dynamic>;
      final s = DateTime.tryParse(stage['startDate']?.toString() ?? '');
      final e = DateTime.tryParse(stage['endDate']?.toString() ?? '');
      if (s == null || e == null) continue;
      final d = DateTime(date.year, date.month, date.day);
      if (!d.isBefore(DateTime(s.year, s.month, s.day)) &&
          !d.isAfter(DateTime(e.year, e.month, e.day))) {
        return stage['cigarettesPerDay'] as int?;
      }
    }
    return null;
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _completePlan() async {
    setState(() => _isCompleting = true);
    final result = await _progressService.completePlan();
    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: AppColors.success),
      );
      await Provider.of<AuthProvider>(context, listen: false).fetchProfile();
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Có lỗi xảy ra'), backgroundColor: AppColors.danger),
      );
      setState(() => _isCompleting = false);
    }
  }

  Future<void> _forceSimulate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận giả lập'),
        content: const Text('Hành động này sẽ xóa toàn bộ nhật ký hiện tại và tạo dữ liệu giả lập cho demo. Bạn có chắc chắn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _isLoading = true);
      final result = await _progressService.forceSimulate();
      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: AppColors.success),
        );
        _fetchAll();
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          title: const Text('Tiến trình của bạn'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.electric_bolt, color: AppColors.warning),
              tooltip: 'Giả lập dữ liệu Demo',
              onPressed: _isLoading ? null : _forceSimulate,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Lịch sử'),
              Tab(text: 'Hồi phục'),
            ],
          ),
        ),
        floatingActionButton: _isLoading || !_hasPlan
            ? null
            : (_isCompleted
                ? FloatingActionButton.extended(
                    onPressed: _isCompleting ? null : _completePlan,
                    backgroundColor: AppColors.success,
                    icon: _isCompleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.emoji_events, color: Colors.white),
                    label: Text(
                      _isCompleting ? 'Đang xử lý...' : 'Hoàn tất Kế hoạch',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                : (!_hasCheckedInToday
                    ? FloatingActionButton.extended(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.dailyCheckin)
                            .then((v) { if (v == true) _fetchAll(); }),
                        backgroundColor: AppColors.warning,
                        icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                        label: const Text('Ghi nhận hôm nay',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    : (DateTime.now().hour < 21
                        ? FloatingActionButton.extended(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.dailyCheckin)
                                .then((v) { if (v == true) _fetchAll(); }),
                            backgroundColor: const Color(0xFF3B82F6),
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                            label: const Text('Sửa ghi nhận',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        : null))),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildHistoryTab(),
                  _buildRecoveryTab(),
                ],
              ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  TAB 1 — TỔNG QUAN
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildOverviewTab() {
    if (!_hasPlan) return _buildNoPlanState();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainStatCard(),
          const SizedBox(height: 24),
          Text('Kế hoạch hiện tại',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 12),
          _buildPlanInfoCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildNoPlanState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flag_outlined, size: 56, color: AppColors.primaryBlue.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Text('Chưa có kế hoạch cai thuốc',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Hãy tạo kế hoạch để bắt đầu theo dõi tiến trình và ghi nhận hằng ngày.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.planSelection).then((_) => _fetchAll()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo kế hoạch ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Số ngày không hút thuốc',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 8),
          Text('$_streak',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              )),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCol('Tiền tiết kiệm', _fmtMoney(_moneySaved), AppColors.warning),
              Container(width: 1, height: 40, color: Colors.white24),
              _statCol('Số điếu tránh được', '$_totalAvoided', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              )),
          const SizedBox(height: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.white.withValues(alpha: 0.9))),
        ],
      );

  Widget _buildPlanInfoCard() {
    final info = _quitPlanInfo!;
    final currentStage = info['currentStage'] as Map<String, dynamic>?;
    final currentIdx = (info['currentStageIndex'] as int?) ?? -1;
    final totalStages = (info['totalStages'] as int?) ?? 0;
    final progress = (info['overallProgress'] as num?)?.toDouble() ?? 0.0;
    final type = info['type'] as String? ?? 'suggested';
    final overallEnd = _fmtDate(info['overallEndDate']);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.keHoachCuaToi),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'suggested' ? Icons.auto_awesome : Icons.edit_note_rounded,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type == 'suggested' ? 'Kế hoạch đề xuất' : 'Kế hoạch tự lập',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tiến độ tổng thể',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 8),
            Text('Dự kiến kết thúc: $overallEnd',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (currentStage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('GĐ ${currentIdx + 1}/$totalStages',
                          style: const TextStyle(
                              color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentStage['stageName'] ?? '',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            () {
                              final c = currentStage['cigarettesPerDay'] as int? ?? 0;
                              return c == 0 ? 'Mục tiêu: Hoàn toàn cai thuốc' : 'Mục tiêu: $c điếu/ngày';
                            }(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmtDate(currentStage['startDate'])} → ${_fmtDate(currentStage['endDate'])}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  TAB 2 — LỊCH SỬ (calendar + history list)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    if (!_hasPlan) return _buildNoPlanState();
    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: AppColors.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSummaryCard(),
            const SizedBox(height: 16),
            _buildCalendar(),
            const SizedBox(height: 24),
            _buildHistoryListSection(),
          ],
        ),
      ),
    );
  }

  // ── monthly summary ───────────────────────────────────────────────────────

  Widget _buildMonthSummaryCard() {
    final now = DateTime.now();
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final lastDay = _calendarMonth.month == now.month && _calendarMonth.year == now.year
        ? now.day
        : daysInMonth;

    int checked = 0;
    int missed = 0;

    for (int d = 1; d <= lastDay; d++) {
      final day = DateTime(_calendarMonth.year, _calendarMonth.month, d);
      if (!_isWithinPlan(day)) continue;
      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
      if (isToday) continue;
      if (_logsByDate.containsKey(_key(day))) {
        checked++;
      } else {
        missed++;
      }
    }

    final total = checked + missed;
    final pct = total == 0 ? 0.0 : checked / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_viMonths[_calendarMonth.month]} ${_calendarMonth.year}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryStatItem('✅', '$checked', 'Ghi nhận'),
              _divider(),
              _summaryStatItem('❌', '$missed', 'Bỏ lỡ'),
              _divider(),
              _summaryStatItem('📊', '${(pct * 100).toStringAsFixed(0)}%', 'Hoàn thành'),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryStatItem(String emoji, String value, String label) => Expanded(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3));

  // ── calendar ──────────────────────────────────────────────────────────────

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1; // 0=Mon

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // navigation header
          Row(
            children: [
              _calNavBtn(Icons.chevron_left, () {
                setState(() => _calendarMonth =
                    DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1));
              }),
              Expanded(
                child: Text(
                  '${_viMonths[_calendarMonth.month]} ${_calendarMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              _calNavBtn(Icons.chevron_right, () {
                setState(() => _calendarMonth =
                    DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1));
              }),
            ],
          ),
          const SizedBox(height: 12),

          // weekday labels
          Row(
            children: _weekLabels.map((l) => Expanded(
              child: Center(
                child: Text(l,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // day grid
          Builder(builder: (_) {
            final cells = <Widget>[];
            // leading blanks
            for (int i = 0; i < startOffset; i++) {
              cells.add(const SizedBox());
            }
            for (int d = 1; d <= daysInMonth; d++) {
              final day = DateTime(_calendarMonth.year, _calendarMonth.month, d);
              cells.add(_buildDayCell(day, now));
            }
            // trailing blanks to complete row
            while (cells.length % 7 != 0) {
              cells.add(const SizedBox());
            }

            final rows = <Widget>[];
            for (int r = 0; r < cells.length; r += 7) {
              rows.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: List.generate(7, (c) => Expanded(child: cells[r + c])),
                  ),
                ),
              );
            }
            return Column(children: rows);
          }),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(const Color(0xFF10B981), '✓ Ghi nhận'),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFFF43F5E), '✗ Bỏ lỡ'),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFFCBD5E1), '○ Chưa đến'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      );

  Widget _legendItem(Color color, String label) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      );

  Widget _buildDayCell(DateTime day, DateTime now) {
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
    final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
    final dayKey = _key(day);
    final withinPlan = _isWithinPlan(day);
    final log = _logsByDate[dayKey];
    final hasLog = log != null;

    Color? bgColor;
    Color textColor = AppColors.textPrimary;
    Widget overlayIcon = const SizedBox.shrink();
    bool hasBorder = false;
    Color borderColor = AppColors.primaryBlue;

    if (isToday) {
      hasBorder = true;
      bgColor = AppColors.primaryBlue.withValues(alpha: 0.08);
      textColor = AppColors.primaryBlue;
    } else if (isPast && withinPlan) {
      if (hasLog) {
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        overlayIcon = const Icon(Icons.check, size: 10, color: Colors.white);
      } else {
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFF43F5E);
        overlayIcon = const Icon(Icons.close, size: 10, color: Color(0xFFF43F5E));
      }
    } else if (!isPast && !isToday) {
      textColor = const Color(0xFFCBD5E1);
    } else if (!withinPlan) {
      textColor = const Color(0xFFCBD5E1);
    }

    return GestureDetector(
      onTap: hasLog
          ? () => _showDayDetails(context, dayKey, log)
          : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: hasBorder ? Border.all(color: borderColor, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: textColor,
                ),
              ),
              overlayIcon,
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, String dateKey, Map<String, dynamic> log) {
    final dt = DateTime.tryParse(log['date']?.toString() ?? '');
    final dateLabel = dt != null
        ? '${_viWeekday(dt.weekday)}, ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
        : dateKey;
    final smoked = log['cigarettesSmoked'] as int? ?? 0;
    final mood = log['mood'] as String? ?? '';
    final craving = log['cravingLevel'] as String? ?? '';
    final symptoms = (log['symptoms'] as List?)?.cast<String>() ?? [];
    final note = log['note'] as String? ?? '';
    final target = dt != null ? _targetForDate(dt) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // drag handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_today_rounded,
                                color: AppColors.primaryBlue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(dateLabel,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // cigarettes
                      _detailRow(
                        label: 'Số điếu đã hút',
                        value: '$smoked điếu',
                        icon: Icons.smoking_rooms_rounded,
                        valueColor: smoked == 0
                            ? const Color(0xFF10B981)
                            : (target != null && smoked <= target
                                ? AppColors.primaryBlue
                                : AppColors.danger),
                        trailing: target != null
                            ? Text(
                                smoked <= target ? '✅ Đạt mục tiêu' : '⚠️ Vượt mục tiêu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: smoked <= target ? const Color(0xFF10B981) : AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      if (target != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text('Mục tiêu kế hoạch: ${target == 0 ? '0' : '≤$target'} điếu',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _detailRow(
                              label: 'Tâm trạng',
                              value: '${_moodEmoji(mood)} $mood',
                              icon: Icons.sentiment_satisfied_alt_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _detailRow(
                              label: 'Mức thèm',
                              value: '${_cravingEmoji(craving)} $craving',
                              icon: Icons.local_fire_department_rounded,
                            ),
                          ),
                        ],
                      ),

                      if (symptoms.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Triệu chứng',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: symptoms
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(s,
                                        style: const TextStyle(
                                            fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                        ),
                      ],

                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Icon(Icons.format_quote_rounded, size: 14, color: AppColors.textSecondary),
                                SizedBox(width: 6),
                                Text('Ghi chú',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                              ]),
                              const SizedBox(height: 6),
                              Text(note,
                                  style: const TextStyle(
                                      fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 14,
                          color: valueColor ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w700)),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── history list ──────────────────────────────────────────────────────────

  Widget _buildHistoryListSection() {
    final monthLogs = _history.where((log) {
      final dt = DateTime.tryParse(log['date']?.toString() ?? '');
      return dt != null && dt.year == _calendarMonth.year && dt.month == _calendarMonth.month;
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lịch sử ghi nhận',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (_isHistoryLoading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_viMonths[_calendarMonth.month]} ${_calendarMonth.year} · ${monthLogs.length} bản ghi',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (monthLogs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.history_rounded, size: 48, color: AppColors.divider.withValues(alpha: 0.8)),
                  const SizedBox(height: 12),
                  const Text('Chưa có dữ liệu trong tháng này',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          ...monthLogs.map((log) => _buildLogCard(log)),
      ],
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final dt = DateTime.tryParse(log['date']?.toString() ?? '');
    if (dt == null) return const SizedBox();
    final smoked = log['cigarettesSmoked'] as int? ?? 0;
    final mood = log['mood'] as String? ?? '';
    final craving = log['cravingLevel'] as String? ?? '';
    final symptoms = (log['symptoms'] as List?)?.cast<String>() ?? [];
    final note = log['note'] as String? ?? '';
    final target = _targetForDate(dt);
    final withinTarget = target == null || smoked <= target;
    final dotColor = smoked == 0
        ? const Color(0xFF10B981)
        : (withinTarget ? AppColors.primaryBlue : AppColors.danger);

    return GestureDetector(
      onTap: () => _showDayDetails(context, _key(dt), log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_viWeekday(dt.weekday)}, ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    smoked == 0 ? '🏆 0 điếu' : '$smoked điếu',
                    style: TextStyle(fontSize: 11, color: dotColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _logPill('${_moodEmoji(mood)} $mood', const Color(0xFF6B4EFF)),
                const SizedBox(width: 8),
                _logPill('${_cravingEmoji(craving)} $craving', const Color(0xFF0EA5E9)),
                if (target != null) ...[
                  const SizedBox(width: 8),
                  _logPill(
                    withinTarget ? '✅ Đạt mục tiêu' : '⚠️ Vượt mục tiêu',
                    withinTarget ? const Color(0xFF10B981) : AppColors.danger,
                  ),
                ],
              ],
            ),
            if (symptoms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: symptoms
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ))
                    .toList(),
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"$note"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _logPill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );

  // ═════════════════════════════════════════════════════════════════════════
  //  TAB 3 — HỒI PHỤC
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildRecoveryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cột mốc phục hồi cơ thể',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 6),
          Text(
            'Những thay đổi kỳ diệu của cơ thể khi bạn ngừng hút thuốc (Theo WHO).',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          _buildMilestonesTimeline(),
          const SizedBox(height: 32),
          Text('Lợi ích sức khỏe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          _buildBenefitsGrid(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMilestonesTimeline() {
    final milestones = [
      {'day': 1, 'title': 'Sau 20 phút – 12 giờ', 'desc': 'Nhịp tim và huyết áp giảm dần. Lượng carbon monoxide (CO) trong máu trở về mức bình thường.', 'icon': Icons.favorite},
      {'day': 2, 'title': 'Sau 2 – 3 ngày', 'desc': 'Nicotine hoàn toàn được loại bỏ khỏi cơ thể. Khứu giác và vị giác bắt đầu nhạy bén hơn.', 'icon': Icons.restaurant},
      {'day': 14, 'title': 'Sau 2 – 12 tuần', 'desc': 'Hệ tuần hoàn cải thiện đáng kể, chức năng phổi bắt đầu tăng cường, đi lại dễ dàng hơn.', 'icon': Icons.directions_walk},
      {'day': 30, 'title': 'Sau 1 – 9 tháng', 'desc': 'Tình trạng ho và khó thở giảm hẳn. Các nhung mao trong phổi bắt đầu hoạt động bình thường trở lại.', 'icon': Icons.air},
      {'day': 365, 'title': 'Sau 1 năm', 'desc': 'Nguy cơ mắc bệnh tim mạch vành giảm đi một nửa so với người tiếp tục hút thuốc.', 'icon': Icons.health_and_safety},
      {'day': 1825, 'title': 'Sau 5 năm', 'desc': 'Nguy cơ bị đột quỵ giảm xuống mức tương đương với người không bao giờ hút thuốc.', 'icon': Icons.monitor_heart},
      {'day': 3650, 'title': 'Sau 10 năm', 'desc': 'Nguy cơ tử vong do ung thư phổi giảm chỉ còn một nửa so với người vẫn tiếp tục hút.', 'icon': Icons.local_hospital},
    ];

    return Column(
      children: milestones.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        final achieved = _streak >= (m['day'] as int);
        final isLast = i == milestones.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: achieved ? AppColors.success.withValues(alpha: 0.15) : AppColors.divider.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: achieved ? AppColors.success : AppColors.divider, width: 2),
                    ),
                    child: Icon(m['icon'] as IconData, size: 18,
                        color: achieved ? AppColors.success : AppColors.textSecondary),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: achieved ? AppColors.success : AppColors.divider)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: achieved
                              ? AppColors.success.withValues(alpha: 0.5)
                              : AppColors.divider.withValues(alpha: 0.5)),
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(m['title'] as String,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: achieved ? AppColors.success : AppColors.textPrimary,
                                  )),
                            ),
                            if (achieved) const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(m['desc'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBenefitsGrid() {
    final benefits = [
      {'title': 'Khứu & Vị giác', 'icon': Icons.restaurant, 'desc': 'Ăn ngon miệng hơn'},
      {'title': 'Phổi & Hô hấp', 'icon': Icons.air, 'desc': 'Thở dễ dàng hơn'},
      {'title': 'Tim mạch', 'icon': Icons.favorite, 'desc': 'Huyết áp ổn định'},
      {'title': 'Năng lượng', 'icon': Icons.bolt, 'desc': 'Ít mệt mỏi hơn'},
      {'title': 'Làn da', 'icon': Icons.face_retouching_natural, 'desc': 'Tươi sáng, trẻ trung'},
      {'title': 'Tài chính', 'icon': Icons.savings, 'desc': 'Tiết kiệm đáng kể'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: benefits.map((b) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(b['icon'] as IconData, size: 26, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['title'] as String,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(b['desc'] as String,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
