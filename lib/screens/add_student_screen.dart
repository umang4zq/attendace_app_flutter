import 'package:flutter/material.dart';
import '../models/stream_model.dart';
import '../services/firestore_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoadingStreams = true);
    try {
      final streams = await _firestoreService.getStreams();
      if (mounted) {
        setState(() {
          _streams = streams;
          if (streams.isNotEmpty && (_selectedStream == null || !_streams.any((s) => s.name == _selectedStream))) {
            _selectedStream = streams.first.name;
          }
          _isLoadingStreams = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStreams = false);
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
            const SizedBox(height: 12),
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
                if (mounted) {
                  setState(() {
                    _selectedStream = sName;
                  });
                  _loadStreams();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteStreamDialog() async {
    if (_selectedStream == null || _selectedStream!.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Stream'),
        content: Text(
          'Are you sure you want to delete "$_selectedStream"?\nAll students inside this stream will also be deleted.',
        ),
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

    if (confirm == true && _selectedStream != null) {
      try {
        await _firestoreService.deleteStream(_selectedStream!);
        _selectedStream = null;
        _loadStreams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stream and associated students deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Students'),
        actions: [
          TextButton(
            onPressed: _showDeleteStreamDialog,
            child: const Text('Delete Class', style: TextStyle(color: AppColors.deleteRed)),
          ),
          TextButton(
            onPressed: _showAddStreamDialog,
            child: const Text('Add Class', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 18),

                // Roll Number
                TextFormField(
                  controller: _rollController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Student Roll number',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter roll number' : null,
                ),
                const SizedBox(height: 18),

                // Stream Dropdown
                _isLoadingStreams
                    ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _streams.any((s) => s.name == _selectedStream) ? _selectedStream : null,
                            hint: const Text('Select Stream'),
                            isExpanded: true,
                            items: _streams.map((s) => s.name).toSet().map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                            onChanged: (val) => setState(() => _selectedStream = val),
                          ),
                        ),
                      ),
                const SizedBox(height: 18),

                // Stream Year
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter Stream Year',
                    prefixIcon: Icon(Icons.date_range_outlined),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.present,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
