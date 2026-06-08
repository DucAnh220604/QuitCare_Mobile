import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
      membershipProvider.fetchPackages();
      membershipProvider.fetchCurrentMembership();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<MembershipProvider>(
                builder: (context, membershipProvider, _) {
                  if (membershipProvider.isLoading && membershipProvider.packages.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)));
                  }

                  final currentMembership = membershipProvider.currentMembership;
                  final packages = membershipProvider.packages;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (currentMembership != null && currentMembership['type'] != 'free')
                          _buildCurrentMembership(currentMembership),

                        const SizedBox(height: 24),
                        const Text(
                          'Chọn gói nâng cấp',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ...packages.map((pkg) => _buildPackageCard(
                          context,
                          package: pkg,
                          isCurrentMembership: currentMembership?['type'] == pkg['id'],
                          membershipProvider: membershipProvider,
                        )),

                        const SizedBox(height: 40),
                        const Text(
                          'Câu hỏi thường gặp',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFaqItem(
                          context,
                          question: 'Sự khác biệt giữa hai gói là gì?',
                          answer: 'Gói Cơ Bản (99K) bao gồm xem thống kê và xây dựng kế hoạch. Gói Premium (199K) bao gồm tất cả tính năng của gói Cơ Bản cộng với tính năng gọi Video trực tiếp với Bác sĩ.',
                        ),
                        _buildFaqItem(
                          context,
                          question: 'Thời hạn của gói là bao lâu?',
                          answer: 'Cả hai gói đều có thời hạn vĩnh viễn, bạn chỉ cần mua 1 lần và sử dụng mãi mãi.',
                        ),
                        _buildFaqItem(
                          context,
                          question: 'Tôi có thể nâng cấp sau này không?',
                          answer: 'Có, bạn hoàn toàn có thể nâng cấp lên Premium bất cứ lúc nào.',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1E293B), size: 20),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói thành viên',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mở khóa tính năng cao cấp',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.star_circle_fill, color: Color(0xFFF59E0B), size: 36),
        ],
      ),
    );
  }

  Widget _buildCurrentMembership(Map<String, dynamic> currentMembership) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6B4EFF), Color(0xFF9D4EDD)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói hiện tại của bạn',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  currentMembership['type'] == '99k' ? 'Gói Cơ Bản (99K)' : 'Gói Premium (199K)',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  currentMembership['status'] == 'active' ? 'Đang hoạt động' : 'Không hoạt động',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isPopular ? const Color(0xFFF3F0FF) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: isPopular ? Border.all(color: const Color(0xFF6B4EFF).withValues(alpha: 0.2), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                package['name'] ?? 'Gói',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Phổ biến',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              if (isCurrentMembership && !isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Hiện tại',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            package['duration'] ?? '',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatPrice(package['price']),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: isPopular ? const Color(0xFF6B4EFF) : const Color(0xFF1E293B),
                ),
              ),
              const Text(
                ' VND',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFF10B981), size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 24),
          if (!isCurrentMembership)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPaymentDialog(context, package, membershipProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? const Color(0xFF6B4EFF) : const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: isPopular ? 8 : 0,
                  shadowColor: isPopular ? const Color(0xFF6B4EFF).withValues(alpha: 0.5) : null,
                ),
                child: const Text('Đăng ký gói này', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Đang sử dụng',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> package, MembershipProvider membershipProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đang chọn gói:', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Text(package['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF6B4EFF))),
            const SizedBox(height: 4),
            Text('Giá: ${_formatPrice(package['price'])} VND', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Hệ thống sẽ tiến hành trừ tiền. Bạn có chắc chắn không?', style: TextStyle(color: Color(0xFF334155))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _processPayment(this.context, package['id'], membershipProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, String packageId, MembershipProvider membershipProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF))),
    );

    try {
      final success = await membershipProvider.registerMembership(packageId).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Kết nối timeout, vui lòng thử lại'),
      );
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!'), backgroundColor: Color(0xFF10B981)));
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(membershipProvider.errorMessage ?? 'Đăng ký thất bại'), backgroundColor: const Color(0xFFF43F5E)));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: const Color(0xFFF43F5E)));
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price is int) return price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return price.toString();
  }

  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF6B4EFF),
          collapsedIconColor: const Color(0xFF94A3B8),
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 15)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(answer, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
