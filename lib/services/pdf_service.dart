import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<Uint8List> generateAttendancePdf({
    required String streamName,
    required String fromMonth,
    required String toMonth,
    required List<Map<String, dynamic>> studentsData,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ATTENDANCE REPORT',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                    color: PdfColor.fromHex('#226EAC'),
                  ),
                ),
                pw.Text(
                  DateFormat('dd-MMM-yyyy').format(DateTime.now()),
                  style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E6F0FA'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Stream / Class: $streamName',
                      style: pw.TextStyle(font: fontBold, fontSize: 11)),
                  pw.Text('Date Range: $fromMonth to $toMonth',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('Total Students: ${studentsData.length}',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB'), width: 1),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(3.0),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(1.2),
                4: pw.FlexColumnWidth(1.2),
                5: pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#226EAC')),
                  children: [
                    _buildCell('Roll No', font: fontBold, isHeader: true),
                    _buildCell('Student Name', font: fontBold, isHeader: true),
                    _buildCell('Present', font: fontBold, isHeader: true),
                    _buildCell('Absent', font: fontBold, isHeader: true),
                    _buildCell('Holiday', font: fontBold, isHeader: true),
                    _buildCell('Attendance %', font: fontBold, isHeader: true),
                  ],
                ),
                // Data Rows
                ...studentsData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final isEven = index % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : PdfColor.fromHex('#F8FAFC'),
                    ),
                    children: [
                      _buildCell(row['rollno']?.toString() ?? '-'),
                      _buildCell(row['name']?.toString() ?? '-'),
                      _buildCell(row['present']?.toString() ?? '0', color: PdfColor.fromHex('#259538')),
                      _buildCell(row['absent']?.toString() ?? '0', color: PdfColor.fromHex('#DC2C2C')),
                      _buildCell(row['holiday']?.toString() ?? '0', color: PdfColor.fromHex('#FFA500')),
                      _buildCell(row['percentage']?.toString() ?? '0.0%', font: fontBold),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCell(
    String text, {
    pw.Font? font,
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          color: isHeader ? PdfColors.white : (color ?? PdfColor.fromHex('#1E293B')),
        ),
      ),
    );
  }

  static Future<void> shareOrPrintPdf(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }
}
