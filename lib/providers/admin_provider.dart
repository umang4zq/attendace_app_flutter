import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/csv_service.dart';
import '../models/student_model.dart';
import '../models/stream_model.dart';

class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Teachers State
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> get teachers => _teachers;
  bool _isLoadingTeachers = true;
  bool get isLoadingTeachers => _isLoadingTeachers;

  // Data State
  List<StreamModel> _streams = [];
  List<StreamModel> get streams => _streams;
  Map<String, List<StudentModel>> _studentsByStream = {};
  Map<String, List<StudentModel>> get studentsByStream => _studentsByStream;
  bool _isLoadingData = true;
  bool get isLoadingData => _isLoadingData;
  String? _expandedStream;
  String? get expandedStream => _expandedStream;

  // CSV State
  List<StreamModel> _csvStreams = [];
  List<StreamModel> get csvStreams => _csvStreams;
  String? _csvSelectedStream;
  String? get csvSelectedStream => _csvSelectedStream;
  List<Map<String, String>> _csvPreviewRows = [];
  List<Map<String, String>> get csvPreviewRows => _csvPreviewRows;
  bool _isImporting = false;
  bool get isImporting => _isImporting;
  bool _isExporting = false;
  bool get isExporting => _isExporting;

  Future<void> loadTeachers() async {
    _isLoadingTeachers = true;
    notifyListeners();
    try {
      _teachers = await _firestoreService.getAllTeachers();
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    } finally {
      _isLoadingTeachers = false;
      notifyListeners();
    }
  }

  Future<void> togglePermission(String uid, String field, bool value) async {
    final index = _teachers.indexWhere((t) => t['uid'] == uid);
    if (index != -1) {
      _teachers[index][field] = value;
      notifyListeners();
    }

    try {
      if (field == 'canAddManually') {
        await _firestoreService.setTeacherPermissions(uid, canAddManually: value);
      } else {
        await _firestoreService.setTeacherPermissions(uid, canImportCsv: value);
      }
    } catch (e) {
      await loadTeachers();
      rethrow;
    }
  }

  Future<void> deleteTeacher(String uid) async {
    _teachers.removeWhere((t) => t['uid'] == uid);
    notifyListeners();

    try {
      await _firestoreService.deleteTeacherDoc(uid);
    } catch (e) {
      await loadTeachers();
      rethrow;
    }
  }

  Future<void> loadData() async {
    _isLoadingData = true;
    notifyListeners();
    try {
      _streams = await _firestoreService.getStreams();
      _studentsByStream = {};
      for (var s in _streams) {
        _studentsByStream[s.id] = await _firestoreService.fetchStudentsByStream(s.id);
      }
      _csvStreams = _streams;
      if (_csvStreams.isNotEmpty && _csvSelectedStream == null) {
        _csvSelectedStream = _csvStreams.first.id;
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoadingData = false;
      notifyListeners();
    }
  }

  void toggleExpandedStream(String streamName) {
    _expandedStream = _expandedStream == streamName ? null : streamName;
    notifyListeners();
  }

  Future<void> addStream(String name, String year, String semester) async {
    await _firestoreService.addStream(name, year, semester);
    await loadData();
  }

  Future<void> deleteStreamAdmin(String streamId) async {
    _streams.removeWhere((s) => s.id == streamId);
    _studentsByStream.remove(streamId);
    notifyListeners();

    try {
      await _firestoreService.deleteStream(streamId);
    } catch (e) {
      await loadData();
      rethrow;
    }
  }

  Future<void> deleteStudentAdmin(StudentModel student) async {
    final streamName = student.streamId.isNotEmpty ? student.streamId : student.stream;
    _studentsByStream[streamName]?.removeWhere((s) => s.docId == student.docId);
    notifyListeners();

    try {
      await _firestoreService.deleteStudent(streamName, student.docId);
    } catch (e) {
      await loadData();
      rethrow;
    }
  }

  Future<int> promoteStream(String oldStreamId, String newStreamName, String year, String semester) async {
    final count = await _firestoreService.promoteStream(oldStreamId, newStreamName, year, semester);
    await loadData();
    return count;
  }

  void setCsvSelectedStream(String? stream) {
    _csvSelectedStream = stream;
    notifyListeners();
  }

  Future<void> pickCsvFile() async {
    final csvContent = await CsvService.pickAndReadCsvFile();
    if (csvContent != null) {
      _csvPreviewRows = CsvService.parseCsv(csvContent);
      notifyListeners();
    }
  }

  void clearCsvPreviewRows() {
    _csvPreviewRows = [];
    notifyListeners();
  }

  Future<int> importCsvStudents() async {
    if (_csvSelectedStream == null || _csvPreviewRows.isEmpty) throw Exception('No stream selected or rows empty');

    _isImporting = true;
    notifyListeners();
    try {
      final count = await _firestoreService.addStudentsBatch(_csvSelectedStream!, _csvPreviewRows);
      _csvPreviewRows = [];
      await loadData();
      return count;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> exportCsv() async {
    if (_csvSelectedStream == null) throw Exception('No stream selected');

    _isExporting = true;
    notifyListeners();
    try {
      final students = await _firestoreService.fetchStudentsByStream(_csvSelectedStream!);
      if (students.isEmpty) throw Exception('No students found in this stream.');
      final csv = CsvService.generateCsv(students);
      await CsvService.shareCsvFile(csv, 'students_$_csvSelectedStream.csv');
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
