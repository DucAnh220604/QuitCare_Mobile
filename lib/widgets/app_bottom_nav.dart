import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  final String currentRoute;

  const AppBottomNav({required this.currentRoute, super.key});

  @override
  Widget build(BuildContext context) {
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
