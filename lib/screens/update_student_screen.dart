import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/student_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class UpdateStudentScreen extends StatefulWidget {
  final StudentModel student;

  const UpdateStudentScreen({super.key, required this.student});

  @override
  State<UpdateStudentScreen> createState() => _UpdateStudentScreenState();
}

class _UpdateStudentScreenState extends State<UpdateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rollController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _rollController = TextEditingController(text: widget.student.rollno);
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateStudent(
        widget.student.streamId.isNotEmpty ? widget.student.streamId : widget.student.stream,
        widget.student.docId,
        _nameController.text,
        _rollController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student updated successfully!'),
            backgroundColor: AppColors.present,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Student Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter name' : null,
                ),
                SizedBox(height: 18.h),
                TextFormField(
                  controller: _rollController,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter roll number' : null,
                ),
                SizedBox(height: 18.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : AppColors.background,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardBorderDark : AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, color: AppColors.textSecondary),
                      SizedBox(width: 12.w),
                      Text(
                        'Stream: ${widget.student.stream}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22.w,
                          height: 22.h,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('UPDATE DETAILS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
