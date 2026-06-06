import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/auth_provider.dart';
import '../routes/app_routes.dart';
import '../screens/my_appointments_screen.dart';

class HoSoScreen extends StatelessWidget {
  const HoSoScreen({super.key});

  bool _hasDeclaredProfile(Map<String, dynamic>? user) {
    final profile = user?['smokingProfile'];
    return profile != null && (profile['cigarettesPerDay'] ?? 0) > 0;
  }

  bool _hasPlan(Map<String, dynamic>? user) {
    final profile = user?['smokingProfile'];
    if (profile == null) return false;
    return profile['currentPlan'] != null || profile['activeQuitPlanId'] != null;
  }

  bool _hasPastPlans(Map<String, dynamic>? user) {
    final pastPlans = user?['smokingProfile']?['pastPlans'] as List?;
    return pastPlans != null && pastPlans.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final hasDeclared = _hasDeclaredProfile(user);
    final hasPlan = _hasPlan(user);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Hồ sơ'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(context, user),

            const SizedBox(height: 24),

            // ── Survey Card (shown once declared, read-only once has plan) ──
            if (hasDeclared) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSurveyCard(context, user, hasPlan),
              ),
              const SizedBox(height: 24),
            ],

            // ── Cài đặt ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cài đặt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (hasPlan)
                    _buildMenuItem(
                      context,
                      icon: Icons.assignment,
                      title: 'Kế hoạch của tôi',
                      subtitle: 'Xem chi tiết kế hoạch đang thực hiện',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.keHoachCuaToi),
                    ),
                  _buildMenuItem(
                    context,
                    icon: Icons.video_camera_front,
                    title: 'Lịch tư vấn Bác sĩ',
                    subtitle: 'Quản lý lịch hẹn Google Meet',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    onTap: () async {
                      final ap = Provider.of<AuthProvider>(context, listen: false);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      final success = await ap.fetchProfile();
                      if (context.mounted) Navigator.pop(context);
                      if (success && context.mounted) {
                        Navigator.pushNamed(context, AppRoutes.profileDetail);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ap.errorMessage ?? 'Lỗi khi lấy thông tin'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Về ứng dụng ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Về ứng dụng',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outlined,
                    title: 'Về QuitCare',
                    subtitle: 'Phiên bản 1.0.0',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Điều khoản & Điều kiện',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Chính sách bảo mật',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Lịch sử ─────────────────────────────────────────────────────
            if (_hasPastPlans(user)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch sử',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      title: 'Lịch sử hành trình',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.planHistory),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lightBlue, width: 3),
              ),
              child: const Icon(Icons.person, size: 60, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              user?['fullname'] ?? 'N/A',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?['email'] ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Survey data card ─────────────────────────────────────────────────────

  Widget _buildSurveyCard(
    BuildContext context,
    Map<String, dynamic>? user,
    bool isViewOnly,
  ) {
    final profile = user?['smokingProfile'] ?? {};
    final cigs = profile['cigarettesPerDay'] ?? 0;
    final years = profile['smokingYears'] ?? 0;
    final craving = profile['morningCravingLevel'] ?? '--';
    final reason = profile['quitReason'] ?? '--';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Khảo sát hút thuốc',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (!isViewOnly)
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.smokingStatus),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Chỉnh sửa',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Đã hoàn thành',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _surveyRow('🚬', 'Số điếu/ngày (ban đầu)', '$cigs điếu'),
          const SizedBox(height: 10),
          _surveyRow('📅', 'Số năm hút thuốc', '$years năm'),
          const SizedBox(height: 10),
          _surveyRow('🌅', 'Thèm thuốc buổi sáng', craving.toString()),
          const SizedBox(height: 10),
          _surveyRow('💡', 'Lý do cai thuốc', reason.toString()),
          if (isViewOnly) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.smokingStatus,
                arguments: {'isViewOnly': true},
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_outlined, color: AppColors.textSecondary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Xem chi tiết khảo sát',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 13),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _surveyRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── Menu item ─────────────────────────────────────────────────────────────

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}
