// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

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
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', '$fileName.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static void printPdf({
    required String title,
    required String subtitle,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    final generated = DateTime.now();
    final bodyRows = rows.map((row) {
      return '<tr>${row.map((cell) => '<td>${_html(cell)}</td>').join()}</tr>';
    }).join();
    final headings = columns.map((column) => '<th>${_html(column)}</th>').join();

    final reportHtml = '''
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>${_html(title)}</title>
<style>
  @page { size: A4 landscape; margin: 14mm; }
  body { font-family: Arial, sans-serif; color: #172033; margin: 0; }
  .brand { color: #0d355c; font-size: 24px; font-weight: 800; }
  h1 { margin: 12px 0 4px; font-size: 22px; }
  .meta { color: #64748b; font-size: 12px; margin-bottom: 18px; }
  table { width: 100%; border-collapse: collapse; font-size: 10px; }
  th { background: #0d355c; color: white; text-align: left; padding: 8px; }
  td { border: 1px solid #dbe3ec; padding: 7px; vertical-align: top; }
  tr:nth-child(even) td { background: #f8fafc; }
  .footer { margin-top: 16px; color: #64748b; font-size: 10px; }
</style>
</head>
<body>
  <div class="brand">LOGIFAENA <span style="font-size:12px;font-weight:400">Enterprise Edition</span></div>
  <h1>${_html(title)}</h1>
  <div class="meta">${_html(subtitle)} · Generado ${generated.day.toString().padLeft(2, '0')}/${generated.month.toString().padLeft(2, '0')}/${generated.year} ${generated.hour.toString().padLeft(2, '0')}:${generated.minute.toString().padLeft(2, '0')} · Coordinador: Alejandro Cárdenas</div>
  <table><thead><tr>$headings</tr></thead><tbody>$bodyRows</tbody></table>
  <div class="footer">Documento generado desde LogiFaena. Use “Guardar como PDF” en el diálogo de impresión.</div>
<script>window.onload = function(){ window.print(); };</script>
</body>
</html>
''';

    // `window.open()` returns WindowBase in current Dart SDKs, which does not
    // expose `document`. Opening a temporary HTML Blob avoids that incompatibility
    // and works reliably in Flutter Web.
    final blob = html.Blob([reportHtml], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');

    // Give the new tab enough time to load the Blob before releasing the URL.
    Future<void>.delayed(const Duration(seconds: 10), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  static String _csvRow(List<String> values) => values.map((value) {
        final escaped = value.replaceAll('"', '""');
        return '"$escaped"';
      }).join(';');

  static String _html(String value) => const HtmlEscape().convert(value);
}
