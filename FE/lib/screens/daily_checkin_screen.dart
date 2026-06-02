import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/progress_service.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final _progressService = ProgressService();
  bool _isLoading = false;

  double _cigarettesSmoked = 0;
  String _cravingLevel = "Không thèm";
  String _mood = "Bình thường";
  
  final List<String> _availableSymptoms = ["Ho", "Đau đầu", "Khó ngủ", "Căng thẳng", "Thèm ăn", "Chóng mặt"];
  final List<String> _selectedSymptoms = [];
  final TextEditingController _noteController = TextEditingController();

  Future<void> _submitCheckin() async {
    setState(() => _isLoading = true);

    final result = await _progressService.checkIn(
      cigarettesSmoked: _cigarettesSmoked.toInt(),
      cravingLevel: _cravingLevel,
      mood: _mood,
      symptoms: _selectedSymptoms,
      note: _noteController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghi nhận thành công!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true); // true indicates success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ghi nhận hôm nay'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hôm nay bạn thế nào?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy trung thực với bản thân để hệ thống theo dõi tốt nhất.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Cigarettes Smoked
            Text(
              'Số điếu đã hút hôm nay: ${_cigarettesSmoked.toInt()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _cigarettesSmoked,
              min: 0,
              max: 50,
              divisions: 50,
              activeColor: _cigarettesSmoked == 0 ? AppColors.success : AppColors.danger,
              onChanged: (val) {
                setState(() => _cigarettesSmoked = val);
              },
            ),
            if (_cigarettesSmoked == 0)
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('Tuyệt vời! Bạn đang giữ vững phong độ.', style: TextStyle(color: AppColors.success)),
              ),
            const SizedBox(height: 32),

            // Craving
            Text(
              'Mức độ thèm thuốc',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "Không thèm", label: Text('Không thèm')),
                ButtonSegment(value: "Thèm nhẹ", label: Text('Thèm nhẹ')),
                ButtonSegment(value: "Thèm nhiều", label: Text('Thèm nhiều')),
              ],
              selected: {_cravingLevel},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _cravingLevel = newSelection.first);
              },
            ),
            const SizedBox(height: 32),

            // Mood
            Text(
              'Tâm trạng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "Tốt", label: Text('Tốt')),
                ButtonSegment(value: "Bình thường", label: Text('Bình thường')),
                ButtonSegment(value: "Tệ", label: Text('Tệ')),
              ],
              selected: {_mood},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _mood = newSelection.first);
              },
            ),
            const SizedBox(height: 32),

            // Symptoms
            Text(
              'Triệu chứng sức khỏe (nếu có)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSymptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primaryBlue,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Note
            Text(
              'Ghi chú thêm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhật ký của bạn...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCheckin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text(
                        'Lưu nhật ký',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
