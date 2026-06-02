import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../constants/colors.dart';
import '../services/progress_service.dart';
import '../routes/app_routes.dart';

class TienTrinhScreen extends StatefulWidget {
  const TienTrinhScreen({super.key});

  @override
  State<TienTrinhScreen> createState() => _TienTrinhScreenState();
}

class _TienTrinhScreenState extends State<TienTrinhScreen> {
  final _progressService = ProgressService();
  bool _isLoading = true;
  
  int _streak = 0;
  int _moneySaved = 0;
  int _totalAvoided = 0;
  int _durationDays = 0;
  int _logsCount = 0;
  bool _hasCheckedInToday = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final result = await _progressService.getProgressStats();
    
    if (result['success']) {
      setState(() {
        _streak = result['data']['streak'] ?? 0;
        _moneySaved = result['data']['moneySaved'] ?? 0;
        _totalAvoided = result['data']['totalAvoided'] ?? 0;
        _hasCheckedInToday = result['data']['hasCheckedInToday'] ?? false;
        _durationDays = result['data']['durationDays'] ?? 0;
        _logsCount = result['data']['logsCount'] ?? 0;
      });
    }
    setState(() => _isLoading = false);
  }

  bool get _isCompleted => _durationDays > 0 && _logsCount >= _durationDays;

  Future<void> _completePlan() async {
    setState(() => _isCompleting = true);
    final result = await _progressService.completePlan();
    
    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: AppColors.success),
      );
      // Reload User Provider so Home/HoSo knows Plan is completed
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.fetchProfile();
      
      if (mounted) {
        Navigator.pop(context); // Go back to Home
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Có lỗi xảy ra'), backgroundColor: AppColors.danger),
      );
      setState(() => _isCompleting = false);
    }
  }

  Future<void> _forceSimulate() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận giả lập'),
        content: const Text('Hành động này sẽ xóa toàn bộ nhật ký hiện tại và tạo ra dữ liệu giả lập cho toàn bộ kế hoạch để demo. Bạn có chắc chắn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _progressService.forceSimulate();
      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: AppColors.success),
        );
        _fetchStats();
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    }
    return '$amount đ';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Tiến trình của bạn'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.electric_bolt, color: AppColors.warning),
            tooltip: 'Giả lập dữ liệu Demo',
            onPressed: _forceSimulate,
          ),
        ],
      ),
      floatingActionButton: _isCompleted
          ? FloatingActionButton.extended(
              onPressed: _isCompleting ? null : _completePlan,
              backgroundColor: AppColors.success,
              icon: _isCompleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.emoji_events, color: Colors.white),
              label: Text(_isCompleting ? 'Đang xử lý...' : 'Hoàn tất Kế hoạch', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : (!_hasCheckedInToday
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.dailyCheckin).then((val) {
                      if (val == true) _fetchStats();
                    });
                  },
                  backgroundColor: AppColors.warning,
                  icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                  label: const Text('Ghi nhận hôm nay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Stats
            _buildMainStatCard(context),
            const SizedBox(height: 32),

            // Milestones
            Text(
              'Cột mốc sức khỏe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildMilestonesList(context),
            const SizedBox(height: 32),

            // Benefits
            Text(
              'Lợi ích sức khỏe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildBenefitsGrid(context),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Số ngày không hút thuốc',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_streak',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                label: 'Tiền tiết kiệm',
                value: _formatMoney(_moneySaved),
                color: AppColors.warning,
              ),
              _buildStatColumn(
                context,
                label: 'Số điếu tránh được',
                value: '$_totalAvoided',
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
        ),
      ],
    );
  }

  Widget _buildMilestonesList(BuildContext context) {
    // Dynamic milestones based on current streak
    List<Map<String, dynamic>> milestones = [
      {
        'day': 1,
        'title': '1 Ngày',
        'description': 'Huyết áp và nhịp tim ổn định',
        'icon': Icons.favorite,
      },
      {
        'day': 7,
        'title': '1 Tuần',
        'description': 'Hệ hô hấp bắt đầu phục hồi',
        'icon': Icons.air,
      },
      {
        'day': 30,
        'title': '1 Tháng',
        'description': 'Khứu giác và vị giác cải thiện',
        'icon': Icons.restaurant,
      },
      {
        'day': 90,
        'title': '3 Tháng',
        'description': 'Chức năng phổi tăng 30%',
        'icon': Icons.local_hospital,
      },
      {
        'day': 365,
        'title': '1 Năm',
        'description': 'Giảm 50% nguy cơ bệnh tim',
        'icon': Icons.health_and_safety,
      },
    ];

    return Column(
      children: milestones.map((milestone) {
        bool achieved = _streak >= milestone['day'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMilestoneCard(context, milestone: milestone, achieved: achieved),
        );
      }).toList(),
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context, {
    required Map<String, dynamic> milestone,
    required bool achieved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achieved ? AppColors.success : AppColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            milestone['icon'],
            color: achieved ? AppColors.success : AppColors.mediumGrey,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone['title'],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: achieved ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  milestone['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (achieved)
            const Icon(Icons.check_circle, color: AppColors.success, size: 24),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid(BuildContext context) {
    List<Map<String, String>> benefits = [
      {'title': 'Khứu giác', 'icon': '👃'},
      {'title': 'Vị giác', 'icon': '👅'},
      {'title': 'Phổi', 'icon': '💨'},
      {'title': 'Tim', 'icon': '❤️'},
      {'title': 'Năng lực', 'icon': '⚡'},
      {'title': 'Da', 'icon': '✨'},
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: benefits.map((benefit) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(benefit['icon']!, style: const TextTheme().displaySmall),
              const SizedBox(height: 8),
              Text(
                benefit['title']!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
