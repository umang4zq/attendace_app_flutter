import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';

import '../providers/attendance_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/student_card.dart';
import 'add_student_screen.dart';
import 'update_student_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  // Floating Action Menu state
  bool _isMenuOpen = false;
  late AnimationController _fabController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack, // Apple-style spring curve
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadData();
    });
  }

  void _markHolidayForClass() {
    _toggleFabMenu();
    context.read<AttendanceProvider>().markHolidayForClass();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as Holiday for selected students! Click Save to confirm.'),
        backgroundColor: AppColors.holiday,
      ),
    );
  }

  void _markAllPresentForClass() {
    _toggleFabMenu();
    context.read<AttendanceProvider>().markAllPresentForClass();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked all as Present! Click Save to confirm.'),
        backgroundColor: AppColors.present,
      ),
    );
  }

  void _markAllAbsentForClass() {
    _toggleFabMenu();
    context.read<AttendanceProvider>().markAllAbsentForClass();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked all as Absent! Click Save to confirm.'),
        backgroundColor: AppColors.absent,
      ),
    );
  }

  Future<void> _saveAttendance() async {
    try {
      await context.read<AttendanceProvider>().saveAttendance(_selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: AppColors.present,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleFabMenu() {
    if (_isMenuOpen) {
      _fabController.reverse();
    } else {
      _fabController.forward();
    }
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<AttendanceProvider>().deleteStudent(student);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final formattedDate = DateFormat('dd-MMM-yy').format(_selectedDate);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(150),
            ),
          ),
        ),
        leadingWidth: 150,
        leading: InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ImageIcon(const AssetImage('assets/images/calendar_icon.png'), color: AppColors.primary, size: 22.sp),
                SizedBox(width: 8.w),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color ?? AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        title: Image.asset('assets/images/logo2.png', height: 50.h),
        actions: [
          IconButton(
            icon: provider.isSaving
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save_rounded, color: AppColors.primary, size: 26.sp),
            onPressed: provider.isSaving ? null : _saveAttendance,
            tooltip: 'Save Attendance',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadData,
        color: AppColors.primary,
        child: Column(
          children: [
            // Filter Bar (Search & Stream Dropdown)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: Row(
                children: [
                  // Search Box
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 46.h,
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(23.r),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => provider.setSearchQuery(val),
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search student...',
                          hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
                          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20.sp),
                          prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(right: 16.w),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Stream Dropdown
                  Expanded (
                    flex: 2,
                    child: Container(
                      height: 46.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(23.r),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.filterOptions.contains(provider.selectedStream) ? provider.selectedStream : (provider.selectedStream == 'All' ? 'All' : null),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500),
                          dropdownColor: Theme.of(context).cardColor,
                          items: provider.filterOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setSelectedStream(val);
                          }
                        },
                      ),
                    ),
                  ),
                  )
                ],
              ),
            ),

            // Student Roster List
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64.sp, color: AppColors.textMuted.withValues(alpha: 0.5)),
                              SizedBox(height: 12.h),
                              Text(
                                'No students found',
                                style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
                              ),
                              SizedBox(height: 4.h),
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddStudentScreen()),
                                  );
                                  provider.loadData();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Student'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          itemCount: provider.filteredStudents.length,
                          padding: EdgeInsets.only(
                            top: 4.h,
                            bottom: 90.h,
                          ),
                          itemBuilder: (context, index) {
                            final student = provider.filteredStudents[index];
                            return StudentCard(
                              student: student,
                              onToggleStatus: () => provider.toggleStudentStatus(index),
                              onMarkPresent: () => provider.markStudentPresent(index),
                              onMarkAbsent: () => provider.markStudentAbsent(index),
                              onDelete: () => _deleteStudent(student),
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateStudentScreen(student: student),
                                  ),
                                );
                                provider.loadData();
                              },
                            ).animate(delay: (50 * index).ms)
                             .fadeIn(duration: 400.ms)
                             .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + -40.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sub-button: Mark All Absent
          ScaleTransition(
            scale: _expandAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: Text('Mark All Absent', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                ),
                SizedBox(width: 8.w),
                FloatingActionButton.small(
                  heroTag: 'absent_btn',
                  backgroundColor: AppColors.absent,
                  onPressed: _markAllAbsentForClass,
                  child: Icon(Icons.close, color: Colors.white, size: 22.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          
          // Sub-button: Mark All Present
          ScaleTransition(
            scale: _expandAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: Text('Mark All Present', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                ),
                SizedBox(width: 8.w),
                FloatingActionButton.small(
                  heroTag: 'present_btn',
                  backgroundColor: AppColors.present,
                  onPressed: _markAllPresentForClass,
                  child: Icon(Icons.check, color: Colors.white, size: 22.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Sub-button: Mark Holiday
          ScaleTransition(
            scale: _expandAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: Text('Holiday', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                ),
                SizedBox(width: 8.w),
                FloatingActionButton.small(
                  heroTag: 'holiday_btn',
                  backgroundColor: AppColors.holiday,
                  onPressed: _markHolidayForClass,
                  child: ImageIcon(const AssetImage('assets/images/holiday_ic.png'), color: Colors.white, size: 22.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),


          // Main Trigger FAB
          FloatingActionButton(
            heroTag: 'main_fab',
            backgroundColor: AppColors.primary,
            onPressed: _toggleFabMenu,
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.125).animate(_expandAnimation),
              child: ImageIcon(const AssetImage('assets/images/plus_fab.png'), color: Colors.white, size: 28.sp),
            ),
          ),
        ],
      ),
    ),
  );
}
}
