import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/membership_provider.dart';

class GoiThanhVienScreen extends StatefulWidget {
  const GoiThanhVienScreen({super.key});

  @override
  State<GoiThanhVienScreen> createState() => _GoiThanhVienScreenState();
}

class _GoiThanhVienScreenState extends State<GoiThanhVienScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final membershipProvider =
          Provider.of<MembershipProvider>(context, listen: false);
      membershipProvider.fetchPackages();
      membershipProvider.fetchCurrentMembership();
    });
  }

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
      body: Consumer<MembershipProvider>(
        builder: (context, membershipProvider, _) {
          if (membershipProvider.isLoading &&
              membershipProvider.packages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentMembership = membershipProvider.currentMembership;
          final packages = membershipProvider.packages;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current membership info
                if (currentMembership != null &&
                    currentMembership['type'] != 'free')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gói hiện tại của bạn',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentMembership['type'] == '99k'
                              ? 'Gói Cơ Bản (99K)'
                              : 'Gói Premium (199K)',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trạng thái: ${currentMembership['status'] == 'active' ? 'Đang hoạt động' : 'Không hoạt động'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                if (currentMembership != null &&
                    currentMembership['type'] != 'free')
                  const SizedBox(height: 24),

                // Packages title
                Text(
                  'Lựa chọn gói thành viên',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Packages list
                Column(
                  children: packages
                      .map((pkg) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPackageCard(
                          context,
                          package: pkg,
                          isCurrentMembership:
                              currentMembership?['type'] == pkg['id'],
                          membershipProvider: membershipProvider,
                        ),
                      ))
                      .toList(),
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
                  question: 'Sự khác biệt giữa hai gói là gì?',
                  answer:
                  'Gói Cơ Bản (99K) bao gồm xem thống kê và xây dựng kế hoạch. Gói Premium (199K) bao gồm tất cả tính năng của gói Cơ Bản cộng với tính năng video call.',
                ),
                _buildFaqItem(
                  context,
                  question: 'Thời hạn của gói là bao lâu?',
                  answer: 'Cả hai gói đều có thời hạn vô hạn, bạn có thể sử dụng mãi mãi.',
                ),
                _buildFaqItem(
                  context,
                  question: 'Tôi có thể thay đổi gói sau này không?',
                  answer:
                  'Có, bạn có thể nâng cấp hoặc hạ cấp gói của mình bất cứ lúc nào.',
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context, {
    required Map<String, dynamic> package,
    required bool isCurrentMembership,
    required MembershipProvider membershipProvider,
  }) {
    final isPopular = package['id'] == '199k';
    final features = List<String>.from(package['features'] ?? []);

    return Container(
      decoration: BoxDecoration(
        color: isPopular
            ? AppColors.primaryBlue.withValues(alpha: 0.1)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentMembership
              ? AppColors.success
              : (isPopular ? AppColors.primaryBlue : AppColors.divider),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCurrentMembership ? AppColors.success : (isPopular ? AppColors.primaryBlue : AppColors.shadow))
                .withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                package['name'] ?? 'Gói',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isCurrentMembership)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hiện tại',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            package['duration'] ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatPrice(package['price']),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                TextSpan(
                  text: ' VND',
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
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (!isCurrentMembership)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _showPaymentDialog(context, package, membershipProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Đăng ký gói này',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success),
              ),
              child: Text(
                'Gói hiện tại',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    Map<String, dynamic> package,
    MembershipProvider membershipProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gói: ${package['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Giá: ${_formatPrice(package['price'])} VND'),
            const SizedBox(height: 8),
            Text('Thời hạn: ${package['duration']}'),
            const SizedBox(height: 16),
            Text(
              'Bạn có chắc chắn muốn đăng ký gói này không?',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _processPayment(
                this.context, // Truyền context của Screen thay vì dialog
                package['id'],
                membershipProvider,
              );
            },
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    String packageId,
    MembershipProvider membershipProvider,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
      const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await membershipProvider.registerMembership(packageId).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Kết nối timeout, vui lòng thử lại');
        },
      );

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Rebuild UI to show current membership
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                membershipProvider.errorMessage ?? 'Đăng ký thất bại',
              ),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price is int) {
      return price.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
      );
    }
    return price.toString();
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: InkRipple.splashFactory,
        ),
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
      ),
    );
  }
}
