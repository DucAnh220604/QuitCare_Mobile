import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/tien_trinh_screen.dart';
import '../screens/bang_xep_hang_screen.dart';
import '../screens/cong_dong_screen.dart';
import '../screens/goi_thanh_vien_screen.dart';
import '../screens/ho_so_screen.dart';
import '../screens/ke_hoach_de_xuat_screen.dart';
import '../screens/ke_hoach_tu_tao_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String tienTrinh = '/tien-trinh';
  static const String bangXepHang = '/bang-xep-hang';
  static const String congDong = '/cong-dong';
  static const String goiThanhVien = '/goi-thanh-vien';
  static const String hoSo = '/ho-so';
  static const String keHoachDeXuat = '/ke-hoach-de-xuat';
  static const String keHoachTuTao = '/ke-hoach-tu-tao';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case tienTrinh:
        return MaterialPageRoute(builder: (_) => const TienTrinhScreen());
      case bangXepHang:
        return MaterialPageRoute(builder: (_) => const BangXepHangScreen());
      case congDong:
        return MaterialPageRoute(builder: (_) => const CongDongScreen());
      case goiThanhVien:
        return MaterialPageRoute(builder: (_) => const GoiThanhVienScreen());
      case hoSo:
        return MaterialPageRoute(builder: (_) => const HoSoScreen());
      case keHoachDeXuat:
        return MaterialPageRoute(builder: (_) => const KeHoachDeXuatScreen());
      case keHoachTuTao:
        return MaterialPageRoute(builder: (_) => const KeHoachTuTaoScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
