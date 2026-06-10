import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/auth_provider.dart';
import '../services/plan_service.dart';
import '../routes/app_routes.dart';

class _IntervalData {
  final TextEditingController weekRangeController;
  final TextEditingController cigarettesController;

  _IntervalData()
      : weekRangeController = TextEditingController(),
        cigarettesController = TextEditingController();

  void dispose() {
    weekRangeController.dispose();
    cigarettesController.dispose();
  }
}

class _StageData {
  final List<_IntervalData> intervals;

  _StageData() : intervals = [_IntervalData()];

  void dispose() {
    for (final i in intervals) {
      i.dispose();
    }
  }
}

class KeHoachTuTaoScreen extends StatefulWidget {
  const KeHoachTuTaoScreen({super.key});

  @override
  State<KeHoachTuTaoScreen> createState() => _KeHoachTuTaoScreenState();
}

class _KeHoachTuTaoScreenState extends State<KeHoachTuTaoScreen> {
  final PlanService _planService = PlanService();
  final List<_StageData> _stages = [_StageData()];
  bool _isSaving = false;

  @override
  void dispose() {
    for (final s in _stages) {
      s.dispose();
    }
    super.dispose();
  }

  void _addStage() {
    setState(() => _stages.add(_StageData()));
  }

  void _removeStage(int stageIdx) {
    if (_stages.length <= 1) return;
    setState(() {
      _stages[stageIdx].dispose();
      _stages.removeAt(stageIdx);
    });
  }

  void _addInterval(int stageIdx) {
    setState(() => _stages[stageIdx].intervals.add(_IntervalData()));
  }

  void _removeInterval(int stageIdx, int intervalIdx) {
    if (_stages[stageIdx].intervals.length <= 1) return;
    setState(() {
      _stages[stageIdx].intervals[intervalIdx].dispose();
      _stages[stageIdx].intervals.removeAt(intervalIdx);
    });
  }

  String? _validate() {
    for (int s = 0; s < _stages.length; s++) {
      for (int i = 0; i < _stages[s].intervals.length; i++) {
        final weekRange = _stages[s].intervals[i].weekRangeController.text.trim();
        final cigsText = _stages[s].intervals[i].cigarettesController.text.trim();

        if (weekRange.isEmpty) {
          return 'Giai đoạn ${s + 1}, khoảng ${i + 1}: Vui lòng nhập khoảng thời gian';
        }
        final weekNums = RegExp(r'\d+').allMatches(weekRange).toList();
        if (weekNums.isEmpty) {
          return 'Giai đoạn ${s + 1}, khoảng ${i + 1}: Khoảng thời gian phải chứa số tuần (vd: "Tuần 1" hoặc "Tuần 1-2")';
        }
        if (cigsText.isEmpty) {
          return 'Giai đoạn ${s + 1}, khoảng ${i + 1}: Vui lòng nhập số điếu';
        }
        final cigs = int.tryParse(cigsText);
        if (cigs == null || cigs < 0 || cigs > 50) {
          return 'Giai đoạn ${s + 1}, khoảng ${i + 1}: Số điếu phải từ 0 đến 50';
        }
      }
    }
    return null;
  }

  // Mirror backend getAddictionLevel logic
  String _computeAddictionLevel(int cigarettesPerDay) {
    if (cigarettesPerDay <= 10) return 'Thấp';
    if (cigarettesPerDay <= 20) return 'Trung bình';
    return 'Cao';
  }

  // Parse "Tuần 1", "Tuần 1-2", "Tuần 1 - 3", etc. → (startWeek, endWeek)
  (int, int) _parseWeekRange(String weekRange) {
    final nums = RegExp(r'\d+').allMatches(weekRange).map((m) => int.parse(m.group(0)!)).toList();
    if (nums.isEmpty) return (1, 1);
    if (nums.length == 1) return (nums[0], nums[0]);
    return (nums[0], nums[1]);
  }

  List<Map<String, dynamic>> _buildStages(DateTime overallStart) {
    final result = <Map<String, dynamic>>[];
    int stageNum = 1;
    for (int s = 0; s < _stages.length; s++) {
      for (int i = 0; i < _stages[s].intervals.length; i++) {
        final weekRange = _stages[s].intervals[i].weekRangeController.text.trim();
        final cigs = int.parse(_stages[s].intervals[i].cigarettesController.text.trim());
        final (startWeek, endWeek) = _parseWeekRange(weekRange);
        final stageStart = overallStart.add(Duration(days: (startWeek - 1) * 7));
        final stageEnd = overallStart.add(Duration(days: endWeek * 7 - 1));
        result.add({
          'stageName': 'Giai đoạn $stageNum',
          'weekRange': weekRange,
          'startDate': stageStart.toIso8601String(),
          'endDate': stageEnd.toIso8601String(),
          'cigarettesPerDay': cigs,
        });
        stageNum++;
      }
    }
    return result;
  }

