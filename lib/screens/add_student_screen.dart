import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stream_model.dart';
import '../services/firestore_service.dart';
import '../services/csv_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final FirestoreService _firestoreService = FirestoreService();

  List<StreamModel> _streams = [];
  String? _selectedStream;
  bool _isLoadingStreams = true;
  bool _isSaving = false;
  bool _canAddManually = true;
  bool _canImportCsv = false;
  bool _isImportingCsv = false;

  @override
  void initState() {
    super.initState();
    _loadStreams();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Super admin gets all permissions
    if (user.email != null && AuthService.superAdminEmails.contains(user.email!.toLowerCase())) {
      setState(() { _canAddManually = true; _canImportCsv = true; });
      return;
    }

    final perms = await FirestoreService().getTeacherPermissions(user.uid);
    if (perms != null && mounted) {
      setState(() {
        _canAddManually = perms['canAddManually'] is bool ? perms['canAddManually'] as bool : true;
        _canImportCsv = perms['canImportCsv'] is bool ? perms['canImportCsv'] as bool : false;
      });
    }
  }

  Future<void> _handleCsvImport() async {
    if (_selectedStream == null || _selectedStream!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a stream first')),
      );
      return;
    }
    setState(() => _isImportingCsv = true);
    try {
      final csvContent = await CsvService.pickAndReadCsvFile();
      if (csvContent == null) { setState(() => _isImportingCsv = false); return; }

      final rows = CsvService.parseCsv(csvContent);
      if (rows.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV file is empty or has no valid rows.')));
        setState(() => _isImportingCsv = false);
        return;
      }

      final count = await _firestoreService.addStudentsBatch(_selectedStream!, rows);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count students imported!'), backgroundColor: AppColors.present),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImportingCsv = false);
    }
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoadingStreams = true);
    try {
      final streams = await _firestoreService.getStreams();
      if (mounted) {
        setState(() {
          _streams = streams;
          if (streams.isNotEmpty && (_selectedStream == null || !_streams.any((s) => s.id == _selectedStream))) {
            _selectedStream = streams.first.id;
          }
          _isLoadingStreams = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStreams = false);
    }
  }

  String _formatStreamName(StreamModel s) {
    String year = '';
    if (s.semester == '1' || s.semester == '2') year = ' 1YR';
    else if (s.semester == '3' || s.semester == '4') year = ' 2YR';
    else if (s.semester == '5' || s.semester == '6') year = ' 3RD YR';
    return year.isNotEmpty ? '${s.name}$year' : s.name;
  }

  Future<void> _handleSaveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStream == null || _selectedStream!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a stream first')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _firestoreService.addStudent(
        _selectedStream!,
        _nameController.text,
        _rollController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student "${_nameController.text}" added!'),
            backgroundColor: AppColors.present,
          ),
        );
        _nameController.clear();
        _rollController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add student: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCsvInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8.w),
            const Expanded(child: Text('CSV Import Guide')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your CSV file must have a header row as the first line.', style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              Text('Required Column:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Text('• name: The student\'s full name.', style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 8.h),
              Text('Optional Columns:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Text('• rollno: The student\'s roll number.\n• stream: The class/stream name.', style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              Text('If a "stream" is provided for a student, it overrides the stream selected in the dropdown. If that stream doesn\'t exist yet, it will be automatically created!', style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic, color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(153))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it!')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showCsvInstructions,
            tooltip: 'CSV Import Instructions',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Student Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Student Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter name' : null,
                ),
                SizedBox(height: 18.h),

                // Roll Number
                TextFormField(
                  controller: _rollController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Student Roll number',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter roll number' : null,
                ),
                SizedBox(height: 18.h),

                // Stream Dropdown
                _isLoadingStreams
                    ? Center(child: Padding(padding: EdgeInsets.all(12.w), child: const CircularProgressIndicator()))
                    : _streams.isEmpty
                        ? Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.deleteRed.withAlpha(25),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.deleteRed.withAlpha(75)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.deleteRed),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    'No streams found! Please create a class from the Admin Panel first.',
                                    style: TextStyle(color: AppColors.deleteRed, fontSize: 13.sp),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardBorderDark : AppColors.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _streams.any((s) => s.id == _selectedStream) ? _selectedStream : null,
                                hint: const Text('Select Stream'),
                                isExpanded: true,
                                items: _streams.map((s) => DropdownMenuItem(value: s.id, child: Text(_formatStreamName(s)))).toList(),
                                onChanged: (val) => setState(() => _selectedStream = val),
                              ),
                            ),
                          ),
                SizedBox(height: 18.h),

                // Stream Year
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter Stream Year',
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                ),
                SizedBox(height: 32.h),

                // Save Button
                if (_canAddManually)
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.present,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 22.w,
                            height: 22.h,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('SAVE', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder.withAlpha(50),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'You do not have permission to add students manually.',
                      style: TextStyle(color: AppColors.deleteRed, fontSize: 13.sp),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // CSV Import Button (if permitted)
                if (_canImportCsv) ...[
                  SizedBox(height: 16.h),
                  OutlinedButton.icon(
                    onPressed: _isImportingCsv ? null : _handleCsvImport,
                    icon: _isImportingCsv
                        ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload_file),
                    label: Text(_isImportingCsv ? 'Importing...' : 'Import from CSV'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
