class ReportExportService {
  static bool get supportsDownloads => false;

  static void exportCsv({
    required String fileName,
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    throw UnsupportedError('La descarga directa está disponible en Flutter Web.');
  }

  static void printPdf({
    required String title,
    required String subtitle,
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    throw UnsupportedError('La impresión PDF está disponible en Flutter Web.');
  }
}
