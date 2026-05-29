import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../constants/colors.dart';
import 'home_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0 ? const HomeScreen() : _buildProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.darkGrey,
        backgroundColor: AppColors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ Sơ'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildProfileScreen() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkBlue, AppColors.primaryBlue],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nguyễn Văn A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Text(
                    //   'Member VIP',
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     color: AppColors.white.withValues(alpha: 0.85),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileMenuTile(
                  'Thông tin cá nhân',
                  Icons.person_outline,
                  () => Navigator.pushNamed(context, AppRoutes.hoSo),
                  color: AppColors.primaryBlue,
                ),
                _buildProfileMenuTile(
                  'Cài đặt',
                  Icons.settings,
                  () {},
                  color: AppColors.info,
                ),
                _buildProfileMenuTile(
                  'Đổi mật khẩu',
                  Icons.lock_outline,
                  () {},
                  color: AppColors.warning,
                ),
                _buildProfileMenuTile(
                  'Đăng xuất',
                  Icons.logout,
                  () {},
                  color: AppColors.danger,
                  isDanger: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.7),
                color.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppColors.white),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDanger = false,
    Color? color,
  }) {
    final iconColor = isDanger
        ? AppColors.danger
        : (color ?? AppColors.primaryBlue);
    final textColor = isDanger ? AppColors.danger : AppColors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: isDanger
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.danger.withValues(alpha: 0.2),
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.mediumGrey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getGridItems() {
    return [
      {
        'label': 'Gói Thành Viên',
        'icon': Icons.card_membership,
        'color': AppColors.danger,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.goiThanhVien),
      },
      {
        'label': 'Kế Hoạch Đề Xuất',
        'icon': Icons.lightbulb,
        'color': AppColors.warning,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.keHoachDeXuat),
      },
      {
        'label': 'Kế Hoạch Riêng',
        'icon': Icons.edit,
        'color': AppColors.primaryBlue,
        'onTap': () => Navigator.pushNamed(context, AppRoutes.keHoachTuTao),
      },
    ];
  }
}
