import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/auth_provider.dart';
import '../services/plan_service.dart';
import '../routes/app_routes.dart';

class KeHoachDeXuatScreen extends StatefulWidget {
  const KeHoachDeXuatScreen({super.key});

  @override
  State<KeHoachDeXuatScreen> createState() => _KeHoachDeXuatScreenState();
}

class _KeHoachDeXuatScreenState extends State<KeHoachDeXuatScreen> {
  final PlanService _planService = PlanService();

  bool _isLoading = true;
  bool _isConfirming = false;
  Map<String, dynamic>? _planData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final result = await _planService.generateSuggestedPlan();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _planData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Không thể tải kế hoạch đề xuất';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmPlan() async {
    if (_planData == null) return;
    setState(() => _isConfirming = true);

    final result = await _planService.confirmPlan(_planData!);
    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (result['success'] == true) {
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).fetchProfile();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kế hoạch đã được xác nhận! Bắt đầu hành trình cai thuốc.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.tienTrinh, (route) => route.settings.name == AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Xác nhận kế hoạch thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '--';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Color _addictionColor(String level) {
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
          'Kế hoạch được đề xuất',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _isLoading = true; _errorMessage = null; });
                _loadPlan();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final plan = _planData!;
    final stages = (plan['stages'] as List?) ?? [];
    final addictionLevel = plan['addictionLevel'] ?? 'Trung bình';
    final baselineCigarettes = plan['baselineCigarettes'] ?? 0;
    final overallStartDate = _formatDate(plan['overallStartDate']);
    final overallEndDate = _formatDate(plan['overallEndDate']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge
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
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kế hoạch cai thuốc được đề xuất',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
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
                _summaryRow(
                  emoji: '🧠',
                  label: 'Mức độ nghiện hệ thống đánh giá:',
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
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 20),
                _summaryRow(
                  emoji: '🚬',
                  label: 'Trung bình số điếu hút mỗi ngày:',
                  value: '$baselineCigarettes',
                ),
                const Divider(height: 20),
                _summaryRow(
                  emoji: '📅',
                  label: 'Ngày bắt đầu dự kiến:',
                  value: overallStartDate,
                ),
                const Divider(height: 20),
                _summaryRow(
                  emoji: '🏁',
                  label: 'Ngày kết thúc dự kiến:',
                  value: overallEndDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stages table
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
                // Table rows
                ...stages.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stage = entry.value as Map<String, dynamic>;
                  final isLast = i == stages.length - 1;
                  final isEven = i % 2 == 0;
                  return _stageRow(stage, isEven: isEven, isLast: isLast, isLastStage: isLast);
                }),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Confirmation section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                const Text('🤔', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 10),
                Text(
                  'Bạn có chắc chắn xác nhận kế hoạch này không?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nếu đồng ý, kế hoạch sẽ được lưu và bạn có thể bắt đầu theo dõi tiến trình cai thuốc. Nếu không, bạn có thể tự lập kế hoạch khác.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isConfirming ? null : _confirmPlan,
                    icon: _isConfirming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _isConfirming ? 'Đang xác nhận...' : 'Xác nhận kế hoạch này',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isConfirming
                        ? null
                        : () => Navigator.pushReplacementNamed(context, AppRoutes.keHoachTuTao),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text(
                      'Tự lập kế hoạch khác',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B4EFF),
                      side: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
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
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        valueWidget ??
            Text(
              value ?? '--',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
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
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _stageRow(Map<String, dynamic> stage, {bool isEven = true, bool isLast = false, bool isLastStage = false}) {
    final cigs = stage['cigarettesPerDay'] as int? ?? 0;
    final isQuit = cigs == 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFFDFDFD) : Colors.white,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : null,
        border: isLast ? null : Border(bottom: BorderSide(color: const Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              stage['stageName'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              stage['weekRange'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(stage['startDate']),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(stage['endDate']),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isQuit ? 'Hoàn toàn cai' : '$cigs điếu',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isQuit ? const Color(0xFF10B981) : const Color(0xFF6B4EFF),
                fontWeight: FontWeight.w800,
                fontSize: isQuit ? 11 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
