import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../constants/colors.dart';

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
      appBar: AppBar(
        title: const Text('Đặt lịch tư vấn'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn thời gian bạn muốn gặp bác sĩ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
              title: Text(selectedDate == null 
                  ? 'Chọn ngày' 
                  : DateFormat('dd/MM/yyyy').format(selectedDate!)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                    selectedTime = null; // Reset time when date changes
                  });
                  _fetchBookedSlots(date);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Các khung giờ khả dụng (45 phút/ca):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isFetchingSlots 
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _availableSlots.length,
                itemBuilder: (context, index) {
                  final time = _availableSlots[index];
                  final isSelected = selectedTime == time;
                  
                  // Disable past slots if selected date is today
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

                  return InkWell(
                    onTap: isDisabled ? null : () {
                      setState(() => selectedTime = time);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue : (isDisabled ? AppColors.lightGrey : AppColors.white),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryBlue : (isDisabled ? AppColors.outlineVariant : AppColors.outline),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isBooked ? 'Đã đặt' : _formatTime(time),
                        style: TextStyle(
                          color: isSelected ? AppColors.white : (isDisabled ? AppColors.textTertiary : AppColors.textPrimary),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : _book,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading 
                  ? const CircularProgressIndicator(color: AppColors.white)
                  : const Text('Xác nhận đặt lịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
