import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../routes/app_routes.dart';
import '../screens/my_appointments_screen.dart';
import '../screens/about_quitcare_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../screens/privacy_policy_screen.dart';

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
      backgroundColor: const Color(0xFFFDFDFD),
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE8E2FA),
                image: DecorationImage(
                  image: AssetImage('assets/images/profile_header_landscape.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context, user),
                  const SizedBox(height: 24),
                  if (hasDeclared) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildSurveyCard(context, user, hasPlan),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildSettingsGroup(context, hasPlan),
                  const SizedBox(height: 24),
                  _buildAboutGroup(context),
                  const SizedBox(height: 24),
                  if (_hasPastPlans(user)) ...[
                    _buildHistoryGroup(context),
                    const SizedBox(height: 40),
                  ],
                  _buildLogoutButton(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? user) {
    final canPop = Navigator.canPop(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 24, 8),
          child: Row(
            children: [
              if (canPop)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1E293B), size: 20),
                  ),
                )
              else
                const SizedBox(width: 16),
              const Text(
                'Hồ sơ',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(user?['fullname']),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF6B4EFF),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['fullname'] ?? 'Người dùng',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?['email'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildSurveyCard(BuildContext context, Map<String, dynamic>? user, bool isViewOnly) {
    final profile = user?['smokingProfile'] ?? {};
    final cigs = profile['cigarettesPerDay'] ?? 0;
    final years = profile['smokingYears'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.heart_solid, color: Color(0xFFF43F5E), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tình trạng hiện tại',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (!isViewOnly)
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.smokingStatus),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Cập nhật', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _surveyMetricCard('Số điếu/ngày', '$cigs', CupertinoIcons.flame)),
              const SizedBox(width: 12),
              Expanded(child: _surveyMetricCard('Số năm', '$years', CupertinoIcons.calendar)),
            ],
          ),
          if (isViewOnly) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.smokingStatus, arguments: {'isViewOnly': true}),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('Xem chi tiết khảo sát', style: TextStyle(color: Color(0xFF6B4EFF), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _surveyMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, bool hasPlan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cài đặt & Tiện ích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                if (hasPlan)
                  _buildMenuItem(
                    context,
                    icon: CupertinoIcons.doc_text,
                    title: 'Kế hoạch của tôi',
                    subtitle: 'Xem tiến trình kế hoạch',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.keHoachCuaToi),
                  ),
                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.calendar_badge_plus,
                  title: 'Lịch hẹn Bác sĩ',
                  subtitle: 'Tư vấn trực tuyến qua Google Meet',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
                ),
                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.person_crop_circle,
                  title: 'Thông tin cá nhân',
                  subtitle: 'Đổi tên, mật khẩu',
                  showBorder: false,
                  onTap: () async {
                    final ap = Provider.of<AuthProvider>(context, listen: false);
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                    final success = await ap.fetchProfile();
                    if (context.mounted) Navigator.pop(context);
                    if (success && context.mounted) {
                      Navigator.pushNamed(context, AppRoutes.profileDetail);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutGroup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Về ứng dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.info_circle,
                  title: 'Về QuitCare',
                  subtitle: 'Phiên bản 1.0.0',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutQuitCareScreen())),
                ),
                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.doc_plaintext,
                  title: 'Điều khoản sử dụng',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfUseScreen())),
                ),
                _buildMenuItem(
                  context,
                  icon: CupertinoIcons.shield,
                  title: 'Chính sách bảo mật',
                  showBorder: false,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryGroup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hoạt động', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: _buildMenuItem(
              context,
              icon: CupertinoIcons.time,
              title: 'Lịch sử hành trình',
              subtitle: 'Những nỗ lực cai thuốc trong quá khứ',
              showBorder: false,
              onTap: () => Navigator.pushNamed(context, AppRoutes.planHistory),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Đăng xuất',
            style: TextStyle(
              color: Color(0xFFF43F5E),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool showBorder = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: showBorder ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6B4EFF), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Color(0xFFCBD5E1), size: 16),
          ],
        ),
      ),
    );
  }
}