  Future<void> _savePlan() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Read smoking profile to get addictionLevel and baseline cigarettes
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final smokingProfile = (authProvider.user?['smokingProfile'] as Map<String, dynamic>?) ?? {};
    final cigarettesPerDay = (smokingProfile['cigarettesPerDay'] as num?)?.toInt() ?? 0;
    final addictionLevel = _computeAddictionLevel(cigarettesPerDay);

    // Use quitDate from profile as start, fallback to today
    DateTime overallStart;
    final quitDateStr = smokingProfile['quitDate']?.toString();
    overallStart = quitDateStr != null
        ? (DateTime.tryParse(quitDateStr) ?? DateTime.now())
        : DateTime.now();
    overallStart = DateTime(overallStart.year, overallStart.month, overallStart.day);

    final stages = _buildStages(overallStart);

    // overallEndDate = last stage's endDate, not a hardcoded offset
    DateTime overallEnd = overallStart.add(const Duration(days: 140));
    if (stages.isNotEmpty) {
      final lastEndStr = stages.last['endDate'] as String?;
      if (lastEndStr != null) {
        overallEnd = DateTime.tryParse(lastEndStr) ?? overallEnd;
      }
    }

    final planData = {
      'type': 'custom',
      'stages': stages,
      'overallStartDate': overallStart.toIso8601String(),
      'overallEndDate': overallEnd.toIso8601String(),
      'addictionLevel': addictionLevel,
      'baselineCigarettes': cigarettesPerDay,
    };

    final result = await _planService.confirmPlan(planData);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).fetchProfile();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kế hoạch đã được lưu! Bắt đầu hành trình cai thuốc.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.tienTrinh, (route) => route.settings.name == AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Lưu kế hoạch thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
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
          'Bảng Tự Lập Kế Hoạch',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionCard(),
            const SizedBox(height: 20),
            ..._stages.asMap().entries.map((entry) => _buildStageCard(entry.key)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addStage,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Thêm giai đoạn', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePlan,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Đang lưu...' : 'Lưu kế hoạch',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Hướng dẫn tạo kế hoạch linh hoạt:',
                style: TextStyle(
                  color: Color(0xFF6B4EFF),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _bullet('Bạn có thể tạo nhiều giai đoạn (ví dụ: Giai đoạn 1, 2, 3...)'),
          _bullet('Mỗi giai đoạn có thể có nhiều khoảng thời gian khác nhau'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Định dạng khoảng thời gian hợp lệ:',
                  style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                _validFormat('✓ "Tuần 1 - 2", "Tuần 3-5", "Tuần 1"'),
                _validFormat('✓ "Tuần 1 đến 3", "Tuần 1 - Tuần 3"'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _bulletCheck('Có thể thêm/xóa giai đoạn và khoảng thời gian'),
          _bulletCheck('Có thể chỉnh sửa cả khoảng thời gian và số điếu thuốc'),
          _bulletCheck('Số điếu/ngày phải từ 1 đến 50 (0 = hoàn toàn cai)'),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _bulletCheck(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅ ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _validFormat(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontFamily: 'monospace'),
    );
  }

  Widget _buildStageCard(int stageIdx) {
    final stage = _stages[stageIdx];
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Stage header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${stageIdx + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Giai đoạn ${stageIdx + 1}',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (_stages.length > 1)
                  IconButton(
                    onPressed: () => _removeStage(stageIdx),
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Xóa giai đoạn',
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _addInterval(stageIdx),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm khoảng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Table header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withValues(alpha: 0.4),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Khoảng thời gian',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Số điếu mỗi ngày trong khoảng này',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // Interval rows
          ...stage.intervals.asMap().entries.map(
            (entry) => _buildIntervalRow(stageIdx, entry.key),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildIntervalRow(int stageIdx, int intervalIdx) {
    final interval = _stages[stageIdx].intervals[intervalIdx];
    final canRemove = _stages[stageIdx].intervals.length > 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: interval.weekRangeController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Tuần 1 - 2, Tuần 1',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: interval.cigarettesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0-50 điếu/ngày',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: canRemove
                ? IconButton(
                    onPressed: () => _removeInterval(stageIdx, intervalIdx),
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
