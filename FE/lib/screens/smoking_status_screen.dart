import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedQuitDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
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

    setState(() {
      _isLoading = true;
    });

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

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công'),
          backgroundColor: AppColors.success,
        ),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.planSelection);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tình trạng hút thuốc'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin hiện tại',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cập nhật thông tin để ứng dụng có thể theo dõi và tính toán tiền tiết kiệm cho bạn.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              _buildInputField(
                label: 'Số lượng điếu thuốc mỗi ngày',
                controller: _cigarettesPerDayController,
                keyboardType: TextInputType.number,
                icon: Icons.smoking_rooms,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  final number = int.tryParse(value);
                  if (number == null) return 'Vui lòng nhập số hợp lệ';
                  if (number < 0) return 'Số lượng không được âm';
                  if (number > 100) return 'Số lượng tối đa là 100 điếu/ngày';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildInputField(
                label: 'Số năm hút thuốc',
                controller: _smokingYearsController,
                keyboardType: TextInputType.number,
                icon: Icons.calendar_today,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số năm';
                  }
                  final number = int.tryParse(value);
                  if (number == null) return 'Vui lòng nhập số hợp lệ';
                  if (number < 0) return 'Số năm không được âm';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              _buildDropdownField(
                label: 'Mức độ thèm thuốc buổi sáng',
                value: _morningCravingLevel,
                items: ["Thấp", "Trung bình", "Cao"],
                icon: Icons.wb_sunny,
                onChanged: (val) {
                  if (val != null) setState(() => _morningCravingLevel = val);
                },
              ),
              const SizedBox(height: 20),
              
              _buildDropdownField(
                label: 'Lý do chính muốn cai thuốc',
                value: _quitReason,
                items: ["Sức khỏe", "Tài chính", "Gia đình", "Khác"],
                icon: Icons.favorite,
                onChanged: (val) {
                  if (val != null) setState(() => _quitReason = val);
                },
              ),
              const SizedBox(height: 20),
              
              GestureDetector(
                onTap: _isViewOnly ? null : () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildInputField(
                    label: 'Ngày bắt đầu cai thuốc',
                    controller: _quitDateController,
                    icon: Icons.event,
                  ),
                ),
              ),
              
              if (!_isViewOnly) ...[
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Lưu thông tin',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: _isViewOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger),
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: _isViewOnly ? null : onChanged,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
