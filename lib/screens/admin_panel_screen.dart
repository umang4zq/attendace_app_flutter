import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/firestore_service.dart';
import '../services/csv_service.dart';
import '../services/auth_service.dart';
import '../models/student_model.dart';
import '../models/stream_model.dart';
import '../theme/app_colors.dart';
import 'add_student_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  // --- Tab 1: Teachers ---
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoadingTeachers = true;

  // --- Tab 2: Data Management ---
  List<StreamModel> _streams = [];
  Map<String, List<StudentModel>> _studentsByStream = {};
  bool _isLoadingData = true;
  String? _expandedStream;

  // --- Tab 3: CSV ---
  List<StreamModel> _csvStreams = [];
  String? _csvSelectedStream;
  List<Map<String, String>> _csvPreviewRows = [];
  bool _isImporting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeachers();
    _loadData();
    _loadCsvStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ========== Tab 1: Teachers ==========

  Future<void> _loadTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      final teachers = await _firestoreService.getAllTeachers();
      if (mounted) setState(() { _teachers = teachers; _isLoadingTeachers = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _togglePermission(String uid, String field, bool value) async {
    try {
      if (field == 'canAddManually') {
        await _firestoreService.setTeacherPermissions(uid, canAddManually: value);
      } else {
        await _firestoreService.setTeacherPermissions(uid, canImportCsv: value);
      }
      _loadTeachers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteTeacher(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Remove permissions for "$email"?\nThey will lose all access controls.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteTeacherDoc(uid);
      _loadTeachers();
    }
  }

  // ========== Tab 2: Data Management ==========

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final streams = await _firestoreService.getStreams();
      final Map<String, List<StudentModel>> map = {};
      for (var s in streams) {
        map[s.name] = await _firestoreService.fetchStudentsByStream(s.name);
      }
      if (mounted) {
        setState(() {
          _streams = streams;
          _studentsByStream = map;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _showAddStreamDialog() async {
    final nameController = TextEditingController();
    final yearController = TextEditingController(text: DateTime.now().year.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Stream'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Stream Name (e.g. BCA2024)'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sName = nameController.text.trim();
              if (sName.isNotEmpty) {
                await _firestoreService.addStream(sName, yearController.text);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                _loadData();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStreamAdmin(String streamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Stream'),
        content: Text('Delete "$streamId" and ALL its students permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteStream(streamId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stream deleted.')));
      }
    }
  }

  Future<void> _deleteStudentAdmin(StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Delete "${student.name}" (Roll: ${student.rollno}) permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteStudent(
        student.streamId.isNotEmpty ? student.streamId : student.stream,
        student.docId,
      );
      _loadData();
    }
  }

  // ========== Tab 3: CSV ==========

  Future<void> _loadCsvStreams() async {
    final streams = await _firestoreService.getStreams();
    if (mounted) {
      setState(() {
        _csvStreams = streams;
        if (streams.isNotEmpty && _csvSelectedStream == null) {
          _csvSelectedStream = streams.first.name;
        }
      });
    }
  }

  Future<void> _pickCsvFile() async {
    try {
      final csvContent = await CsvService.pickAndReadCsvFile();
      if (csvContent == null) return;

      final rows = CsvService.parseCsv(csvContent);
      if (mounted) {
        setState(() => _csvPreviewRows = rows);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Error: $e')));
      }
    }
  }

  Future<void> _importCsvStudents() async {
    if (_csvSelectedStream == null || _csvPreviewRows.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final count = await _firestoreService.addStudentsBatch(_csvSelectedStream!, _csvPreviewRows);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count students imported to $_csvSelectedStream!'), backgroundColor: AppColors.present),
        );
        setState(() => _csvPreviewRows = []);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_csvSelectedStream == null) return;

    setState(() => _isExporting = true);
    try {
      final students = await _firestoreService.fetchStudentsByStream(_csvSelectedStream!);
      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No students found in this stream.')),
          );
        }
        return;
      }
      final csv = CsvService.generateCsv(students);
      await CsvService.shareCsvFile(csv, 'students_$_csvSelectedStream.csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ========== BUILD ==========

  void _showCsvInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.cardBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showCsvInstructions,
            tooltip: 'CSV Import Instructions',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(153),
          indicatorColor: AppColors.primary,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Teachers'),
            Tab(icon: Icon(Icons.storage), text: 'Data'),
            Tab(icon: Icon(Icons.file_copy), text: 'CSV'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeachersTab(cardBg, borderColor),
          _buildDataTab(cardBg, borderColor),
          _buildCsvTab(cardBg, borderColor),
        ],
      ),
    );
  }

  // ---------- Tab 1: Teachers ----------

  Widget _buildTeachersTab(Color cardBg, Color borderColor) {
    if (_isLoadingTeachers) return const Center(child: CircularProgressIndicator());

    if (_teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64.sp, color: AppColors.textMuted),
            SizedBox(height: 12.h),
            Text('No teachers registered yet', style: TextStyle(fontSize: 16.sp, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeachers,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _teachers.length,
        itemBuilder: (context, index) {
          final t = _teachers[index];
          final uid = t['uid'] as String;
          final email = (t['email'] ?? '').toString();
          final canAdd = t['canAddManually'] is bool ? t['canAddManually'] as bool : true;
          final canCsv = t['canImportCsv'] is bool ? t['canImportCsv'] as bool : false;
          final isSuperAdmin = email.toLowerCase() == AuthService.superAdminEmail;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: isSuperAdmin ? AppColors.primary : AppColors.textMuted,
                      child: Icon(isSuperAdmin ? Icons.shield : Icons.person, color: Colors.white, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                          if (isSuperAdmin)
                            Text('Super Admin', style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (!isSuperAdmin)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.deleteRed, size: 22.sp),
                        onPressed: () => _deleteTeacher(uid, email),
                      ),
                  ],
                ),
                if (!isSuperAdmin) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: Text('Can Add Manually', style: TextStyle(fontSize: 13.sp))),
                      Switch(value: canAdd, onChanged: (v) => _togglePermission(uid, 'canAddManually', v), activeThumbColor: AppColors.primary),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Can Import CSV', style: TextStyle(fontSize: 13.sp))),
                      Switch(value: canCsv, onChanged: (v) => _togglePermission(uid, 'canImportCsv', v), activeThumbColor: AppColors.primary),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Tab 2: Data Management ----------

  Widget _buildDataTab(Color cardBg, Color borderColor) {
    if (_isLoadingData) return const Center(child: CircularProgressIndicator());

    if (_streams.isEmpty) {
      return Column(
        children: [
          _buildAdminActionButtons(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64.sp, color: AppColors.textMuted),
                  SizedBox(height: 12.h),
                  Text('No streams found', style: TextStyle(fontSize: 16.sp, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _buildAdminActionButtons(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: _streams.length,
              itemBuilder: (context, index) {
                final stream = _streams[index];
                final students = _studentsByStream[stream.name] ?? [];
                final isExpanded = _expandedStream == stream.name;

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      // Stream header
                      ListTile(
                        onTap: () => setState(() => _expandedStream = isExpanded ? null : stream.name),
                        title: Text(stream.name, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        subtitle: Text('${students.length} students', style: TextStyle(fontSize: 13.sp)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete_forever, color: AppColors.deleteRed, size: 22.sp),
                              onPressed: () => _deleteStreamAdmin(stream.name),
                            ),
                            Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 24.sp),
                          ],
                        ),
                      ),
                      // Expanded student list
                      if (isExpanded)
                        ...students.map((s) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16.r,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?', style: TextStyle(fontSize: 14.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(s.name, style: TextStyle(fontSize: 14.sp)),
                          subtitle: Text('Roll: ${s.rollno}', style: TextStyle(fontSize: 12.sp)),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: AppColors.deleteRed, size: 20.sp),
                            onPressed: () => _deleteStudentAdmin(s),
                          ),
                        )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButtons() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showAddStreamDialog,
              icon: const Icon(Icons.class_),
              label: const Text('Add Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddStudentScreen()),
                );
                _loadData();
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.present,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tab 3: CSV ----------

  Widget _buildCsvTab(Color cardBg, Color borderColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stream selector
          Text('Select Stream', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _csvStreams.any((s) => s.name == _csvSelectedStream) ? _csvSelectedStream : null,
                hint: const Text('Select Stream'),
                isExpanded: true,
                items: _csvStreams.map((s) => s.name).toSet().map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                onChanged: (val) => setState(() => _csvSelectedStream = val),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Export section
          Text('Export Students', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportCsv,
            icon: _isExporting
                ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.download),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.present,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
          SizedBox(height: 32.h),

          // Import section
          Text('Import Students', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text('CSV must have a "name" column. "rollno" and "stream" are optional.\nIf a "stream" is provided, it overrides the selection above.',
              style: TextStyle(fontSize: 12.sp, color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(153))),
          SizedBox(height: 12.h),

          OutlinedButton.icon(
            onPressed: _pickCsvFile,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Pick CSV File'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          SizedBox(height: 16.h),

          // Preview
          if (_csvPreviewRows.isNotEmpty) ...[
            Text('Preview (${_csvPreviewRows.length} rows)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor),
              ),
              child: ListView.separated(
                padding: EdgeInsets.all(8.w),
                itemCount: _csvPreviewRows.length,
                separatorBuilder: (_, __) => Divider(height: 1.h),
                itemBuilder: (context, index) {
                  final row = _csvPreviewRows[index];
                  return ListTile(
                    dense: true,
                    title: Text(row['name'] ?? '', style: TextStyle(fontSize: 14.sp)),
                    trailing: Text(row['rollno'] ?? '', style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted)),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importCsvStudents,
              icon: _isImporting
                  ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text('Import ${_csvPreviewRows.length} Students to $_csvSelectedStream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
