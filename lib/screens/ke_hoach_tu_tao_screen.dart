import 'package:flutter/material.dart';
import '../constants/colors.dart';

class KeHoachTuTaoScreen extends StatefulWidget {
  const KeHoachTuTaoScreen({super.key});

  @override
  State<KeHoachTuTaoScreen> createState() => _KeHoachTuTaoScreenState();
}

class _KeHoachTuTaoScreenState extends State<KeHoachTuTaoScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Tạo kế hoạch của bạn'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            _buildProgressBar(context),
            const SizedBox(height: 32),

            // Step Content
            if (_currentStep == 0) _buildStep1(context),
            if (_currentStep == 1) _buildStep2(context),
            if (_currentStep == 2) _buildStep3(context),

            const SizedBox(height: 32),

            // Navigation Buttons
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Quay lại'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        // Complete
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kế hoạch đã được tạo!'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: Text(_currentStep == 2 ? 'Hoàn thành' : 'Tiếp tục'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước ${_currentStep + 1} / 3',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            minHeight: 6,
            backgroundColor: AppColors.lightGrey,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mục tiêu của bạn',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildOption(
          context,
          title: 'Bỏ hoàn toàn',
          description: 'Dừng sử dụng thuốc hoàn toàn',
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          title: 'Giảm dần',
          description: 'Giảm lượng thuốc theo thời gian',
          icon: Icons.trending_down,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          title: 'Quản lý',
          description: 'Kiểm soát thói quen hút thuốc',
          icon: Icons.balance,
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thời gian mong muốn',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildOption(
          context,
          title: '30 ngày',
          description: 'Bỏ nhanh',
          icon: Icons.flash_on,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          title: '60 ngày',
          description: 'Cân bằng',
          icon: Icons.equalizer,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          title: '90 ngày',
          description: 'Từ từ và an toàn',
          icon: Icons.spa,
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hỗ trợ bổ sung',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildCheckbox(context, label: 'Nhận thông báo hàng ngày'),
        const SizedBox(height: 12),
        _buildCheckbox(context, label: 'Tham gia cộng đồng'),
        const SizedBox(height: 12),
        _buildCheckbox(context, label: 'Tư vấn từ chuyên gia'),
        const SizedBox(height: 12),
        _buildCheckbox(context, label: 'Theo dõi sức khỏe'),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.radio_button_unchecked, color: AppColors.primaryBlue),
        ],
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context, {required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Checkbox(
            value: true,
            onChanged: (_) {},
            activeColor: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
