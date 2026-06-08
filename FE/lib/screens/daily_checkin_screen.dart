import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
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
        const SnackBar(content: Text('Ghi nhận thành công!'), backgroundColor: Color(0xFF10B981)),
      );
      Navigator.pop(context, true); // true indicates success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi'), backgroundColor: const Color(0xFFF43F5E)),
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
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCigarettesCard(),
                    const SizedBox(height: 24),
                    _buildSegmentCard(
                      title: 'Mức độ thèm thuốc',
                      icon: CupertinoIcons.flame,
                      options: ["Không thèm", "Thèm nhẹ", "Thèm nhiều"],
                      selectedValue: _cravingLevel,
                      onChanged: (val) => setState(() => _cravingLevel = val),
                    ),
                    const SizedBox(height: 24),
                    _buildSegmentCard(
                      title: 'Tâm trạng',
                      icon: CupertinoIcons.smiley,
                      options: ["Tốt", "Bình thường", "Tệ"],
                      selectedValue: _mood,
                      onChanged: (val) => setState(() => _mood = val),
                    ),
                    const SizedBox(height: 24),
                    _buildSymptomsCard(),
                    const SizedBox(height: 24),
                    _buildNoteCard(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
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
      decoration: const BoxDecoration(color: Color(0xFFFDFDFD)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1E293B), size: 20),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ghi nhận hôm nay',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                SizedBox(height: 4),
                Text(
                  'Hãy trung thực với bản thân nhé!',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCigarettesCard() {
    final isZero = _cigarettesSmoked == 0;
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.smoke, color: Color(0xFF6B4EFF), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Số điếu đã hút hôm nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              _cigarettesSmoked.toInt().toString(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: isZero ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: isZero ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
              inactiveTrackColor: const Color(0xFFF1F5F9),
              thumbColor: isZero ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
              overlayColor: (isZero ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: _cigarettesSmoked,
              min: 0,
              max: 50,
              divisions: 50,
              onChanged: (val) => setState(() => _cigarettesSmoked = val),
            ),
          ),
          if (isZero)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.star_fill, color: Color(0xFF10B981), size: 14),
                  SizedBox(width: 8),
                  Text('Tuyệt vời! Bạn đang giữ vững phong độ.', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard({
    required String title,
    required IconData icon,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF6B4EFF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: options.map((opt) {
              final isSelected = selectedValue == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6B4EFF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? const Color(0xFF6B4EFF) : const Color(0xFFE2E8F0)),
                      boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.thermometer, color: Color(0xFF6B4EFF), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Triệu chứng (nếu có)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableSymptoms.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) _selectedSymptoms.remove(symptom);
                    else _selectedSymptoms.add(symptom);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6B4EFF).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFF6B4EFF) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    symptom,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6B4EFF) : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.pencil, color: Color(0xFF6B4EFF), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Ghi chú thêm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhật ký của bạn...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitCheckin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4EFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Lưu nhật ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
