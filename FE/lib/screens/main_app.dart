import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../constants/colors.dart';
import '../services/auth_provider.dart';
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
                    Text(
                      context.watch<AuthProvider>().user?['fullname'] ?? 'Người dùng',
                      style: const TextStyle(
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
                  () async {
                    final authProvider = context.read<AuthProvider>();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text('Bạn có chắc muốn đăng xuất không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
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
}
