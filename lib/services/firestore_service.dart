import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/stream_model.dart';
import '../models/date_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Stream Operations ---

  Future<List<StreamModel>> getStreams() async {
    final snapshot = await _firestore.collection('streams').get();
    return snapshot.docs.map((doc) {
      return StreamModel.fromDoc(doc.id, doc.data());
    }).toList();
  }

  Future<void> addStream(String streamName, String year) async {
    final cleanName = streamName.trim();
    if (cleanName.isEmpty) return;

    await _firestore.collection('streams').doc(cleanName).set({
      'name': cleanName,
      'year': year.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStream(String streamId) async {
    // Delete all students inside the stream subcollection first
    final studentsSnapshot = await _firestore
        .collection('streams')
        .doc(streamId)
        .collection('students')
        .get();

    final batch = _firestore.batch();
    for (var doc in studentsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    // Delete stream document
    batch.delete(_firestore.collection('streams').doc(streamId));
    await batch.commit();
  }

  // --- Student Operations ---

  Future<List<StudentModel>> fetchAllStudents() async {
    final streamDocs = await _firestore.collection('streams').get();
    if (streamDocs.docs.isEmpty) return [];

    final Map<String, StudentModel> studentMap = {};

    for (var streamDoc in streamDocs.docs) {
      final streamId = streamDoc.id;
      final studentSnapshots = await _firestore
          .collection('streams')
          .doc(streamId)
          .collection('students')
          .get();

      for (var sdoc in studentSnapshots.docs) {
        final data = sdoc.data();
        final student = StudentModel.fromMap(data, sdoc.id, streamId: streamId);
        studentMap[student.docId] = student;
      }
    }
    return studentMap.values.toList();
  }

  Future<List<StudentModel>> fetchStudentsByStream(String streamId) async {
    if (streamId.isEmpty || streamId.toLowerCase() == 'all') {
      return fetchAllStudents();
    }

    final snapshot = await _firestore
        .collection('streams')
        .doc(streamId)
        .collection('students')
        .get();

    return snapshot.docs.map((doc) {
      return StudentModel.fromMap(doc.data(), doc.id, streamId: streamId);
    }).toList();
  }

  Future<void> addStudent(String stream, String name, String rollNo) async {
    final cleanStream = stream.trim();
    final cleanName = name.trim();
    final cleanRoll = rollNo.trim();

    final docId = cleanRoll.isNotEmpty ? cleanRoll : cleanName;

    await _firestore
        .collection('streams')
        .doc(cleanStream)
        .collection('students')
        .doc(docId)
        .set({
      'name': cleanName,
      'rollno': cleanRoll,
      'stream': cleanStream,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStudent(String streamId, String docId, String newName, String newRollNo) async {
    await _firestore
        .collection('streams')
        .doc(streamId)
        .collection('students')
        .doc(docId)
        .update({
      'name': newName.trim(),
      'rollno': newRollNo.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStudent(String streamId, String docId) async {
    await _firestore
        .collection('streams')
        .doc(streamId)
        .collection('students')
        .doc(docId)
        .delete();
  }

  // --- Attendance Operations ---

  Future<void> saveAttendance({
    required DateTime date,
    required List<StudentModel> students,
  }) async {
    final monthKey = DateFormat('yyyy-MM').format(date);
    final dayKey = DateFormat('dd').format(date);
    final formattedDate = DateFormat('dd-MMM-yy').format(date);

    final batch = _firestore.batch();

    for (var student in students) {
      String status;
      if (student.selected) {
        status = 'Holiday';
      } else if (student.isPresent) {
        status = 'Present';
      } else if (student.isAbsent) {
        status = 'Absent';
      } else {
        continue; // Unmarked, skip saving
      }

      final studentDocId = student.docId.isNotEmpty ? student.docId : student.rollno;
      final streamDocId = student.streamId.isNotEmpty ? student.streamId : student.stream;

      if (streamDocId.isEmpty || studentDocId.isEmpty) continue;

      final dayRef = _firestore
          .collection('streams')
          .doc(streamDocId)
          .collection('students')
          .doc(studentDocId)
          .collection('attendance')
          .doc(monthKey)
          .collection('days')
          .doc(dayKey);

      batch.set(dayRef, {
        'status': status,
        'name': student.name,
        'rollno': student.rollno,
        'date': formattedDate,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // --- Monthly Attendance & Statistics ---

  Future<Map<String, dynamic>> fetchMonthlyAttendance({
    required String streamId,
    required String studentId,
    required int year,
    required int month,
  }) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    final daysSnapshot = await _firestore
        .collection('streams')
        .doc(streamId)
        .collection('students')
        .doc(studentId)
        .collection('attendance')
        .doc(monthKey)
        .collection('days')
        .get();

    final Map<int, String> dayStatuses = {};
    int presentCount = 0;
    int absentCount = 0;
    int holidayCount = 0;

    for (var doc in daysSnapshot.docs) {
      final dayNumber = int.tryParse(doc.id);
      if (dayNumber != null) {
        final status = (doc.data()['status'] ?? 'None').toString();
        dayStatuses[dayNumber] = status;

        if (status.toLowerCase() == 'present') {
          presentCount++;
        } else if (status.toLowerCase() == 'absent') {
          absentCount++;
        } else if (status.toLowerCase() == 'holiday') {
          holidayCount++;
        }
      }
    }

    final totalWorkingDays = presentCount + absentCount;
    final percentage = totalWorkingDays > 0 ? (presentCount / totalWorkingDays) * 100 : 0.0;

    // Generate date models for the calendar grid
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<DateModel> calendarDays = [];

    for (int i = 1; i <= daysInMonth; i++) {
      calendarDays.add(DateModel(
        day: i,
        date: '$i',
        month: '$month',
        year: '$year',
        status: dayStatuses[i] ?? 'None',
      ));
    }

    return {
      'presentCount': presentCount,
      'absentCount': absentCount,
      'holidayCount': holidayCount,
      'percentage': percentage,
      'calendarDays': calendarDays,
    };
  }

  // --- Report Date-Range Attendance Calculation ---

  Future<List<Map<String, dynamic>>> fetchAttendanceReportData({
    required String streamId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final students = await fetchStudentsByStream(streamId);
    final List<Map<String, dynamic>> reportRows = [];

    // List of all months in range
    final List<String> monthKeys = [];
    var current = DateTime(fromDate.year, fromDate.month);
    final end = DateTime(toDate.year, toDate.month);

    while (!current.isAfter(end)) {
      monthKeys.add(DateFormat('yyyy-MM').format(current));
      current = DateTime(current.year, current.month + 1);
    }

    for (var student in students) {
      int totalPresent = 0;
      int totalAbsent = 0;
      int totalHoliday = 0;

      for (var mKey in monthKeys) {
        final daysSnap = await _firestore
            .collection('streams')
            .doc(student.streamId.isNotEmpty ? student.streamId : streamId)
            .collection('students')
            .doc(student.docId)
            .collection('attendance')
            .doc(mKey)
            .collection('days')
            .get();

        for (var doc in daysSnap.docs) {
          final st = (doc.data()['status'] ?? '').toString().toLowerCase();
          if (st == 'present') {
            totalPresent++;
          } else if (st == 'absent') {
            totalAbsent++;
          } else if (st == 'holiday') {
            totalHoliday++;
          }
        }
      }

      final workingDays = totalPresent + totalAbsent;
      final pct = workingDays > 0 ? ((totalPresent / workingDays) * 100).toStringAsFixed(1) : '0.0';

      reportRows.add({
        'rollno': student.rollno,
        'name': student.name,
        'stream': student.stream,
        'present': totalPresent,
        'absent': totalAbsent,
        'holiday': totalHoliday,
        'percentage': '$pct%',
      });
    }

    return reportRows;
  }
}
