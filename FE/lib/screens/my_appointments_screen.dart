import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/appointment_service.dart';
import 'booking_doctor_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  List<dynamic> upcomingAppointments = [];
  List<dynamic> pastAppointments = [];
  bool isLoading = true;

  bool showAllUpcoming = false;
  bool showAllPast = false;
  
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => isLoading = true);
    try {
      final data = await _appointmentService.getAppointments();
      setState(() {
        upcomingAppointments = [];
        pastAppointments = [];
        for (var apt in data) {
          final endTime = DateTime.parse(apt['endTime']).toLocal();
          final isExpired = DateTime.now().isAfter(endTime);
          final isCompleted = apt['status'] == 'completed' || isExpired;
          if (isCompleted) {
            pastAppointments.add(apt);
          } else {
            upcomingAppointments.add(apt);
          }
        }
        upcomingAppointments.sort((a, b) => DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));
        pastAppointments.sort((a, b) => DateTime.parse(b['startTime']).compareTo(DateTime.parse(a['startTime'])));
      });
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

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở link cuộc họp')),
        );
      }
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
            _buildTabs(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)))
                  : (_activeTabIndex == 0 
                      ? _buildTabContent(upcomingAppointments, showAllUpcoming, (val) => setState(() => showAllUpcoming = val))
                      : _buildTabContent(pastAppointments, showAllPast, (val) => setState(() => showAllPast = val))),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookingDoctorScreen()),
          );
          if (result == true) {
            _loadAppointments();
          }
        },
        backgroundColor: const Color(0xFF6B4EFF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: const Text('Đặt lịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(CupertinoIcons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFD),
      ),
      child: Row(
        children: [
          if (canPop)
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
            )
          else
            const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch hẹn của tôi',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý lịch tư vấn y tế',
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

  Widget _buildTabs() {
    final tabs = ['Sắp diễn ra', 'Đã kết thúc'];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _activeTabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isActive
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: isActive ? const Color(0xFF6B4EFF) : const Color(0xFF64748B),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.calendar_today, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Trống trải quá!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn chưa có lịch hẹn nào ở đây.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<dynamic> list, bool showAll, Function(bool) onToggleShowAll) {
    if (list.isEmpty) return _buildEmptyState();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), // extra padding for FAB
      child: Column(
        children: [
          _buildAppointmentGroup(list, showAll, onToggleShowAll),
        ],
      ),
    );
  }

  Widget _buildAppointmentGroup(List<dynamic> list, bool showAll, Function(bool) onToggleShowAll) {
    final displayList = showAll ? list : list.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...displayList.map((apt) => _buildAppointmentCard(apt)),
        if (list.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () => onToggleShowAll(!showAll),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B4EFF),
              ),
              child: Text(
                showAll ? 'Thu gọn' : 'Xem thêm (${list.length - 5})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(dynamic apt) {
    final startTime = DateTime.parse(apt['startTime']).toLocal();
    final endTime = DateTime.parse(apt['endTime']).toLocal();
    final meetLink = apt['meetLink'];
    final isExpired = DateTime.now().isAfter(endTime);
    final isCompleted = apt['status'] == 'completed' || isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(startTime),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.clock, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFF1F5F9) : const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'Đã xong' : 'Sắp diễn ra',
                  style: TextStyle(
                    color: isCompleted ? const Color(0xFF64748B) : const Color(0xFF6B4EFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (meetLink != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompleted ? null : () => _launchUrl(meetLink),
                icon: Icon(CupertinoIcons.video_camera_solid, size: 18, color: isCompleted ? const Color(0xFF94A3B8) : Colors.white),
                label: Text(
                  isCompleted ? 'Cuộc họp đã kết thúc' : 'Tham gia Google Meet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? const Color(0xFF94A3B8) : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                  disabledBackgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
