import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import '../routes/app_routes.dart';
import '../constants/colors.dart';
import '../services/auth_provider.dart';
import '../services/membership_provider.dart';
import 'home_screen.dart';
import 'ke_hoach_cua_toi_screen.dart';
import 'booking_doctor_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const KeHoachCuaToiScreen();
      case 2:
        return const BookingDoctorScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.darkGrey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house),
              activeIcon: Icon(CupertinoIcons.house_fill),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.doc_text),
              activeIcon: Icon(CupertinoIcons.doc_text_fill),
              label: 'Kế hoạch',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.videocam),
              activeIcon: Icon(CupertinoIcons.videocam_fill),
              label: 'Lịch hẹn',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              activeIcon: Icon(CupertinoIcons.person_fill),
              label: 'Hồ sơ',
            ),
          ],
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    final user = context.watch<AuthProvider>().user;
    final fullname = ((user?['fullname'] as String?) ?? '').trim();
    final email = ((user?['email'] as String?) ?? '');
    final initials = _getInitials(fullname);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────
          _buildProfileHeader(fullname, email, initials),

          const SizedBox(height: 20),

          // ── Menu sections ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('TÀI KHOẢN'),
                const SizedBox(height: 8),
                _menuCard([
                  _menuTile(
                    icon: CupertinoIcons.person,
                    label: 'Thông tin cá nhân',
                    subtitle: 'Xem và chỉnh sửa hồ sơ',
                    color: AppColors.primaryBlue,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profileDetail),
                  ),
                  _menuTile(
                    icon: CupertinoIcons.lock,
                    label: 'Đổi mật khẩu',
                    subtitle: 'Cập nhật mật khẩu bảo mật',
                    color: AppColors.brandPurple,
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 20),
                _sectionLabel('ỨNG DỤNG'),
                const SizedBox(height: 8),
                _menuCard([
                  _menuTile(
                    icon: CupertinoIcons.rosette,
                    label: 'Gói thành viên',
                    subtitle: 'Nâng cấp tài khoản VIP',
                    color: const Color(0xFFD97706),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.goiThanhVien),
                  ),
                  _menuTile(
                    icon: CupertinoIcons.settings,
                    label: 'Cài đặt',
                    subtitle: 'Tuỳ chỉnh ứng dụng',
                    color: AppColors.info,
                    onTap: () {},
                  ),
                  _menuTile(
                    icon: CupertinoIcons.bell,
                    label: 'Thông báo',
                    subtitle: 'Quản lý cài đặt nhắc nhở',
                    color: AppColors.brandOrange,
                    onTap: () {},
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 20),
                _logoutButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String fullname, String email, String initials) {
    final user = context.watch<AuthProvider>().user;
    final profile = user?['smokingProfile'] as Map<String, dynamic>?;
    final cigarettesPerDay = (profile?['cigarettesPerDay'] as int?) ?? 0;
    final currentPlanRaw = profile?['currentPlan'];
    final planName = (currentPlanRaw is Map)
        ? ((currentPlanRaw['name'] as String?) ?? 'Đang thực hiện')
        : (profile?['activeQuitPlanId'] != null ? 'Đang thực hiện' : 'Chưa chọn');

    final membership = context.watch<MembershipProvider>().currentMembership;
    final memberType = membership?['type'] as String?;
    final isVip = memberType != null && memberType != 'free' && memberType != '99k';
    final isBasic = memberType == '99k';
    final memberLabel = isVip ? 'VIP' : (isBasic ? 'Thường' : 'Miễn phí');
    final memberIcon = isVip ? CupertinoIcons.rosette : CupertinoIcons.checkmark_seal;
    final memberColor = isVip
        ? const Color(0xFFFBBF24)
        : (isBasic ? const Color(0xFF93C5FD) : Colors.white.withValues(alpha: 0.6));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001A4D), Color(0xFF0057CC)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              right: -40,
              top: -40,
              child: _decorCircle(180, 0.07),
            ),
            Positioned(
              left: -30,
              bottom: 30,
              child: _decorCircle(120, 0.05),
            ),
            Positioned(
              right: 50,
              bottom: -15,
              child: _decorCircle(90, 0.06),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  // Top row: spacer + edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.profileDetail),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.pencil,
                                  color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text(
                                'Chỉnh sửa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Avatar with concentric rings
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      // Middle ring
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Avatar circle
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.32),
                              Colors.white.withValues(alpha: 0.12),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Stats glass card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        _profileStat(
                          icon: CupertinoIcons.nosign,
                          iconColor: const Color(0xFF4ADE80),
                          value: cigarettesPerDay > 0
                              ? '$cigarettesPerDay'
                              : '--',
                          label: 'Điếu/ngày',
                        ),
                        _profileStatDivider(),
                        _profileStat(
                          icon: CupertinoIcons.doc_text,
                          iconColor: const Color(0xFF93C5FD),
                          value: planName.length > 10
                              ? '${planName.substring(0, 9)}…'
                              : planName,
                          label: 'Kế hoạch',
                        ),
                        _profileStatDivider(),
                        _profileStat(
                          icon: memberIcon,
                          iconColor: memberColor,
                          value: memberLabel,
                          label: 'Thành viên',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  Widget _profileStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStatDivider() => Container(
        width: 1,
        height: 40,
        color: Colors.white.withValues(alpha: 0.2),
      );

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _menuCard(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: tiles),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 13,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: const Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  Widget _logoutButton() {
    return GestureDetector(
      onTap: () async {
        final authProvider = context.read<AuthProvider>();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text('Bạn có chắc muốn đăng xuất không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await authProvider.logout();
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.square_arrow_right, color: AppColors.danger, size: 18),
            SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((String p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}
