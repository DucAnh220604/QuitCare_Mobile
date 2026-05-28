import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GoiThanhVienScreen extends StatefulWidget {
  const GoiThanhVienScreen({super.key});

  @override
  State<GoiThanhVienScreen> createState() => _GoiThanhVienScreenState();
}

class _GoiThanhVienScreenState extends State<GoiThanhVienScreen> {
  bool isMonthly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Gói thành viên'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isMonthly = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isMonthly
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Tháng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isMonthly
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isMonthly = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isMonthly
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Năm',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !isMonthly
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Packages
            Column(
              children: [
                _buildPackageCard(
                  context,
                  title: 'Free',
                  price: 'Miễn phí',
                  description: 'Bắt đầu hành trình của bạn',
                  features: [
                    '✓ Tính năng cơ bản',
                    '✓ Theo dõi tiến độ',
                    '✗ Cộng đồng premium',
                    '✗ Tư vấn 1-1',
                  ],
                  isPopular: false,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildPackageCard(
                  context,
                  title: 'Pro',
                  price: isMonthly ? '99.000 đ' : '990.000 đ',
                  duration: isMonthly ? '/tháng' : '/năm',
                  badge: 'Được chọn nhiều nhất',
                  description: 'Truy cập đầy đủ tất cả tính năng',
                  features: [
                    '✓ Tính năng cơ bản',
                    '✓ Theo dõi tiến độ nâng cao',
                    '✓ Cộng đồng premium',
                    '✓ Tư vấn 1-1 hàng tháng',
                  ],
                  isPopular: true,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildPackageCard(
                  context,
                  title: 'Premium',
                  price: isMonthly ? '199.000 đ' : '1.990.000 đ',
                  duration: isMonthly ? '/tháng' : '/năm',
                  description: 'Hỗ trợ VIP và tư vấn độc lập',
                  features: [
                    '✓ Tất cả tính năng Pro',
                    '✓ Hỗ trợ ưu tiên 24/7',
                    '✓ Tư vấn 1-1 tuần',
                    '✓ Kế hoạch cá nhân hóa',
                  ],
                  isPopular: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Câu hỏi thường gặp',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              question: 'Tôi có thể hủy bỏ bất cứ lúc nào không?',
              answer:
                  'Có, bạn có thể hủy gói thành viên của mình bất cứ lúc nào.',
            ),
            _buildFaqItem(
              context,
              question: 'Có chế độ dùng thử miễn phí không?',
              answer: 'Có, bạn có thể sử dụng gói Free để trải nghiệm trước.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context, {
    required String title,
    required String price,
    String? duration,
    String? badge,
    required String description,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPopular
            ? AppColors.primaryBlue.withOpacity(0.1)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppColors.primaryBlue : AppColors.divider,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? AppColors.primaryBlue.withOpacity(0.2)
                : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (badge != null) const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                if (duration != null)
                  TextSpan(
                    text: duration,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? AppColors.primaryBlue
                    : AppColors.lightGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Chọn gói này',
                style: TextStyle(
                  color: isPopular ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Text(
            answer,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
