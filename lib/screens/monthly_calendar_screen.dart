import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/date_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gauge_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ViewMode { monthly, semester1, semester2, yearly }

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
  ViewMode _viewMode = ViewMode.monthly;

  bool _isLoading = true;

  int _presentCount = 0;
  int _absentCount = 0;
  int _holidayCount = 0;
  double _percentage = 0.0;
  List<DateModel> _calendarDays = [];
  List<Map<String, dynamic>> _monthlyBreakdown = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_viewMode == ViewMode.monthly) {
      await _loadMonthData();
    } else {
      await _loadAggregatedData();
    }
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
          _monthlyBreakdown = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAggregatedData() async {
    setState(() => _isLoading = true);
    try {
      List<int> monthsToFetch = [];
      if (_viewMode == ViewMode.yearly) {
        monthsToFetch = List.generate(12, (index) => index + 1);
      } else if (_viewMode == ViewMode.semester1) {
        monthsToFetch = [1, 2, 3, 4, 5, 6];
      } else if (_viewMode == ViewMode.semester2) {
        monthsToFetch = [7, 8, 9, 10, 11, 12];
      }

      final data = await _firestoreService.fetchAggregatedAttendance(
        streamId: widget.student.streamId.isNotEmpty ? widget.student.streamId : widget.student.stream,
        studentId: widget.student.docId.isNotEmpty ? widget.student.docId : widget.student.rollno,
        year: _selectedMonth.year,
        months: monthsToFetch,
      );

      if (mounted) {
        setState(() {
          _presentCount = data['presentCount'] as int;
          _absentCount = data['absentCount'] as int;
          _holidayCount = data['holidayCount'] as int;
          _percentage = data['percentage'] as double;
          _monthlyBreakdown = data['monthlyBreakdown'] as List<Map<String, dynamic>>;
          _calendarDays = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousPeriod() {
    setState(() {
      if (_viewMode == ViewMode.monthly) {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month);
      }
    });
    _loadData();
  }

  void _nextPeriod() {
    setState(() {
      if (_viewMode == ViewMode.monthly) {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month);
      }
    });
    _loadData();
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
    final periodLabel = _viewMode == ViewMode.monthly
        ? DateFormat('MMMM yyyy').format(_selectedMonth)
        : _selectedMonth.year.toString();
    
    final firstDayOfWeek = _viewMode == ViewMode.monthly 
        ? DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7 
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Details'),
        actions: [
          PopupMenuButton<ViewMode>(
            initialValue: _viewMode,
            onSelected: (ViewMode newSelection) {
              setState(() {
                _viewMode = newSelection;
              });
              _loadData();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<ViewMode>>[
              const PopupMenuItem<ViewMode>(
                value: ViewMode.monthly,
                child: Text('Monthly'),
              ),
              const PopupMenuItem<ViewMode>(
                value: ViewMode.semester1,
                child: Text('Semester 1'),
              ),
              const PopupMenuItem<ViewMode>(
                value: ViewMode.semester2,
                child: Text('Semester 2'),
              ),
              const PopupMenuItem<ViewMode>(
                value: ViewMode.yearly,
                child: Text('Yearly'),
              ),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    _getViewModeLabel(_viewMode),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.keyboard_arrow_down, size: 20.sp),
                ],
              ),
            ),
          ),
        ],
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
                style: TextStyle(fontSize: 16.sp, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
              SizedBox(height: 24.h),



              // Navigator Bar
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
                      onPressed: _previousPeriod,
                    ),
                    Text(
                      periodLabel,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20.sp),
                      onPressed: _nextPeriod,
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
                if (_viewMode == ViewMode.monthly) ...[
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
                ] else ...[
                  // Monthly Breakdown List
                  Text('Monthly Breakdown', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  ..._monthlyBreakdown.map((m) {
                    final mName = DateFormat('MMMM').format(DateTime(2020, m['month']));
                    final mPct = m['percentage'] as double;
                    final hasData = m['hasData'] as bool;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.cardBorder.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(mName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                          Text(
                            hasData ? '${mPct.toStringAsFixed(1)}%' : 'No Data',
                            style: TextStyle(
                              fontSize: 16.sp, 
                              fontWeight: FontWeight.bold,
                              color: hasData ? (mPct >= 75 ? AppColors.present : (mPct > 0 ? Colors.orange : AppColors.absent)) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideX();
                  }),
                ],
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

  String _getViewModeLabel(ViewMode mode) {
    switch (mode) {
      case ViewMode.monthly: return 'Monthly';
      case ViewMode.semester1: return 'Sem 1';
      case ViewMode.semester2: return 'Sem 2';
      case ViewMode.yearly: return 'Yearly';
    }
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
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
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
      width: 40.w,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}


