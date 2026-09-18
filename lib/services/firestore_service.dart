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

  Future<void> addStream(String streamName, String year, [String semester = '']) async {
    final cleanName = streamName.trim();
    if (cleanName.isEmpty) return;

    await _firestore.collection('streams').doc(cleanName).set({
      'name': cleanName,
      'year': year.trim(),
      'semester': semester.trim(),
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
      final semester = streamDoc.data()['semester']?.toString() ?? '';
      
      final studentSnapshots = await _firestore
          .collection('streams')
          .doc(streamId)
          .collection('students')
          .get();

      for (var sdoc in studentSnapshots.docs) {
        final data = sdoc.data();
        final student = StudentModel.fromMap(data, sdoc.id, streamId: streamId, semester: semester);
        studentMap[student.docId] = student;
      }
    }
    return studentMap.values.toList();
  }

  Future<List<StudentModel>> fetchStudentsByStream(String streamId) async {
    if (streamId.isEmpty || streamId.toLowerCase() == 'all') {
      return fetchAllStudents();
    }

    final streamDoc = await _firestore.collection('streams').doc(streamId).get();
    final semester = streamDoc.data()?['semester']?.toString() ?? '';

    final snapshot = await _firestore
        .collection('streams')
        .doc(streamId)
        .collection('students')
        .get();

    return snapshot.docs.map((doc) {
      return StudentModel.fromMap(doc.data(), doc.id, streamId: streamId, semester: semester);
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

  // --- Aggregated Attendance (Semester / Year) ---

  Future<Map<String, dynamic>> fetchAggregatedAttendance({
    required String streamId,
    required String studentId,
    required int year,
    required List<int> months,
  }) async {
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalHoliday = 0;
    final List<Map<String, dynamic>> monthlyBreakdown = [];

    for (int month in months) {
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

      int mPresent = 0;
      int mAbsent = 0;

      for (var doc in daysSnapshot.docs) {
        final status = (doc.data()['status'] ?? 'None').toString().toLowerCase();
        if (status == 'present') {
          mPresent++;
        } else if (status == 'absent') {
          mAbsent++;
        } else if (status == 'holiday') {
          totalHoliday++; // Keep track of total holidays
        }
      }

      totalPresent += mPresent;
      totalAbsent += mAbsent;

      final mWorkingDays = mPresent + mAbsent;
      final mPercentage = mWorkingDays > 0 ? (mPresent / mWorkingDays) * 100 : 0.0;

      monthlyBreakdown.add({
        'month': month,
        'percentage': mPercentage,
        'hasData': daysSnapshot.docs.isNotEmpty,
      });
    }

    final totalWorkingDays = totalPresent + totalAbsent;
    final percentage = totalWorkingDays > 0 ? (totalPresent / totalWorkingDays) * 100 : 0.0;

    return {
      'presentCount': totalPresent,
      'absentCount': totalAbsent,
      'holidayCount': totalHoliday,
      'percentage': percentage,
      'monthlyBreakdown': monthlyBreakdown,
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

  // --- Teacher Permission Operations (Super Admin) ---

  /// Get all teacher documents.
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  /// Get a single teacher's permissions by UID.
  Future<Map<String, dynamic>?> getTeacherPermissions(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['uid'] = doc.id;
    return data;
  }

  /// Create or update teacher permissions.
  Future<void> setTeacherPermissions(String uid, {bool? canAddManually, bool? canImportCsv}) async {
    final Map<String, dynamic> updates = {};
    if (canAddManually != null) updates['canAddManually'] = canAddManually;
    if (canImportCsv != null) updates['canImportCsv'] = canImportCsv;
    if (updates.isEmpty) return;

    await _firestore.collection('users').doc(uid).update(updates);
  }

  /// Delete a teacher's permission doc.
  Future<void> deleteTeacherDoc(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // --- Bulk Student Operations (CSV) ---

  Future<int> addStudentsBatch(String defaultStreamId, List<Map<String, String>> students) async {
    final batch = _firestore.batch();
    int count = 0;
    Set<String> uniqueStreams = {};

    for (var student in students) {
      final name = (student['name'] ?? '').trim();
      final rollno = (student['rollno'] ?? '').trim();
      String streamId = (student['stream'] ?? '').trim();
      
      if (streamId.isEmpty) {
        streamId = defaultStreamId;
      }

      if (name.isEmpty || streamId.isEmpty) continue;
      
      uniqueStreams.add(streamId);

      final docId = rollno.isNotEmpty ? rollno : name;
      final ref = _firestore
          .collection('streams')
          .doc(streamId)
          .collection('students')
          .doc(docId);

      batch.set(ref, {
        'name': name,
        'rollno': rollno,
        'stream': streamId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      count++;
    }
    
    // Create any new streams that don't exist yet
    for (String s in uniqueStreams) {
      final streamRef = _firestore.collection('streams').doc(s);
      batch.set(streamRef, {
        'name': s,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (count > 0) await batch.commit();
    return count;
  }

  // --- Promote Batch Operation ---

  Future<int> promoteStream(String oldStreamId, String newStreamName, String newStreamYear, String newStreamSemester) async {
    final students = await fetchStudentsByStream(oldStreamId);
    if (students.isEmpty) return 0;

    final cleanNewStreamName = newStreamName.trim();
    if (cleanNewStreamName.isEmpty) return 0;

    // Create the new stream document
    await addStream(cleanNewStreamName, newStreamYear, newStreamSemester);

    final batch = _firestore.batch();
    int count = 0;

    for (var student in students) {
      final docId = student.rollno.isNotEmpty ? student.rollno : student.name;
      final ref = _firestore
          .collection('streams')
          .doc(cleanNewStreamName)
          .collection('students')
          .doc(docId);

      batch.set(ref, {
        'name': student.name,
        'rollno': student.rollno,
        'stream': cleanNewStreamName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }

    return count;
  }
}

