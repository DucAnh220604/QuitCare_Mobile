import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class ScreenWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBottomNavigation;
  final String currentRoute;

  const ScreenWrapper({
    required this.title,
    required this.child,
    this.actions,
    this.showBottomNavigation = true,
    this.currentRoute = AppRoutes.home,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 2,
        actions: actions,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: child,
      bottomNavigationBar: showBottomNavigation
          ? _buildBottomNav(context)
          : null,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getNavIndex(),
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.darkGrey,
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up),
          label: 'Tiến Trình',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard),
          label: 'Xếp Hạng',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Cộng Đồng'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Lịch Hẹn',
        ),
      ],
      onTap: (index) => _navigateToTab(context, index),
    );
  }

  int _getNavIndex() {
    switch (currentRoute) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.tienTrinh:
        return 1;
      case AppRoutes.bangXepHang:
        return 2;
      case AppRoutes.congDong:
        return 3;
      default:
        return 0;
    }
  }

  void _navigateToTab(BuildContext context, int index) {
    final routes = [
      AppRoutes.home,
      AppRoutes.tienTrinh,
      AppRoutes.bangXepHang,
      AppRoutes.congDong,
    ];

    Navigator.pushNamed(context, routes[index]);
  }
}
