import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/date_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gauge_chart.dart';

class MonthlyCalendarScreen extends StatefulWidget {
  final StudentModel student;

  const MonthlyCalendarScreen({
    super.key,
    required this.student,
  });

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late DateTime _selectedMonth;
  bool _isLoading = true;

  int _presentCount = 0;
  int _absentCount = 0;
  int _holidayCount = 0;
  double _percentage = 0.0;
  List<DateModel> _calendarDays = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadMonthData();
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _firestoreService.fetchMonthlyAttendance(
        streamId: widget.student.streamId.isNotEmpty ? widget.student.streamId : widget.student.stream,
        studentId: widget.student.docId.isNotEmpty ? widget.student.docId : widget.student.rollno,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      if (mounted) {
        setState(() {
          _presentCount = data['presentCount'] as int;
          _absentCount = data['absentCount'] as int;
          _holidayCount = data['holidayCount'] as int;
          _percentage = data['percentage'] as double;
          _calendarDays = data['calendarDays'] as List<DateModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadMonthData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadMonthData();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.present;
      case 'absent':
        return AppColors.absent;
      case 'holiday':
        return AppColors.holiday;
      default:
        return Colors.transparent;
    }
  }

  Color _getTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'absent':
      case 'holiday':
        return Colors.white;
      default:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final firstDayOfWeek = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Monthly Attendance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Student Name & Roll Number
              Text(
                widget.student.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Roll No: ${widget.student.rollno} | ${widget.student.stream}',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Month Navigator Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status Summary Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatBadge('Present', _presentCount, AppColors.present),
                  _buildStatBadge('Absent', _absentCount, AppColors.absent),
                  _buildStatBadge('Holiday', _holidayCount, AppColors.holiday),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Weekday Headers
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _WeekdayHeader('Sun'),
                    _WeekdayHeader('Mon'),
                    _WeekdayHeader('Tue'),
                    _WeekdayHeader('Wed'),
                    _WeekdayHeader('Thu'),
                    _WeekdayHeader('Fri'),
                    _WeekdayHeader('Sat'),
                  ],
                ),
                const SizedBox(height: 12),

                // Calendar Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: firstDayOfWeek + _calendarDays.length,
                  itemBuilder: (context, index) {
                    if (index < firstDayOfWeek) {
                      return const SizedBox();
                    }
                    final dayModel = _calendarDays[index - firstDayOfWeek];
                    final bgColor = _getStatusColor(dayModel.status);
                    final txtColor = _getTextColor(dayModel.status);

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: bgColor == Colors.transparent
                            ? Border.all(color: AppColors.cardBorder.withAlpha(128))
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${dayModel.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: txtColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Attendance Gauge & %
                AttendanceGaugeChart(percentage: _percentage),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(77),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String text;
  const _WeekdayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
