import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../routes/app_routes.dart';

class SmokingStatusScreen extends StatefulWidget {
  const SmokingStatusScreen({super.key});

  @override
  State<SmokingStatusScreen> createState() => _SmokingStatusScreenState();
}

class _SmokingStatusScreenState extends State<SmokingStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _cigarettesPerDayController;
  late TextEditingController _smokingYearsController;
  late TextEditingController _quitDateController;
  
  DateTime? _selectedQuitDate;
  String _morningCravingLevel = "Thấp";
  String _quitReason = "Sức khỏe";
  bool _isLoading = false;
  bool _isViewOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('isViewOnly')) {
      _isViewOnly = args['isViewOnly'];
    }
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final smokingProfile = user?['smokingProfile'] ?? {};
    
    _cigarettesPerDayController = TextEditingController(
      text: (smokingProfile['cigarettesPerDay'] ?? 0).toString(),
    );
    _smokingYearsController = TextEditingController(
      text: (smokingProfile['smokingYears'] ?? 0).toString(),
    );
    if (smokingProfile['quitDate'] != null) {
      _selectedQuitDate = DateTime.parse(smokingProfile['quitDate']);
    } else {
      _selectedQuitDate = DateTime.now();
    }
    
    _quitDateController = TextEditingController(
      text: "${_selectedQuitDate!.day}/${_selectedQuitDate!.month}/${_selectedQuitDate!.year}",
    );
    
    if (smokingProfile['morningCravingLevel'] != null && smokingProfile['morningCravingLevel'] != "") {
      _morningCravingLevel = smokingProfile['morningCravingLevel'];
    }
    
    if (smokingProfile['quitReason'] != null && smokingProfile['quitReason'] != "") {
      _quitReason = smokingProfile['quitReason'];
    }
  }

  @override
  void dispose() {
    _cigarettesPerDayController.dispose();
    _smokingYearsController.dispose();
    _quitDateController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    if (_isViewOnly) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedQuitDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B4EFF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedQuitDate) {
      setState(() {
        _selectedQuitDate = picked;
        _quitDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final smokingProfile = {
      'cigarettesPerDay': int.tryParse(_cigarettesPerDayController.text) ?? 0,
      'smokingYears': int.tryParse(_smokingYearsController.text) ?? 0,
      'quitDate': _selectedQuitDate?.toIso8601String(),
      'morningCravingLevel': _morningCravingLevel,
      'quitReason': _quitReason,
    };

    final success = await authProvider.updateProfile(
      fullname: user?['fullname'] ?? '',
      phone: user?['phone'] ?? '',
      smokingProfile: smokingProfile,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thông tin thành công'), backgroundColor: Color(0xFF10B981)));
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.planSelection);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.errorMessage ?? 'Có lỗi xảy ra'), backgroundColor: const Color(0xFFF43F5E)));
    }
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMainCard(),
                      if (!_isViewOnly) ...[
                        const SizedBox(height: 40),
                        _buildSaveButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 16),
      decoration: const BoxDecoration(color: Color(0xFFFDFDFD)),
      child: Row(
        children: [
          if (canPop)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1E293B), size: 20),
              ),
            )
          else
            const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tình trạng hút thuốc',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                SizedBox(height: 4),
                Text(
                  'Giúp chúng tôi cá nhân hóa kế hoạch',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            label: 'Số điếu mỗi ngày',
            controller: _cigarettesPerDayController,
            icon: CupertinoIcons.flame,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập số lượng';
              final number = int.tryParse(value);
              if (number == null) return 'Vui lòng nhập số hợp lệ';
              if (number < 0) return 'Số lượng không được âm';
              if (number > 100) return 'Tối đa 100 điếu/ngày';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Số năm hút thuốc',
            controller: _smokingYearsController,
            icon: CupertinoIcons.calendar,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập số năm';
              final number = int.tryParse(value);
              if (number == null) return 'Vui lòng nhập số hợp lệ';
              if (number < 0) return 'Số năm không được âm';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildDropdownField(
            label: 'Mức độ thèm thuốc buổi sáng',
            value: _morningCravingLevel,
            items: ["Thấp", "Trung bình", "Cao"],
            icon: CupertinoIcons.sun_max,
            onChanged: (val) {
              if (val != null) setState(() => _morningCravingLevel = val);
            },
          ),
          const SizedBox(height: 24),
          _buildDropdownField(
            label: 'Lý do muốn cai thuốc',
            value: _quitReason,
            items: ["Sức khỏe", "Tài chính", "Gia đình", "Khác"],
            icon: CupertinoIcons.heart,
            onChanged: (val) {
              if (val != null) setState(() => _quitReason = val);
            },
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: _buildInputField(
                label: 'Ngày bắt đầu cai',
                controller: _quitDateController,
                icon: CupertinoIcons.flag,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            readOnly: _isViewOnly,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: _isViewOnly ? null : onChanged,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            ),
            dropdownColor: Colors.white,
            icon: const Icon(CupertinoIcons.chevron_down, color: Color(0xFF94A3B8), size: 18),
            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontFamily: 'sans-serif'),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4EFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Lưu thông tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
