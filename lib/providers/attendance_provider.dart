import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/stream_model.dart';
import '../services/firestore_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<StreamModel> _streams = [];
  List<StreamModel> get streams => _streams;

  List<String> get filterOptions {
    final options = <String>{'All'};
    for (var s in _streams) {
      String year = '';
      if (s.semester == '1' || s.semester == '2') year = ' 1YR';
      else if (s.semester == '3' || s.semester == '4') year = ' 2YR';
      else if (s.semester == '5' || s.semester == '6') year = ' 3RD YR';
      
      if (year.isNotEmpty && s.name.isNotEmpty) {
        options.add('${s.name}$year');
      } else if (s.name.isNotEmpty) {
        options.add(s.name);
      }
    }
    // ensure 'All' is first
    final list = options.toList();
    list.remove('All');
    list.sort();
    return ['All', ...list];
  }

  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];
  List<StudentModel> get filteredStudents => _filteredStudents;

  String _selectedStream = 'All';
  String get selectedStream => _selectedStream;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _streams = await _firestoreService.getStreams();
      _allStudents = await _firestoreService.fetchAllStudents();
      filterStudents();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedStream(String stream) {
    _selectedStream = stream;
    filterStudents();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    filterStudents();
  }

  void filterStudents() {
    final query = _searchQuery.toLowerCase().trim();
    _filteredStudents = _allStudents.where((s) {
      String year = '';
      if (s.semester == '1' || s.semester == '2') year = ' 1YR';
      else if (s.semester == '3' || s.semester == '4') year = ' 2YR';
      else if (s.semester == '5' || s.semester == '6') year = ' 3RD YR';

      final streamWithYear = '${s.stream}$year'.toLowerCase();
      final streamIdWithYear = '${s.streamId}$year'.toLowerCase();

      final matchesStream = _selectedStream == 'All' ||
          s.stream.toLowerCase() == _selectedStream.toLowerCase() ||
          s.streamId.toLowerCase() == _selectedStream.toLowerCase() ||
          streamWithYear == _selectedStream.toLowerCase() ||
          streamIdWithYear == _selectedStream.toLowerCase();

      final matchesQuery = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.rollno.toLowerCase().contains(query);

      return matchesStream && matchesQuery;
    }).toList();
    notifyListeners();
  }

  void toggleStudentStatus(int index) {
    final student = _filteredStudents[index];
    student.selected = false; // clear holiday
    student.isPresent = !student.isPresent;
    if (student.isPresent) {
      student.isAbsent = false;
    }
    notifyListeners();
  }

  void markStudentPresent(int index) {
    final student = _filteredStudents[index];
    student.selected = false;
    student.isPresent = true;
    student.isAbsent = false;
    notifyListeners();
  }

  void markStudentAbsent(int index) {
    final student = _filteredStudents[index];
    student.selected = false;
    student.isPresent = false;
    student.isAbsent = true;
    notifyListeners();
  }

  void markHolidayForClass() {
    for (var student in _filteredStudents) {
      student.selected = true;
      student.isPresent = false;
      student.isAbsent = false;
    }
    notifyListeners();
  }

  void markAllPresentForClass() {
    for (var student in _filteredStudents) {
      student.selected = false;
      student.isPresent = true;
      student.isAbsent = false;
    }
    notifyListeners();
  }

  void markAllAbsentForClass() {
    for (var student in _filteredStudents) {
      student.selected = false;
      student.isPresent = false;
      student.isAbsent = true;
    }
    notifyListeners();
  }

  Future<void> saveAttendance(DateTime date) async {
    if (_filteredStudents.isEmpty) throw Exception('No students to save attendance for');

    _isSaving = true;
    notifyListeners();
    try {
      await _firestoreService.saveAttendance(
        date: date,
        students: _filteredStudents,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(StudentModel student) async {
    await _firestoreService.deleteStudent(
      student.streamId.isNotEmpty ? student.streamId : student.stream,
      student.docId,
    );
    await loadData();
  }
}
