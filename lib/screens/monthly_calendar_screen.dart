import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/date_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gauge_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  Color _getTextColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'absent':
      case 'holiday':
        return Colors.white;
      default:
        return Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final firstDayOfWeek = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Attendance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Student Name & Roll Number
              Text(
                widget.student.name,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
              SizedBox(height: 8.h),
              Text(
                'Roll No: ${widget.student.rollno} | ${widget.student.stream}${widget.student.semester.isNotEmpty ? ' (Sem ${widget.student.semester})' : ''}',
                style: TextStyle(fontSize: 16.sp, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
              SizedBox(height: 32.h),

              // Month Navigator Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      monthName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20.sp),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Status Summary Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatBadge('Present', _presentCount, AppColors.present).animate(delay: 200.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
                  _buildStatBadge('Absent', _absentCount, AppColors.absent).animate(delay: 300.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
                  _buildStatBadge('Holiday', _holidayCount, AppColors.holiday).animate(delay: 400.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),
                ],
              ),
              SizedBox(height: 24.h),

              if (_isLoading)
                Padding(
                  padding: EdgeInsets.all(60.w),
                  child: const Center(child: CircularProgressIndicator()),
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
                SizedBox(height: 12.h),

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
                    Color bgColor = _getStatusColor(dayModel.status);
                    Color txtColor = _getTextColor(context, dayModel.status);

                    if (index % 7 == 0) {
                      bgColor = Colors.amber;
                      txtColor = Colors.white;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: bgColor == Colors.transparent
                            ? Border.all(color: AppColors.cardBorder.withAlpha(128))
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${dayModel.day}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: txtColor,
                        ),
                      ),
                    ).animate(delay: (20 * index).ms).fadeIn(duration: 300.ms).scale(curve: Curves.easeOutBack);
                  },
                ),
                SizedBox(height: 32.h),

                // Attendance Gauge & %
                AttendanceGaugeChart(percentage: _percentage)
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
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
          width: 54.w,
          height: 54.h,
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String text;
  final Color? color;
  const _WeekdayHeader(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.w,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: color ?? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
    );
  }
}
