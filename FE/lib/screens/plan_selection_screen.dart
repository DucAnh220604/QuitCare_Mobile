import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/plan_service.dart';
import '../routes/app_routes.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final PlanService _planService = PlanService();

  bool _isLoading = true;
  Map<String, dynamic>? _suggestedPlan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuggestedPlan();
  }

  Future<void> _fetchSuggestedPlan() async {
    final result = await _planService.generateSuggestedPlan();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _suggestedPlan = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
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

  IconData _addictionIcon(String level) {
    switch (level) {
      case 'Thấp':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'Trung bình':
        return Icons.sentiment_neutral_rounded;
      default:
        return Icons.sentiment_very_dissatisfied_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text(
          'Chọn Kế Hoạch Cai Thuốc',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page header
                  Text(
                    'Lựa chọn hướng đi phù hợp',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hệ thống đã phân tích hồ sơ của bạn và tạo kế hoạch phù hợp nhất. Quyền quyết định cuối cùng là ở bạn.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Option 1: Expert Suggested Plan ──
                  _buildSuggestedPlanCard(context),

                  const SizedBox(height: 16),

                  // Divider with "or"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'hoặc',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Option 2: Custom Plan ──
                  _buildCustomPlanCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildSuggestedPlanCard(BuildContext context) {
    final plan = _suggestedPlan;
    final hasData = plan != null && _errorMessage == null;
    final addictionLevel = plan?['addictionLevel'] ?? 'Trung bình';
    final baselineCigs = plan?['baselineCigarettes'] ?? 0;
    final stages = (plan?['stages'] as List?) ?? [];
    final startDate = _formatDate(plan?['overallStartDate']);
    final endDate = _formatDate(plan?['overallEndDate']);
    final durationWeeks = stages.length * 4;

    return GestureDetector(
      onTap: hasData ? () => Navigator.pushNamed(context, AppRoutes.keHoachDeXuat) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6B4EFF), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4EFF).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B4EFF).withValues(alpha: 0.15),
                    const Color(0xFF6B4EFF).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Phù hợp nhất',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Được tạo từ hồ sơ của bạn',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: Color(0xFF6B4EFF), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Kế hoạch Đề xuất từ Chuyên gia',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (!hasData) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage ?? 'Vui lòng hoàn thành khai báo hồ sơ để xem kế hoạch đề xuất.',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),

                    // Stats row
                    Row(
                      children: [
                        _statChip(
                          icon: _addictionIcon(addictionLevel),
                          iconColor: _addictionColor(addictionLevel),
                          label: 'Mức nghiện',
                          value: addictionLevel,
                          valueColor: _addictionColor(addictionLevel),
                        ),
                        const SizedBox(width: 8),
                        _statChip(
                          icon: Icons.smoking_rooms_rounded,
                          iconColor: AppColors.textSecondary,
                          label: 'Điếu/ngày',
                          value: '$baselineCigs điếu',
                          valueColor: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        _statChip(
                          icon: Icons.calendar_month_rounded,
                          iconColor: AppColors.primaryBlue,
                          label: 'Thời gian',
                          value: '$durationWeeks tuần',
                          valueColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Mini stage preview
                    Text(
                      'Lộ trình giảm dần',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMiniStages(stages),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Date range
                    Row(
                      children: [
                        const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Text(
                          '$startDate  →  $endDate',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B4EFF), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Text(
                            'Xem chi tiết →',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStages(List<dynamic> stages) {
    return Row(
      children: stages.asMap().entries.map((entry) {
        final i = entry.key;
        final stage = entry.value as Map<String, dynamic>;
        final cigs = stage['cigarettesPerDay'] as int? ?? 0;
        final isQuit = cigs == 0;
        final isLast = i == stages.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isQuit
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isQuit ? '0' : '$cigs',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isQuit ? const Color(0xFF10B981) : const Color(0xFF6B4EFF),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'GĐ ${i + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomPlanCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.keHoachTuTao),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF7C3AED), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tự tạo Kế hoạch của riêng tôi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tự thiết lập giai đoạn, khoảng thời gian và số điếu theo ý muốn.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      _tag(Icons.tune_rounded, 'Linh hoạt'),
                      _tag(Icons.add_box_outlined, 'Nhiều giai đoạn'),
                      _tag(Icons.lock_open_rounded, 'Tự quyết'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
