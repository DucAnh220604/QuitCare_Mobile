import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Chính sách bảo mật',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cập nhật lần cuối: 08/06/2026',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. Thông tin thu thập',
                'Khi bạn sử dụng QuitCare, chúng tôi có thể thu thập các thông tin cá nhân (như Tên, Email, Số điện thoại) và các dữ liệu liên quan đến thói quen hút thuốc của bạn nhằm cá nhân hóa lộ trình cai thuốc.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '2. Cách thức sử dụng thông tin',
                'Các thông tin thu thập được sẽ được dùng để:\n• Gợi ý kế hoạch cai thuốc phù hợp.\n• Hiển thị tiến trình và phân tích cá nhân.\n• Gửi thông báo nhắc nhở và động viên hàng ngày.\n• Cải thiện chất lượng và trải nghiệm ứng dụng.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '3. Bảo mật và Lưu trữ',
                'Chúng tôi cam kết sử dụng các biện pháp bảo mật hiện đại để bảo vệ dữ liệu cá nhân của bạn khỏi các hành vi truy cập, tiết lộ hoặc phá hoại trái phép. Dữ liệu nhạy cảm được mã hóa và lưu trữ an toàn trên các máy chủ có độ bảo mật cao.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '4. Chia sẻ thông tin',
                'QuitCare cam kết KHÔNG bán, trao đổi hay chia sẻ thông tin cá nhân của bạn cho bất kỳ bên thứ ba nào vì mục đích thương mại, ngoại trừ các trường hợp có yêu cầu hợp pháp từ cơ quan chức năng.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '5. Quyền của người dùng',
                'Bạn có quyền truy cập, chỉnh sửa hoặc yêu cầu xóa toàn bộ dữ liệu cá nhân của mình trên hệ thống của QuitCare. Bạn có thể thực hiện thông qua chức năng Cài đặt trong ứng dụng hoặc liên hệ trực tiếp với đội ngũ hỗ trợ.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
