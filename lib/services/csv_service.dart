import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/student_model.dart';

class CsvService {
  /// Pick a CSV file from device storage and return its raw text content.
  static Future<String?> pickAndReadCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    return file.readAsString();
  }

  /// Parse raw CSV text into a list of maps with keys: name, rollno.
  /// Expects header row: name, rollno (case-insensitive).
  static List<Map<String, String>> parseCsv(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent, eol: '\n');
    if (rows.isEmpty) return [];

    // Find header indices
    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final nameIdx = header.indexOf('name');
    final rollIdx = header.indexOf('rollno');
    final streamIdx = header.indexOf('stream');

    if (nameIdx == -1) {
      throw FormatException('CSV must have a "name" column. Found: ${rows.first}');
    }

    final List<Map<String, String>> students = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final name = (nameIdx < row.length) ? row[nameIdx].toString().trim() : '';
      final rollno = (rollIdx != -1 && rollIdx < row.length) ? row[rollIdx].toString().trim() : '';
      final stream = (streamIdx != -1 && streamIdx < row.length) ? row[streamIdx].toString().trim() : '';

      if (name.isNotEmpty) {
        students.add({'name': name, 'rollno': rollno, 'stream': stream});
      }
    }
    return students;
  }

  /// Generate CSV string from a list of StudentModel.
  static String generateCsv(List<StudentModel> students) {
    final List<List<String>> rows = [
      ['name', 'rollno', 'stream'], // header
      ...students.map((s) => [s.name, s.rollno, s.stream]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Save CSV content to a temp file and share it via the OS share sheet.
  static Future<void> shareCsvFile(String csvContent, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Student data export',
    );
  }
}
