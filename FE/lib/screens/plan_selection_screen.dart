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
  Map<String, dynamic>? _recommendedPlan;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    final result = await _planService.getRecommendedPlan();
    if (result['success'] && mounted) {
      setState(() {
        _recommendedPlan = result['recommendedPlan'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi tải kế hoạch'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chọn Hướng Đi'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lựa chọn kế hoạch cai thuốc',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dựa vào thông tin bạn cung cấp, hệ thống đã phân tích và đưa ra đề xuất tốt nhất. Tuy nhiên, quyền quyết định là ở bạn.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recommended Plan
                  if (_recommendedPlan != null)
                    _buildOptionCard(
                      context,
                      title: 'Kế hoạch Đề xuất từ Chuyên gia',
                      description: 'Phù hợp nhất với mức độ phụ thuộc và thói quen hút thuốc của bạn.',
                      isRecommended: true,
                      onTap: () {
                        Navigator.pushNamed(
                          context, 
                          AppRoutes.planDetail, 
                          arguments: {
                            'plan': _recommendedPlan,
                            'isViewOnly': false,
                          },
                        );
                      },
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Custom Plan
                  _buildOptionCard(
                    context,
                    title: 'Tự tạo Kế hoạch của riêng tôi',
                    description: 'Tự do thiết lập mục tiêu, thời gian và lộ trình cai thuốc.',
                    isRecommended: false,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng tự tạo kế hoạch đang được phát triển.')),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? AppColors.warning : AppColors.divider,
            width: isRecommended ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isRecommended ? AppColors.warning.withValues(alpha: 0.15) : AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    const Text('Phù hợp nhất', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isRecommended ? AppColors.primaryBlue : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
