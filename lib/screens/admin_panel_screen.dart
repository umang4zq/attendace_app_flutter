import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/student_model.dart';

import '../theme/app_colors.dart';
import 'add_student_screen.dart';
import '../providers/admin_provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      provider.loadTeachers();
      provider.loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteTeacher(AdminProvider provider, String uid, String email) async {
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
    if (confirm == true && mounted) {
      try {
        await provider.deleteTeacher(uid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _showAddStreamDialog(AdminProvider provider) async {
    final nameController = TextEditingController();
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    final semesterController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Stream'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    );
                  }),
                ],
                decoration: const InputDecoration(labelText: 'Stream Name (e.g. BCA2024)'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: semesterController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Semester'),
              ),
            ],
          ),
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
                try {
                  await provider.addStream(sName, yearController.text, semesterController.text);
                  if (ctx.mounted && mounted) {
                    Navigator.of(ctx).pop();
                  }
                } catch (e) {
                  if (ctx.mounted && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: AppColors.deleteRed,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStreamAdmin(AdminProvider provider, String streamId) async {
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
    if (confirm == true && mounted) {
      try {
        await provider.deleteStreamAdmin(streamId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stream deleted.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteStudentAdmin(AdminProvider provider, StudentModel student) async {
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
    if (confirm == true && mounted) {
      try {
        await provider.deleteStudentAdmin(student);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _showPromoteStreamDialog(AdminProvider provider, String oldStreamId) async {
    final nameController = TextEditingController(text: oldStreamId);
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    final semesterController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Promote $oldStreamId'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This will copy all students to a new stream.', style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted)),
              SizedBox(height: 12.h),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'New Stream Name (e.g. BCA 2nd Sem)'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: semesterController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Semester'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStreamName = nameController.text.trim();
              if (newStreamName.isNotEmpty) {
                showDialog(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (c) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final count = await provider.promoteStream(oldStreamId, newStreamName, yearController.text, semesterController.text);
                  
                  if (ctx.mounted && mounted) {
                    Navigator.pop(ctx); // pop loading
                    Navigator.pop(ctx); // pop promote dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully promoted $count students to $newStreamName!'), backgroundColor: AppColors.present),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted && mounted) {
                    Navigator.pop(ctx); // pop loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
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
          _buildTeachersTab(provider, cardBg, borderColor),
          _buildDataTab(provider, cardBg, borderColor),
          _buildCsvTab(provider, cardBg, borderColor),
        ],
      ),
    );
  }

  Widget _buildTeachersTab(AdminProvider provider, Color cardBg, Color borderColor) {
    if (provider.isLoadingTeachers) return const Center(child: CircularProgressIndicator());

    if (provider.teachers.isEmpty) {
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
      onRefresh: provider.loadTeachers,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: provider.teachers.length,
        itemBuilder: (context, index) {
          final t = provider.teachers[index];
          final uid = t['uid'] as String;
          final email = (t['email'] ?? '').toString();
          final canAdd = t['canAddManually'] is bool ? t['canAddManually'] as bool : true;
          final canCsv = t['canImportCsv'] is bool ? t['canImportCsv'] as bool : false;
          final isSuperAdmin = AuthService.superAdminEmails.contains(email.toLowerCase());

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
                        onPressed: () => _deleteTeacher(provider, uid, email),
                      ),
                  ],
                ),
                if (!isSuperAdmin) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: Text('Can Add Manually', style: TextStyle(fontSize: 13.sp))),
                      Switch(value: canAdd, onChanged: (v) async {
                        try {
                          await provider.togglePermission(uid, 'canAddManually', v);
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }, activeThumbColor: AppColors.primary),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Can Import CSV', style: TextStyle(fontSize: 13.sp))),
                      Switch(value: canCsv, onChanged: (v) async {
                        try {
                          await provider.togglePermission(uid, 'canImportCsv', v);
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }, activeThumbColor: AppColors.primary),
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

  Widget _buildDataTab(AdminProvider provider, Color cardBg, Color borderColor) {
    if (provider.isLoadingData) return const Center(child: CircularProgressIndicator());

    if (provider.streams.isEmpty) {
      return Column(
        children: [
          _buildAdminActionButtons(provider),
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
      onRefresh: provider.loadData,
      child: Column(
        children: [
          _buildAdminActionButtons(provider),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: provider.streams.length,
              itemBuilder: (context, index) {
                final stream = provider.streams[index];
                final students = provider.studentsByStream[stream.id] ?? [];
                final isExpanded = provider.expandedStream == stream.id;

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
                        onTap: () => provider.toggleExpandedStream(stream.id),
                        title: Text('${stream.name}${stream.semester != null && stream.semester!.isNotEmpty ? ' (Sem ${stream.semester})' : ''}', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        subtitle: Text('${students.length} students', style: TextStyle(fontSize: 13.sp)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.upgrade, color: AppColors.primary, size: 22.sp),
                              tooltip: 'Promote Batch',
                              onPressed: () => _showPromoteStreamDialog(provider, stream.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever, color: AppColors.deleteRed, size: 22.sp),
                              tooltip: 'Delete Stream',
                              onPressed: () => _deleteStreamAdmin(provider, stream.id),
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
                            onPressed: () => _deleteStudentAdmin(provider, s),
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

  Widget _buildAdminActionButtons(AdminProvider provider) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAddStreamDialog(provider),
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
                provider.loadData();
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

  Widget _buildCsvTab(AdminProvider provider, Color cardBg, Color borderColor) {
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
                value: provider.csvStreams.any((s) => s.id == provider.csvSelectedStream) ? provider.csvSelectedStream : null,
                hint: const Text('Select Stream'),
                isExpanded: true,
                items: provider.csvStreams.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name}${s.semester != null && s.semester!.isNotEmpty ? ' (Sem ${s.semester})' : ''}'))).toList(),
                onChanged: provider.setCsvSelectedStream,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Export section
          Text('Export Students', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            onPressed: provider.isExporting ? null : () async {
              try {
                await provider.exportCsv();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            },
            icon: provider.isExporting
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
            onPressed: () async {
              try {
                await provider.pickCsvFile();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Error: $e')));
              }
            },
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Pick CSV File'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          SizedBox(height: 16.h),

          // Preview
          if (provider.csvPreviewRows.isNotEmpty) ...[
            Text('Preview (${provider.csvPreviewRows.length} rows)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: borderColor),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: provider.csvPreviewRows.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                itemBuilder: (context, index) {
                  final row = provider.csvPreviewRows[index];
                  return ListTile(
                    dense: true,
                    title: Text(row['name'] ?? 'Unknown', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    subtitle: Text('Roll: ${row['rollno'] ?? '-'} | Stream: ${row['stream'] ?? provider.csvSelectedStream ?? '-'}', style: TextStyle(fontSize: 12.sp)),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: provider.isImporting ? null : () async {
                try {
                  final count = await provider.importCsvStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count students imported to ${provider.csvSelectedStream}!'), backgroundColor: AppColors.present),
                    );
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
                }
              },
              icon: provider.isImporting
                  ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(provider.isImporting ? 'Importing...' : 'Confirm & Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
            TextButton(
              onPressed: provider.clearCsvPreviewRows,
              child: const Text('Cancel'),
            ),
          ],
        ],
      ),
    );
  }
}
