import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Điều khoản sử dụng',
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
                '1. Chấp nhận điều khoản',
                'Bằng việc tải xuống, cài đặt và sử dụng ứng dụng QuitCare, bạn đồng ý tuân thủ và bị ràng buộc bởi các điều khoản sử dụng này. Nếu bạn không đồng ý với bất kỳ điều khoản nào, vui lòng không sử dụng ứng dụng.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '2. Mục đích của ứng dụng',
                'QuitCare là một ứng dụng hỗ trợ người dùng theo dõi và quản lý quá trình cai thuốc lá. Ứng dụng cung cấp các công cụ, kế hoạch và thông tin mang tính chất tham khảo. Ứng dụng không thay thế cho các chẩn đoán, điều trị hay tư vấn y khoa chuyên nghiệp.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '3. Quyền và trách nhiệm của người dùng',
                '• Cung cấp thông tin chính xác khi tạo hồ sơ.\n• Bảo mật thông tin tài khoản của mình.\n• Không sử dụng ứng dụng cho các mục đích bất hợp pháp hoặc vi phạm quy định pháp luật.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '4. Quyền sở hữu trí tuệ',
                'Tất cả nội dung, biểu tượng, thiết kế và mã nguồn của ứng dụng đều thuộc bản quyền của QuitCare. Mọi hành vi sao chép, chỉnh sửa hoặc phân phối mà không có sự cho phép đều bị nghiêm cấm.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '5. Giới hạn trách nhiệm',
                'QuitCare không chịu trách nhiệm pháp lý cho bất kỳ hậu quả, thiệt hại hoặc tác động sức khỏe nào phát sinh trong quá trình sử dụng ứng dụng. Hiệu quả của việc cai thuốc phụ thuộc vào sự kiên trì và nỗ lực của cá nhân người dùng.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                '6. Thay đổi điều khoản',
                'Chúng tôi có quyền thay đổi các điều khoản sử dụng này vào bất kỳ lúc nào mà không cần báo trước. Việc tiếp tục sử dụng ứng dụng sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận những thay đổi đó.',
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
