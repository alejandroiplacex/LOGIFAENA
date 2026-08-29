import 'dart:convert';
import 'dart:js_interop';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

class ReportExportService {
  static bool get supportsDownloads => true;

  static void exportCsv({
    required String fileName,
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(_csvRow([title]));
    buffer.writeln(_csvRow(['Generado', DateTime.now().toIso8601String()]));
    buffer.writeln();
    buffer.writeln(_csvRow(columns));
    for (final row in rows) {
      buffer.writeln(_csvRow(row));
    }

    final bytes = utf8.encode('\uFEFF${buffer.toString()}');
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );

    final url = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = '$fileName.csv';

    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  static Future<void> printPdf({
    required String title,
    required String subtitle,
    required List<String> columns,
    required List<List<String>> rows,
  }) async {
    final generated = DateTime.now();

    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'LOGIFAENA',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Enterprise Edition',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '$subtitle · Generado '
                '${generated.day.toString().padLeft(2, '0')}/'
                '${generated.month.toString().padLeft(2, '0')}/'
                '${generated.year} '
                '${generated.hour.toString().padLeft(2, '0')}:'
                '${generated.minute.toString().padLeft(2, '0')} '
                '· Coordinador: Alejandro Cárdenas',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: columns,
            data: rows,
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    final bytes = await document.save();

final blob = web.Blob(
  [bytes.toJS].toJS,
  web.BlobPropertyBag(type: 'application/pdf'),
);

final url = web.URL.createObjectURL(blob);

final safeTitle = title
    .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
    .replaceAll(' ', '_');

final anchor = web.HTMLAnchorElement()
  ..href = url
  ..download = 'logifaena_$safeTitle.pdf';

anchor.click();

Future<void>.delayed(const Duration(seconds: 2), () {
  web.URL.revokeObjectURL(url);
});
  }

  static String _csvRow(List<String> values) => values
      .map((value) {
        final escaped = value.replaceAll('"', '""');
        return '"$escaped"';
      })
      .join(';');
}
