import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/plan_service.dart';
import '../services/progress_service.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final _progressService = ProgressService();
  final _planService = PlanService();

  // loading states
  bool _isLoadingInitial = true;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  // plan & today's existing log
  int? _todayTarget;
  Map<String, dynamic>? _existingLog;

  // form values
  double _cigarettesSmoked = 0;
  String _cravingLevel = 'Không thèm';
  String _mood = 'Bình thường';
  final List<String> _availableSymptoms = ['Ho', 'Đau đầu', 'Khó ngủ', 'Căng thẳng', 'Thèm ăn', 'Chóng mặt'];
  final List<String> _selectedSymptoms = [];
  final TextEditingController _noteController = TextEditingController();

  // ── computed ──────────────────────────────────────────────────────────────

  bool get _isEditMode => _existingLog != null;

  bool get _isLocked {
    if (_existingLog == null) return false;
    final now = DateTime.now();
    return now.hour >= 21;
  }

  bool get _canEditUntilInfo {
    final now = DateTime.now();
    return now.hour < 21;
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadTodayTarget(), _loadExistingCheckin()]);
    if (mounted) setState(() => _isLoadingInitial = false);
  }

  Future<void> _loadTodayTarget() async {
    final result = await _planService.getCurrentQuitPlan();
    if (!mounted || result['success'] != true) return;
    final stage = result['data']?['currentStage'] as Map<String, dynamic>?;
    if (mounted) setState(() => _todayTarget = stage?['cigarettesPerDay'] as int?);
  }

  Future<void> _loadExistingCheckin() async {
    final result = await _progressService.getHistory();
    if (!mounted || result['success'] != true) return;

    final logs = (result['data'] as List? ?? []).cast<Map<String, dynamic>>();
    final todayKey = _dateKey(DateTime.now());

    for (final log in logs) {
      final dt = DateTime.tryParse(log['date']?.toString() ?? '');
      if (dt != null && _dateKey(dt) == todayKey) {
        if (mounted) {
          setState(() {
            _existingLog = log;
            _cigarettesSmoked = ((log['cigarettesSmoked'] as int?) ?? 0).toDouble();
            _cravingLevel = log['cravingLevel'] as String? ?? 'Không thèm';
            _mood = log['mood'] as String? ?? 'Bình thường';
            final syms = (log['symptoms'] as List?)?.cast<String>() ?? [];
            _selectedSymptoms
              ..clear()
              ..addAll(syms);
            _noteController.text = log['note'] as String? ?? '';
          });
        }
        break;
      }
    }
  }

  Future<void> _submitCheckin() async {
    setState(() => _isSubmitting = true);
    final result = await _progressService.checkIn(
      cigarettesSmoked: _cigarettesSmoked.toInt(),
      cravingLevel: _cravingLevel,
      mood: _mood,
      symptoms: _selectedSymptoms,
      note: _noteController.text,
    );
    setState(() => _isSubmitting = false);

    if (result['success'] == true && mounted) {
      setState(() => _showSuccess = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Có lỗi xảy ra'),
          backgroundColor: const Color(0xFFF43F5E),
        ),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _viWeekday(int w) {
    const n = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return n[w.clamp(1, 7)];
  }

  String _moodEmoji(String m) {
    if (m == 'Tốt') return '😊';
    if (m == 'Tệ') return '😔';
    return '😐';
  }

  String _cravingEmoji(String c) {
    if (c == 'Không thèm') return '💪';
    if (c == 'Thèm nhiều') return '😰';
    return '😤';
  }

  String get _todayDateStr {
    final now = DateTime.now();
    return '${_viWeekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF6B4EFF)),
                      SizedBox(height: 16),
                      Text('Đang tải dữ liệu...',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: _showSuccess
            ? _buildSuccessView()
            : _isLocked
                ? _buildLockedView()
                : _buildFormView(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOCKED VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLockedView() {
    final log = _existingLog!;
    final smoked = log['cigarettesSmoked'] as int? ?? 0;
    final mood = log['mood'] as String? ?? '';
    final craving = log['cravingLevel'] as String? ?? '';
    final symptoms = (log['symptoms'] as List?)?.cast<String>() ?? [];
    final note = log['note'] as String? ?? '';
    final withinTarget = _todayTarget != null && smoked <= _todayTarget!;
    final Color smokedColor = smoked == 0
        ? const Color(0xFF10B981)
        : (withinTarget ? const Color(0xFF6B4EFF) : const Color(0xFFF43F5E));

    return SafeArea(
      key: const ValueKey('locked'),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 24, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                    child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1E293B), size: 20),
                  ),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ghi nhận hôm nay',
                          style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.lock_rounded, size: 12, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text('Đã khóa lúc 21:00',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // lock banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ghi nhận đã bị khóa sau 21:00. Bạn không thể chỉnh sửa nhật ký ngày hôm nay nữa.',
                    style: TextStyle(
                        color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                children: [
                  // date card
                  _lockedCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(CupertinoIcons.calendar, color: Color(0xFF6B4EFF), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ngày ghi nhận',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(_todayDateStr,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // cigarettes
                  _lockedCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: smokedColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$smoked',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w900, color: smokedColor)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Số điếu đã hút',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text('$smoked điếu',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w800, color: smokedColor)),
                              if (_todayTarget != null)
                                Text(
                                  smoked == 0
                                      ? '🏆 Không hút điếu nào!'
                                      : (withinTarget
                                          ? '✅ Đạt mục tiêu ≤$_todayTarget điếu'
                                          : '⚠️ Vượt mục tiêu ${smoked - _todayTarget!} điếu'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: withinTarget || smoked == 0
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF43F5E),
                                      fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // mood & craving row
                  Row(
                    children: [
                      Expanded(
                        child: _lockedCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tâm trạng',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Text(_moodEmoji(mood), style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(mood.isNotEmpty ? mood : '--',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _lockedCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mức thèm',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Text(_cravingEmoji(craving), style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(craving.isNotEmpty ? craving : '--',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // symptoms
                  if (symptoms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _lockedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(CupertinoIcons.thermometer, size: 14, color: Color(0xFF6B4EFF)),
                            SizedBox(width: 8),
                            Text('Triệu chứng',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          ]),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: symptoms
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6B4EFF).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: const Color(0xFF6B4EFF).withValues(alpha: 0.25)),
                                      ),
                                      child: Text(s,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B4EFF),
                                              fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // note
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _lockedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(CupertinoIcons.quote_bubble, size: 14, color: Color(0xFF6B4EFF)),
                            SizedBox(width: 8),
                            Text('Ghi chú',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          ]),
                          const SizedBox(height: 10),
                          Text('"$note"',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                  fontStyle: FontStyle.italic,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Đóng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: child,
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  SUCCESS VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSuccessView() {
    final smoked = _cigarettesSmoked.toInt();
    final withinTarget = _todayTarget != null && smoked <= _todayTarget!;
    final exceeded = _todayTarget != null && smoked > _todayTarget!;

    return SafeArea(
      key: const ValueKey('success'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _circleBtn(icon: CupertinoIcons.xmark, onTap: () => Navigator.pop(context, true)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.tienTrinh, (r) => r.isFirst),
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: const Text('Tiến trình'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B4EFF)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isEditMode ? 'Đã cập nhật! ✏️' : 'Tuyệt vời! 🎉',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isEditMode
                        ? 'Ghi nhận hôm nay đã được cập nhật'
                        : 'Bạn đã hoàn thành ghi nhận hôm nay',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                    child: Text(_todayDateStr,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _successStatTile(emoji: '🚬', label: 'Số điếu', value: '$smoked điếu',
                          color: smoked == 0 ? const Color(0xFF10B981) : (withinTarget ? const Color(0xFF6B4EFF) : const Color(0xFFF43F5E))),
                      const SizedBox(width: 10),
                      _successStatTile(emoji: _moodEmoji(_mood), label: 'Tâm trạng', value: _mood, color: const Color(0xFF6B4EFF)),
                      const SizedBox(width: 10),
                      _successStatTile(emoji: _cravingEmoji(_cravingLevel), label: 'Mức thèm',
                          value: _cravingLevel == 'Không thèm' ? 'Không' : _cravingLevel, color: const Color(0xFF0EA5E9)),
                    ],
                  ),

                  if (_todayTarget != null) ...[const SizedBox(height: 16), _buildTargetCard(smoked, withinTarget, exceeded)],
                  if (_selectedSymptoms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _summarySectionCard(
                      icon: CupertinoIcons.thermometer,
                      title: 'Triệu chứng',
                      child: Wrap(spacing: 8, runSpacing: 6,
                          children: _selectedSymptoms.map((s) => _chip(s, const Color(0xFF6B4EFF))).toList()),
                    ),
                  ],
                  if (_noteController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _summarySectionCard(
                      icon: CupertinoIcons.quote_bubble,
                      title: 'Ghi chú',
                      child: Text('"${_noteController.text.trim()}"',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontStyle: FontStyle.italic, height: 1.5)),
                    ),
                  ],

                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.tienTrinh, (r) => r.isFirst),
                      icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                      label: const Text('Xem tiến trình', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Về trang trước', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FORM VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFormView() {
    return SafeArea(
      key: const ValueKey('form'),
      bottom: false,
      child: Column(
        children: [
          _buildHeader(),
          // edit mode banner (before 9PM)
          if (_isEditMode && _canEditUntilInfo) _buildEditBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCigarettesCard(),
                  const SizedBox(height: 24),
                  _buildSegmentCard(
                    title: 'Mức độ thèm thuốc',
                    icon: CupertinoIcons.flame,
                    options: ['Không thèm', 'Thèm nhẹ', 'Thèm nhiều'],
                    selectedValue: _cravingLevel,
                    onChanged: (v) => setState(() => _cravingLevel = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSegmentCard(
                    title: 'Tâm trạng',
                    icon: CupertinoIcons.smiley,
                    options: ['Tốt', 'Bình thường', 'Tệ'],
                    selectedValue: _mood,
                    onChanged: (v) => setState(() => _mood = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSymptomsCard(),
                  const SizedBox(height: 24),
                  _buildNoteCard(),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1E293B), size: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isEditMode ? 'Sửa ghi nhận' : 'Ghi nhận hôm nay',
                      style: const TextStyle(
                          color: Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Chỉnh sửa',
                            style: TextStyle(fontSize: 10, color: Color(0xFF6B4EFF), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditMode ? 'Cập nhật ghi nhận trước 21:00' : 'Hãy trung thực với bản thân nhé!',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditBanner() {
    final now = DateTime.now();
    final remaining = 21 - now.hour;
    final minutesLeft = remaining == 1 ? '${60 - now.minute} phút nữa' : '$remaining giờ nữa';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bạn có thể sửa ghi nhận trong $minutesLeft. Sau 21:00 sẽ bị khóa.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── shared form widgets ───────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: child,
      );

  Widget _buildCigarettesCard() {
    final smoked = _cigarettesSmoked.toInt();
    final isZero = smoked == 0;
    final withinTarget = _todayTarget != null && smoked <= _todayTarget!;
    final Color activeColor = isZero
        ? const Color(0xFF10B981)
        : (withinTarget ? const Color(0xFF6B4EFF) : const Color(0xFFF43F5E));

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(CupertinoIcons.smoke, color: Color(0xFF6B4EFF), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Số điếu đã hút hôm nay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ),
              if (_todayTarget != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _todayTarget == 0 ? 'Mục tiêu: 0' : '≤$_todayTarget điếu',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B4EFF)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(smoked.toString(),
                style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: activeColor)),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              inactiveTrackColor: const Color(0xFFF1F5F9),
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: _cigarettesSmoked,
              min: 0,
              max: 50,
              divisions: 50,
              onChanged: (v) => setState(() => _cigarettesSmoked = v),
            ),
          ),
          if (isZero)
            _statusBanner(const Color(0xFF10B981), CupertinoIcons.star_fill, 'Tuyệt vời! Bạn đang giữ vững phong độ.')
          else if (_todayTarget != null && smoked <= _todayTarget!)
            _statusBanner(const Color(0xFF6B4EFF), CupertinoIcons.checkmark_seal_fill, 'Trong mục tiêu kế hoạch. Tiếp tục cố lên!')
          else if (_todayTarget != null)
            _statusBanner(const Color(0xFFF43F5E), CupertinoIcons.exclamationmark_circle_fill,
                'Vượt mục tiêu ${smoked - _todayTarget!} điếu. Cố gắng hơn ngày mai!'),
        ],
      ),
    );
  }

  Widget _statusBanner(Color color, IconData icon, String text) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _buildSegmentCard({
    required String title,
    required IconData icon,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF6B4EFF), size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          ]),
          const SizedBox(height: 20),
          Row(
            children: options.map((opt) {
              final sel = selectedValue == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF6B4EFF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sel ? const Color(0xFF6B4EFF) : const Color(0xFFE2E8F0)),
                      boxShadow: sel
                          ? [BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(opt,
                        style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF64748B),
                            fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(CupertinoIcons.thermometer, color: Color(0xFF6B4EFF), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Triệu chứng (nếu có)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          ]),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableSymptoms.map((symptom) {
              final sel = _selectedSymptoms.contains(symptom);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _selectedSymptoms.remove(symptom);
                    } else {
                      _selectedSymptoms.add(symptom);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF6B4EFF).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? const Color(0xFF6B4EFF) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(symptom,
                      style: TextStyle(
                          color: sel ? const Color(0xFF6B4EFF) : const Color(0xFF64748B),
                          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(CupertinoIcons.pencil, color: Color(0xFF6B4EFF), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Ghi chú thêm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhật ký của bạn...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitCheckin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4EFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                _isEditMode ? 'Cập nhật ghi nhận' : 'Lưu nhật ký',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ── shared success widgets ────────────────────────────────────────────────

  Widget _successStatTile({required String emoji, required String label, required String value, required Color color}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );

  Widget _buildTargetCard(int smoked, bool withinTarget, bool exceeded) {
    final target = _todayTarget!;
    final color = smoked == 0 ? const Color(0xFF10B981) : (withinTarget ? const Color(0xFF6B4EFF) : const Color(0xFFF43F5E));
    final progress = target == 0 ? (smoked == 0 ? 1.0 : 0.0) : (smoked / target).clamp(0.0, 1.0);
    final label = smoked == 0
        ? '🏆 Hoàn hảo! Không hút điếu nào!'
        : (withinTarget ? '✅ Đạt mục tiêu kế hoạch hôm nay' : '⚠️ Vượt mục tiêu ${smoked - target} điếu hôm nay');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mục tiêu kế hoạch', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
              Text(target == 0 ? '0 điếu' : '≤$target điếu', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _summarySectionCard({required IconData icon, required String title, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 15, color: const Color(0xFF6B4EFF)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF1E293B), size: 18),
        ),
      );
}
