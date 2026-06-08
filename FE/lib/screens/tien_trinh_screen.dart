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
  Map<String, dynamic>? _quitPlanInfo;

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
        _quitPlanInfo = result['data']['quitPlan'] as Map<String, dynamic>?;
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

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '--';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
              onPressed: _isLoading ? null : _forceSimulate,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Hồi phục'),
            ],
          ),
        ),
        floatingActionButton: _isLoading ? null : (_isCompleted
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
                : null)),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : TabBarView(
                children: [
                  // Tab 1: Tổng quan
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainStatCard(context),
                        const SizedBox(height: 24),
                        if (_quitPlanInfo != null) ...[
                          Text(
                            'Kế hoạch hiện tại',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPlanInfoCard(context),
                          const SizedBox(height: 80),
                        ],
                      ],
                    ),
                  ),
                  // Tab 2: Hồi phục
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cột mốc phục hồi cơ thể',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Những thay đổi kỳ diệu của cơ thể khi bạn ngừng hút thuốc (Theo tổ chức Y tế thế giới WHO).',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMilestonesTimeline(context),
                        const SizedBox(height: 32),
                        Text(
                          'Lợi ích sức khỏe',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBenefitsGrid(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMainStatCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
              Container(width: 1, height: 40, color: Colors.white24),
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
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
        ),
      ],
    );
  }

  Widget _buildPlanInfoCard(BuildContext context) {
    final info = _quitPlanInfo!;
    final currentStage = info['currentStage'] as Map<String, dynamic>?;
    final currentIdx = (info['currentStageIndex'] as int?) ?? -1;
    final totalStages = (info['totalStages'] as int?) ?? 0;
    final overallProgress = (info['overallProgress'] as num?)?.toDouble() ?? 0.0;
    final type = info['type'] as String? ?? 'suggested';
    final overallEnd = _formatDate(info['overallEndDate']);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.keHoachCuaToi),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5), width: 1),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'suggested' ? Icons.auto_awesome : Icons.edit_note_rounded,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type == 'suggested' ? 'Kế hoạch đề xuất' : 'Kế hoạch tự lập',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến độ tổng thể',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(overallProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: overallProgress,
                minHeight: 10,
                backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dự kiến kết thúc: $overallEnd',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),

            if (currentStage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GĐ ${currentIdx + 1}/$totalStages',
                        style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStage['stageName'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            () {
                              final cigs = currentStage['cigarettesPerDay'] as int? ?? 0;
                              return cigs == 0
                                  ? 'Mục tiêu: Hoàn toàn cai thuốc'
                                  : 'Mục tiêu: $cigs điếu/ngày';
                            }(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(currentStage['startDate'])} → ${_formatDate(currentStage['endDate'])}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesTimeline(BuildContext context) {
    List<Map<String, dynamic>> milestones = [
      {
        'day': 1, 
        'title': 'Sau 20 phút - 12 giờ',
        'description': 'Nhịp tim và huyết áp giảm dần. Lượng carbon monoxide (CO) trong máu trở về mức bình thường.',
        'icon': Icons.favorite,
      },
      {
        'day': 2,
        'title': 'Sau 2 - 3 ngày',
        'description': 'Nicotine hoàn toàn được loại bỏ khỏi cơ thể. Khứu giác và vị giác bắt đầu nhạy bén hơn.',
        'icon': Icons.restaurant,
      },
      {
        'day': 14,
        'title': 'Sau 2 - 12 tuần',
        'description': 'Hệ tuần hoàn cải thiện đáng kể, chức năng phổi bắt đầu tăng cường, đi lại dễ dàng hơn.',
        'icon': Icons.directions_walk,
      },
      {
        'day': 30,
        'title': 'Sau 1 - 9 tháng',
        'description': 'Tình trạng ho và khó thở giảm hẳn. Các nhung mao trong phổi bắt đầu hoạt động bình thường trở lại, làm sạch dịch nhầy và chống nhiễm trùng.',
        'icon': Icons.air,
      },
      {
        'day': 365,
        'title': 'Sau 1 năm',
        'description': 'Nguy cơ mắc bệnh tim mạch vành giảm đi một nửa so với người tiếp tục hút thuốc.',
        'icon': Icons.health_and_safety,
      },
      {
        'day': 1825,
        'title': 'Sau 5 năm',
        'description': 'Nguy cơ bị đột quỵ giảm xuống mức tương đương với người không bao giờ hút thuốc.',
        'icon': Icons.monitor_heart,
      },
      {
        'day': 3650,
        'title': 'Sau 10 năm',
        'description': 'Nguy cơ tử vong do ung thư phổi giảm chỉ còn một nửa so với người vẫn tiếp tục hút.',
        'icon': Icons.local_hospital,
      },
    ];

    return Column(
      children: milestones.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> milestone = entry.value;
        bool achieved = _streak >= milestone['day'];
        bool isLast = index == milestones.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: achieved ? AppColors.success.withValues(alpha: 0.15) : AppColors.divider.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: achieved ? AppColors.success : AppColors.divider,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      milestone['icon'],
                      size: 18,
                      color: achieved ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: achieved ? AppColors.success : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: achieved ? AppColors.success.withValues(alpha: 0.5) : AppColors.divider.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                milestone['title'],
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: achieved ? AppColors.success : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (achieved)
                              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          milestone['description'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBenefitsGrid(BuildContext context) {
    List<Map<String, dynamic>> benefits = [
      {'title': 'Khứu & Vị giác', 'icon': Icons.restaurant, 'desc': 'Ăn ngon miệng hơn'},
      {'title': 'Phổi & Hô hấp', 'icon': Icons.air, 'desc': 'Thở dễ dàng hơn'},
      {'title': 'Tim mạch', 'icon': Icons.favorite, 'desc': 'Huyết áp ổn định'},
      {'title': 'Năng lượng', 'icon': Icons.bolt, 'desc': 'Ít mệt mỏi hơn'},
      {'title': 'Làn da', 'icon': Icons.face_retouching_natural, 'desc': 'Tươi sáng, trẻ trung'},
      {'title': 'Tài chính', 'icon': Icons.savings, 'desc': 'Tiết kiệm đáng kể'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: benefits.map((benefit) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                benefit['icon'] as IconData,
                size: 26,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      benefit['desc'] as String,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
