import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/stream_model.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<StreamModel> _streams = [];
  String? _selectedStream;
  DateTime _fromMonth = DateTime(DateTime.now().year, DateTime.now().month > 3 ? DateTime.now().month - 3 : 1);
  DateTime _toMonth = DateTime.now();

  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoading = true);
    try {
      final streams = await _firestoreService.getStreams();
      if (mounted) {
        setState(() {
          _streams = streams;
          if (streams.isNotEmpty) {
            _selectedStream = streams.first.name;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMonth({required bool isFrom}) async {
    final initialDate = isFrom ? _fromMonth : _toMonth;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: isFrom ? 'Select Start Month' : 'Select End Month',
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromMonth = DateTime(picked.year, picked.month);
        } else {
          _toMonth = DateTime(picked.year, picked.month);
        }
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedStream == null || _selectedStream!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stream first')),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);
    try {
      final studentsData = await _firestoreService.fetchAttendanceReportData(
        streamId: _selectedStream!,
        fromDate: _fromMonth,
        toDate: _toMonth,
      );

      if (studentsData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attendance records found for selected criteria')),
          );
        }
        return;
      }

      final fromStr = DateFormat('yyyy-MM').format(_fromMonth);
      final toStr = DateFormat('yyyy-MM').format(_toMonth);

      final pdfBytes = await PdfService.generateAttendancePdf(
        streamName: _selectedStream!,
        fromMonth: fromStr,
        toMonth: toStr,
        studentsData: studentsData,
      );

      await PdfService.shareOrPrintPdf(
        pdfBytes,
        'Attendance_${_selectedStream}_$fromStr-$toStr.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fromMonthStr = DateFormat('yyyy-MM').format(_fromMonth);
    final toMonthStr = DateFormat('yyyy-MM').format(_toMonth);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final cardBgColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.cardBorder;
    final headerBgColor = isDark ? AppColors.cardDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile & Reports'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              final isDarkTheme = currentMode == ThemeMode.dark ||
                  (currentMode == ThemeMode.system &&
                      Theme.of(context).brightness == Brightness.dark);
              return IconButton(
                icon: Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeNotifier.value = isDarkTheme ? ThemeMode.light : ThemeMode.dark;
                },
                tooltip: 'Toggle Theme',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Account Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: headerBgColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: isDark ? Border.all(color: borderColor) : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 32.sp),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructor Account',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            user?.email ?? 'instructor@school.edu',
                            style: TextStyle(fontSize: 13.sp, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Title Section
              Text(
                'Export Attendance Report',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Generate attendance PDF by selecting stream and month range',
                style: TextStyle(fontSize: 14.sp, color: subTextColor),
              ),
              SizedBox(height: 28.h),

              // Stream Selection
              Text(
                'Select Stream',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              SizedBox(height: 8.h),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _streams.any((s) => s.name == _selectedStream) ? _selectedStream : null,
                          hint: Text('Select Stream', style: TextStyle(color: subTextColor)),
                          isExpanded: true,
                          dropdownColor: cardBgColor,
                          style: TextStyle(color: textColor, fontSize: 16.sp),
                          items: _streams.map((s) => s.name).toSet().map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                          onChanged: (val) => setState(() => _selectedStream = val),
                        ),
                      ),
                    ),
              SizedBox(height: 24.h),

              // Date Range Selectors
              Row(
                children: [
                  // From Month
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Month',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: () => _pickMonth(isFrom: true),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(fromMonthStr, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                Icon(Icons.arrow_drop_down, color: subTextColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // To Month
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To Month',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: () => _pickMonth(isFrom: false),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(toMonthStr, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                Icon(Icons.arrow_drop_down, color: subTextColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 36.h),

              // Export Button
              ElevatedButton.icon(
                onPressed: _isGeneratingPdf ? null : _exportPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: _isGeneratingPdf
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text('Export PDF', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 16.h),

              // Logout Button
              OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.deleteRed,
                  side: const BorderSide(color: AppColors.deleteRed),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('LOGOUT', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
