import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/stream_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/student_card.dart';
import 'add_student_screen.dart';
import 'update_student_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<StreamModel> _streams = [];
  String _selectedStream = 'All';

  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Floating Action Menu state
  bool _isMenuOpen = false;
  late AnimationController _fabController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final streams = await _firestoreService.getStreams();
      final students = await _firestoreService.fetchAllStudents();

      if (mounted) {
        setState(() {
          _streams = streams;
          _allStudents = students;
          _filterStudents();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredStudents = _allStudents.where((s) {
        final matchesStream = _selectedStream == 'All' ||
            s.stream.toLowerCase() == _selectedStream.toLowerCase() ||
            s.streamId.toLowerCase() == _selectedStream.toLowerCase();

        final matchesQuery = query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.rollno.toLowerCase().contains(query);

        return matchesStream && matchesQuery;
      }).toList();
    });
  }

  void _toggleStudentStatus(int index) {
    setState(() {
      final student = _filteredStudents[index];
      student.selected = false; // clear holiday
      student.isPresent = !student.isPresent;
      if (student.isPresent) {
        student.isAbsent = false;
      }
    });
  }

  void _markStudentPresent(int index) {
    setState(() {
      final student = _filteredStudents[index];
      student.selected = false;
      student.isPresent = true;
      student.isAbsent = false;
    });
  }

  void _markStudentAbsent(int index) {
    setState(() {
      final student = _filteredStudents[index];
      student.selected = false;
      student.isPresent = false;
      student.isAbsent = true;
    });
  }

  void _markHolidayForClass() {
    _toggleFabMenu();
    setState(() {
      for (var student in _filteredStudents) {
        student.selected = true;
        student.isPresent = false;
        student.isAbsent = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as Holiday for selected students! Click Save to confirm.'),
        backgroundColor: AppColors.holiday,
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_filteredStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to save attendance for')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _firestoreService.saveAttendance(
        date: _selectedDate,
        students: _filteredStudents,
      );
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

    if (confirm == true) {
      try {
        await _firestoreService.deleteStudent(
          student.streamId.isNotEmpty ? student.streamId : student.stream,
          student.docId,
        );
        _loadData();
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
    final formattedDate = DateFormat('dd-MMM-yy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo2.png'),
        ),
        title: InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ImageIcon(AssetImage('assets/images/calendar_icon.png'), color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, color: AppColors.primary, size: 26),
            onPressed: _isSaving ? null : _saveAttendance,
            tooltip: 'Save Attendance',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: Column(
          children: [
            // Filter Bar (Search & Stream Dropdown)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  // Search Box
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => _filterStudents(),
                        decoration: const InputDecoration(
                          hintText: 'Search student...',
                          hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
                          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Stream Dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStream,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All')),
                            ..._streams.map((s) => s.name).toSet().map((name) => DropdownMenuItem(value: name, child: Text(name))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStream = val);
                              _filterStudents();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Student Roster List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'No students found',
                                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddStudentScreen()),
                                  );
                                  _loadData();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Student'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredStudents.length,
                          padding: const EdgeInsets.only(bottom: 90),
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return StudentCard(
                              student: student,
                              onToggleStatus: () => _toggleStudentStatus(index),
                              onMarkPresent: () => _markStudentPresent(index),
                              onMarkAbsent: () => _markStudentAbsent(index),
                              onDelete: () => _deleteStudent(student),
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateStudentScreen(student: student),
                                  ),
                                );
                                _loadData();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sub-button: Mark Holiday
          ScaleTransition(
            scale: _expandAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                    ],
                  ),
                  child: const Text('Holiday', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'holiday_btn',
                  backgroundColor: AppColors.holiday,
                  onPressed: _markHolidayForClass,
                  child: const ImageIcon(AssetImage('assets/images/holiday_ic.png'), color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sub-button: Add Student
          ScaleTransition(
            scale: _expandAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                    ],
                  ),
                  child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'add_btn',
                  backgroundColor: AppColors.present,
                  onPressed: () async {
                    _toggleFabMenu();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddStudentScreen()),
                    );
                    _loadData();
                  },
                  child: const ImageIcon(AssetImage('assets/images/add_icon.png'), color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Main Trigger FAB
          FloatingActionButton(
            heroTag: 'main_fab',
            backgroundColor: AppColors.primary,
            onPressed: _toggleFabMenu,
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.125).animate(_expandAnimation),
              child: const ImageIcon(AssetImage('assets/images/plus_fab.png'), color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
