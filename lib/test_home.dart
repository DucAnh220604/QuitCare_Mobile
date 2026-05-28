import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

class TestNavigationHome extends StatelessWidget {
  const TestNavigationHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuitCare - Navigation Test'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: const Text(
                'Navigation Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(context, 'Trang Chủ', AppRoutes.home),
            _buildDrawerItem(context, 'Tiến Trình', AppRoutes.tienTrinh),
            _buildDrawerItem(context, 'Bảng Xếp Hạng', AppRoutes.bangXepHang),
            _buildDrawerItem(context, 'Cộng Đồng', AppRoutes.congDong),
            _buildDrawerItem(context, 'Gói Thành Viên', AppRoutes.goiThanhVien),
            _buildDrawerItem(context, 'Hồ Sơ', AppRoutes.hoSo),
            _buildDrawerItem(
              context,
              'Kế Hoạch Đề Xuất',
              AppRoutes.keHoachDeXuat,
            ),
            _buildDrawerItem(
              context,
              'Kế Hoạch Tự Tạo',
              AppRoutes.keHoachTuTao,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn một trang để điều hướng:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildNavigationButton(context, 'Trang Chủ', AppRoutes.home),
            _buildNavigationButton(context, 'Tiến Trình', AppRoutes.tienTrinh),
            _buildNavigationButton(
              context,
              'Bảng Xếp Hạng',
              AppRoutes.bangXepHang,
            ),
            _buildNavigationButton(context, 'Cộng Đồng', AppRoutes.congDong),
            _buildNavigationButton(
              context,
              'Gói Thành Viên',
              AppRoutes.goiThanhVien,
            ),
            _buildNavigationButton(context, 'Hồ Sơ', AppRoutes.hoSo),
            _buildNavigationButton(
              context,
              'Kế Hoạch Đề Xuất',
              AppRoutes.keHoachDeXuat,
            ),
            _buildNavigationButton(
              context,
              'Kế Hoạch Tự Tạo',
              AppRoutes.keHoachTuTao,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context,
    String title,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Đóng drawer
        Navigator.pushNamed(context, route);
      },
    );
  }
}
