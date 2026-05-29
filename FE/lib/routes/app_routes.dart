import 'package:flutter/material.dart';
import '../screens/main_app.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/tien_trinh_screen.dart';
import '../screens/bang_xep_hang_screen.dart';
import '../screens/cong_dong_screen.dart';
import '../screens/goi_thanh_vien_screen.dart';
import '../screens/ho_so_screen.dart';
import '../screens/ke_hoach_de_xuat_screen.dart';
import '../screens/ke_hoach_tu_tao_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String mainApp = '/main';
  static const String tienTrinh = '/tien-trinh';
  static const String bangXepHang = '/bang-xep-hang';
  static const String congDong = '/cong-dong';
  static const String goiThanhVien = '/goi-thanh-vien';
  static const String hoSo = '/ho-so';
  static const String keHoachDeXuat = '/ke-hoach-de-xuat';
  static const String keHoachTuTao = '/ke-hoach-tu-tao';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const MainApp());
      case mainApp:
        return MaterialPageRoute(builder: (_) => const MainApp());
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
        return MaterialPageRoute(builder: (_) => const MainApp());
    }
  }
}
