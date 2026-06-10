import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/plan_service.dart';

class KeHoachCuaToiScreen extends StatefulWidget {
  const KeHoachCuaToiScreen({super.key});

  @override
  State<KeHoachCuaToiScreen> createState() => _KeHoachCuaToiScreenState();
}

class _KeHoachCuaToiScreenState extends State<KeHoachCuaToiScreen> {
  final PlanService _planService = PlanService();

  bool _isLoading = true;
  Map<String, dynamic>? _quitPlan;
  Map<String, dynamic>? _predefinedPlan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    // Try to load personalized QuitPlan (staged) first
    final quitResult = await _planService.getCurrentQuitPlan();
    if (quitResult['success'] == true) {
      setState(() {
        _quitPlan = quitResult['data'];
        _isLoading = false;
      });
      return;
    }

    // Fallback: predefined plan (Cold Turkey / NRT / Tapering)
    final planResult = await _planService.getMyPlan();
    if (planResult['success'] == true) {
      setState(() {
        _predefinedPlan = planResult['plan'];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = 'Bạn chưa có kế hoạch cai thuốc nào. Hãy chọn hoặc tạo kế hoạch từ trang chủ.';
      _isLoading = false;
    });
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '--';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  bool _isCurrentStage(Map<String, dynamic> stage) {
    final now = DateTime.now();
    final start = DateTime.tryParse(stage['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(stage['endDate']?.toString() ?? '');
    if (start == null || end == null) return false;
    return now.isAfter(start.subtract(const Duration(seconds: 1))) &&
        now.isBefore(end.add(const Duration(days: 1)));
  }

  Color _addictionColor(String? level) {
    switch (level) {
      case 'Thấp':
        return AppColors.success;
      case 'Trung bình':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Kế hoạch của tôi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _errorMessage != null
              ? _buildEmpty()
              : _quitPlan != null
                  ? _buildQuitPlan()
                  : _buildPredefinedPlan(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 72, color: AppColors.mediumGrey),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Personalized QuitPlan (staged) ──────────────────────────────────────────

  Widget _buildQuitPlan() {
    final plan = _quitPlan!;
    final stages = (plan['stages'] as List?) ?? [];
    final type = plan['type'] as String? ?? 'suggested';
    final addictionLevel = plan['addictionLevel'] as String?;
    final baselineCigarettes = plan['baselineCigarettes'] as int? ?? 0;

    // Find current stage index
    int currentIdx = -1;
    for (int i = 0; i < stages.length; i++) {
      if (_isCurrentStage(stages[i] as Map<String, dynamic>)) {
        currentIdx = i;
        break;
      }
    }

    final overallDays = _calcOverallDays(plan);
    final elapsedDays = _calcElapsedDays(plan);
    final overallProgress = overallDays > 0 ? (elapsedDays / overallDays).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: type == 'suggested'
                    ? [const Color(0xFF6B4EFF), const Color(0xFFA855F7)]
                    : [const Color(0xFF10B981), const Color(0xFF34D399)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (type == 'suggested' ? const Color(0xFF6B4EFF) : const Color(0xFF10B981)).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(
                  type == 'suggested' ? Icons.auto_awesome : Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  type == 'suggested' ? 'Kế hoạch được đề xuất' : 'Kế hoạch tự lập',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (addictionLevel != null) ...[
                  _summaryRow(
                    emoji: '🧠',
                    label: 'Mức độ nghiện:',
                    valueWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _addictionColor(addictionLevel).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        addictionLevel,
                        style: TextStyle(
                          color: _addictionColor(addictionLevel),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  _summaryRow(emoji: '🚬', label: 'Số điếu ban đầu/ngày:', value: '$baselineCigarettes'),
                  const Divider(height: 20),
                ],
                _summaryRow(
                  emoji: '📅',
                  label: 'Ngày bắt đầu:',
                  value: _formatDate(plan['overallStartDate']),
                ),
                const Divider(height: 20),
                _summaryRow(
                  emoji: '🏁',
                  label: 'Ngày kết thúc dự kiến:',
                  value: _formatDate(plan['overallEndDate']),
                ),
                const Divider(height: 20),
                _summaryRow(
                  emoji: '📊',
                  label: 'Tổng thời gian:',
                  value: '$overallDays ngày',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overall progress bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ tổng thể',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(overallProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày $elapsedDays / $overallDays',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stages table
          Text(
            'Các giai đoạn',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      _headerCell('Giai đoạn', flex: 2),
                      _headerCell('Thời gian', flex: 2),
                      _headerCell('Ngày BĐ', flex: 2),
                      _headerCell('Ngày KT', flex: 2),
                      _headerCell('Điếu/ngày', flex: 2, isLast: true),
                    ],
                  ),
                ),
                // Rows
                ...stages.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stage = entry.value as Map<String, dynamic>;
                  final isCurrent = (i == currentIdx);
                  final isLast = i == stages.length - 1;
                  return _stageRow(stage, isCurrent: isCurrent, isEven: i % 2 == 0, isLast: isLast);
                }),
              ],
            ),
          ),

          if (currentIdx >= 0) ...[
            const SizedBox(height: 20),
            _buildCurrentStageCard(stages[currentIdx] as Map<String, dynamic>, currentIdx, stages.length),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCurrentStageCard(Map<String, dynamic> stage, int idx, int total) {
    final cigs = stage['cigarettesPerDay'] as int? ?? 0;
    final isQuit = cigs == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isQuit
              ? [const Color(0xFF10B981), const Color(0xFF34D399)]
              : [const Color(0xFF6B4EFF), const Color(0xFFA855F7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isQuit ? const Color(0xFF10B981) : const Color(0xFF6B4EFF)).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'Giai đoạn hiện tại (${idx + 1}/$total)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stage['stageName'] ?? 'Giai đoạn ${idx + 1}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            isQuit ? '🎯 Mục tiêu: Hoàn toàn cai thuốc' : '🎯 Mục tiêu: $cigs điếu/ngày',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '📅 ${_formatDate(stage['startDate'])} → ${_formatDate(stage['endDate'])}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Predefined plan (Cold Turkey / NRT / Tapering) ─────────────────────────

  Widget _buildPredefinedPlan() {
    final plan = _predefinedPlan!;
    final tasks = (plan['dailyTasks'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4EFF), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Kế hoạch đã chọn',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Plan card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan['description'] ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _chip(
                      label: 'Độ khó: ${plan['difficulty'] ?? '--'}',
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      label: '${plan['durationDays'] ?? '--'} ngày',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (tasks.isNotEmpty) ...[
            Text(
              'Nhiệm vụ hằng ngày',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: tasks.asMap().entries.map((entry) {
                  final i = entry.key;
                  final task = entry.value as String;
                  final isLast = i == tasks.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Color(0xFF6B4EFF),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            task,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  int _calcOverallDays(Map<String, dynamic> plan) {
    final start = DateTime.tryParse(plan['overallStartDate']?.toString() ?? '');
    final end = DateTime.tryParse(plan['overallEndDate']?.toString() ?? '');
    if (start == null || end == null) return 0;
    return end.difference(start).inDays.abs();
  }

  int _calcElapsedDays(Map<String, dynamic> plan) {
    final start = DateTime.tryParse(plan['overallStartDate']?.toString() ?? '');
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays.clamp(0, _calcOverallDays(plan));
  }

  Widget _summaryRow({
    required String emoji,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ),
        const SizedBox(width: 8),
        valueWidget ??
            Text(
              value ?? '--',
              style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 14),
            ),
      ],
    );
  }

  Widget _headerCell(String text, {int flex = 2, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: isLast ? TextAlign.right : TextAlign.center,
        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _stageRow(
    Map<String, dynamic> stage, {
    bool isCurrent = false,
    bool isEven = true,
    bool isLast = false,
  }) {
    final cigs = stage['cigarettesPerDay'] as int? ?? 0;
    final isQuit = cigs == 0;
    Color bgColor = isCurrent
        ? const Color(0xFFF3F0FF)
        : (isEven ? const Color(0xFFFDFDFD) : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : null,
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrent)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.location_on, color: AppColors.primaryBlue, size: 14),
                  ),
                Flexible(
                  child: Text(
                    stage['stageName'] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isCurrent ? const Color(0xFF6B4EFF) : const Color(0xFF1E293B),
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              stage['weekRange'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(stage['startDate']),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(stage['endDate']),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isQuit ? 'Cai hoàn toàn' : '$cigs điếu',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isQuit ? const Color(0xFF10B981) : const Color(0xFF6B4EFF),
                fontWeight: FontWeight.w800,
                fontSize: isQuit ? 10 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
