import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class BookingDoctorScreen extends StatefulWidget {
  const BookingDoctorScreen({super.key});

  @override
  State<BookingDoctorScreen> createState() => _BookingDoctorScreenState();
}

class _BookingDoctorScreenState extends State<BookingDoctorScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading = false;
  bool isFetchingSlots = false;
  List<DateTime> _bookedSlots = [];

  final List<TimeOfDay> _availableSlots = const [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 8, minute: 45),
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 10, minute: 15),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 11, minute: 45),
    TimeOfDay(hour: 12, minute: 30),
    TimeOfDay(hour: 13, minute: 15),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 14, minute: 45),
    TimeOfDay(hour: 15, minute: 30),
    TimeOfDay(hour: 16, minute: 15),
  ];

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    setState(() {
      isFetchingSlots = true;
      _bookedSlots = [];
    });
    try {
      final slots = await _appointmentService.getBookedSlots(date);
      setState(() {
        _bookedSlots = slots.map((e) => DateTime.parse(e).toLocal()).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lấy khung giờ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isFetchingSlots = false);
    }
  }

  void _book() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày và giờ')),
      );
      return;
    }

    final startTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (startTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian hẹn phải ở tương lai')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await _appointmentService.bookAppointment(startTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lịch thành công!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Chọn thời gian',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerCard(),
                    const SizedBox(height: 32),
                    const Text(
                      'Khung giờ khả dụng (45p)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimeSlots(),
                    const SizedBox(height: 40),
                    _buildConfirmButton(),
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
                  'Đặt lịch',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cùng chuyên gia y tế',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerCard() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
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
        if (date != null) {
          setState(() {
            selectedDate = date;
            selectedTime = null;
          });
          _fetchBookedSlots(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.calendar, color: Color(0xFF6B4EFF)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày khám',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedDate == null ? 'Chưa chọn' : DateFormat('dd/MM/yyyy').format(selectedDate!),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (isFetchingSlots) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final time = _availableSlots[index];
        final isSelected = selectedTime == time;
        
        bool isPast = false;
        bool isBooked = false;
        if (selectedDate != null) {
          final slotDateTime = DateTime(
            selectedDate!.year, selectedDate!.month, selectedDate!.day,
            time.hour, time.minute
          );
          if (slotDateTime.isBefore(DateTime.now())) {
            isPast = true;
          }
          isBooked = _bookedSlots.any((d) => 
            d.year == slotDateTime.year && 
            d.month == slotDateTime.month && 
            d.day == slotDateTime.day && 
            d.hour == slotDateTime.hour && 
            d.minute == slotDateTime.minute
          );
        }

        final isDisabled = selectedDate == null || isPast || isBooked;

        Color bgColor = Colors.white;
        Color textColor = const Color(0xFF64748B);
        Border border = Border.all(color: const Color(0xFFE2E8F0));

        if (isDisabled) {
          bgColor = const Color(0xFFF8FAFC);
          textColor = const Color(0xFFCBD5E1);
          border = Border.all(color: Colors.transparent);
        } else if (isSelected) {
          bgColor = const Color(0xFF6B4EFF);
          textColor = Colors.white;
          border = Border.all(color: const Color(0xFF6B4EFF));
        }

        return GestureDetector(
          onTap: isDisabled ? null : () => setState(() => selectedTime = time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              border: border,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Text(
              isBooked ? 'Đã đặt' : _formatTime(time),
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    final canBook = selectedDate != null && selectedTime != null && !isLoading;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: canBook
            ? [BoxShadow(color: const Color(0xFF6B4EFF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
            : [],
      ),
      child: ElevatedButton(
        onPressed: canBook ? _book : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4EFF),
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: isLoading 
            ? const SizedBox(
                width: 24, height: 24, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : const Text('Xác nhận đặt lịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
