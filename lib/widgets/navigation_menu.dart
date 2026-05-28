import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../constants/colors.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMenuItem(context, 'Trang Chủ', AppRoutes.home, Icons.home),
          _buildMenuItem(
            context,
            'Tiến Trình',
            AppRoutes.tienTrinh,
            Icons.trending_up,
          ),
          _buildMenuItem(
            context,
            'Bảng Xếp Hạng',
            AppRoutes.bangXepHang,
            Icons.leaderboard,
          ),
          _buildMenuItem(
            context,
            'Cộng Đồng',
            AppRoutes.congDong,
            Icons.people,
          ),
          _buildMenuItem(
            context,
            'Gói Thành Viên',
            AppRoutes.goiThanhVien,
            Icons.card_membership,
          ),
          _buildMenuItem(context, 'Hồ Sơ', AppRoutes.hoSo, Icons.person),
          _buildMenuItem(
            context,
            'Kế Hoạch Đề Xuất',
            AppRoutes.keHoachDeXuat,
            Icons.lightbulb,
          ),
          _buildMenuItem(
            context,
            'Kế Hoạch Tự Tạo',
            AppRoutes.keHoachTuTao,
            Icons.edit,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}
