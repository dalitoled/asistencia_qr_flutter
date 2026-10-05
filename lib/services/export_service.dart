import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';
import '../models/multa_model.dart';
import '../models/pago_model.dart';
import '../models/socio_model.dart';

class ExportService {
  // ─── Exportar asistencias generales ─────────────────────────────────────

  static Future<void> exportToPdfWithData(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Asociación de Agua Potable Tolata Chico',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Reporte de Asistencia', style: const pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 5),
          pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['N°', 'Socio', 'CI', 'Tipo', 'Fecha/Hora'],
            data: data.asMap().entries.map((e) => [
              (e.key + 1).toString(),
              e.value['socio'] ?? '',
              e.value['ci'] ?? '',
              e.value['tipo'] ?? '',
              e.value['fecha'] ?? '',
            ]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> exportToExcelWithData(List<Map<String, dynamic>> data) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.getRangeByName('A1').setText('Asociación de Agua Potable Tolata Chico');
    sheet.getRangeByName('A1').cellStyle.fontSize = 16;
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A3').setText('N°');
    sheet.getRangeByName('B3').setText('Socio');
    sheet.getRangeByName('C3').setText('CI');
    sheet.getRangeByName('D3').setText('Tipo');
    sheet.getRangeByName('E3').setText('Fecha/Hora');
    for (int i = 0; i < data.length; i++) {
      final row = data[i];
      sheet.getRangeByIndex(i + 4, 1).setNumber(i + 1);
      sheet.getRangeByIndex(i + 4, 2).setText(row['socio'] ?? '');
      sheet.getRangeByIndex(i + 4, 3).setText(row['ci'] ?? '');
      sheet.getRangeByIndex(i + 4, 4).setText(row['tipo'] ?? '');
      sheet.getRangeByIndex(i + 4, 5).setText(row['fecha'] ?? '');
    }
    final List<int> bytes = workbook.saveAsStream();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/reporte_asistencia_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(bytes);
    workbook.dispose();
  }

  // ─── Reporte mensual por usuario: multas y pagos ────────────────────────

  /// Genera un PDF con el estado mensual de multas y pagos de un socio.
  static Future<void> exportReporteMensualPdf({
    required SocioModel socio,
    required int mes,
    required int anio,
    required List<MultaModel> multas,
    required List<PaymentModel> pagos,
  }) async {
    final pdf = pw.Document();
    final mesNombre = DateFormat('MMMM yyyy', 'es').format(DateTime(anio, mes));
    final fmt = DateFormat('dd/MM/yyyy');
    final fmtMonto = NumberFormat('#,##0.00', 'es');

    // Filtrar por mes y año
    final multasMes = multas
        .where((m) => m.fecha.month == mes && m.fecha.year == anio)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final pagosMes = pagos
        .where((p) => p.fecha.month == mes && p.fecha.year == anio)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    final totalMultas = multasMes.fold<double>(0, (s, m) => s + m.monto);
    final totalPendiente = multasMes
        .where((m) => m.estado == EstadoMulta.pendiente)
        .fold<double>(0, (s, m) => s + m.monto);
    final totalPagado = pagosMes.fold<double>(0, (s, p) => s + p.monto);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Encabezado
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Asociación de Agua Potable Tolata Chico',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'REPORTE MENSUAL DE MULTAS Y PAGOS',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Info del socio
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Socio: ${socio.nombreCompleto}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                    pw.Text('CI: ${socio.ci}'),
                    if (socio.numeroSocio != null && socio.numeroSocio!.isNotEmpty)
                      pw.Text('Código: ${socio.numeroSocio}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Período:', style: pw.TextStyle(color: PdfColors.grey700)),
                    pw.Text(mesNombre,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                    pw.Text('Generado: ${fmt.format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Resumen
          pw.Row(
            children: [
              _pdfSummaryBox('Total multas', 'Bs. ${fmtMonto.format(totalMultas)}', PdfColors.red100, PdfColors.red700),
              pw.SizedBox(width: 8),
              _pdfSummaryBox('Pendiente', 'Bs. ${fmtMonto.format(totalPendiente)}', PdfColors.orange100, PdfColors.orange700),
              pw.SizedBox(width: 8),
              _pdfSummaryBox('Total pagado', 'Bs. ${fmtMonto.format(totalPagado)}', PdfColors.green100, PdfColors.green700),
            ],
          ),
          pw.SizedBox(height: 20),
          // Tabla de multas
          if (multasMes.isNotEmpty) ...[
            pw.Text('MULTAS DEL PERÍODO',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Fecha', 'Tipo', 'Motivo', 'Monto (Bs)', 'Estado'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
              data: multasMes.map((m) => [
                fmt.format(m.fecha),
                m.tipoString,
                m.observaciones ?? '-',
                fmtMonto.format(m.monto),
                m.estadoString,
              ]).toList(),
            ),
            pw.SizedBox(height: 16),
          ] else ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Text('Sin multas registradas en este período.',
                  style: const pw.TextStyle(color: PdfColors.grey600)),
            ),
            pw.SizedBox(height: 16),
          ],
          // Tabla de pagos
          if (pagosMes.isNotEmpty) ...[
            pw.Text('PAGOS DEL PERÍODO',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Fecha', 'Tipo', 'Descripción', 'Monto (Bs)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
              data: pagosMes.map((p) => [
                fmt.format(p.fecha),
                p.tipo,
                p.observaciones ?? '-',
                fmtMonto.format(p.monto),
              ]).toList(),
            ),
          ] else ...[
            pw.Text('PAGOS DEL PERÍODO',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Text('Sin pagos registrados en este período.',
                  style: const pw.TextStyle(color: PdfColors.grey600)),
            ),
          ],
          pw.SizedBox(height: 24),
          // Balance final
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('SALDO PENDIENTE DEL PERÍODO:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.Text('Bs. ${fmtMonto.format(totalPendiente)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                      color: totalPendiente > 0 ? PdfColors.red700 : PdfColors.green700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _pdfSummaryBox(String label, String value, PdfColor bg, PdfColor fg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(color: fg, fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(color: fg, fontWeight: pw.FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  /// Genera un Excel con el estado mensual de multas y pagos de un socio.
  static Future<String> exportReporteMensualExcel({
    required SocioModel socio,
    required int mes,
    required int anio,
    required List<MultaModel> multas,
    required List<PaymentModel> pagos,
  }) async {
    final workbook = Workbook();
    final mesNombre = DateFormat('MMMM yyyy', 'es').format(DateTime(anio, mes));
    final fmt = DateFormat('dd/MM/yyyy');

    // Filtrar por mes y año
    final multasMes = multas
        .where((m) => m.fecha.month == mes && m.fecha.year == anio)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final pagosMes = pagos
        .where((p) => p.fecha.month == mes && p.fecha.year == anio)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    // ── Hoja 1: Resumen ──────────────────────────────────────────────────
    final sheetResumen = workbook.worksheets[0];
    sheetResumen.name = 'Resumen';

    sheetResumen.getRangeByName('A1').setText('Asociación de Agua Potable Tolata Chico');
    sheetResumen.getRangeByName('A1').cellStyle.bold = true;
    sheetResumen.getRangeByName('A1').cellStyle.fontSize = 14;

    sheetResumen.getRangeByName('A2').setText('Reporte Mensual de Multas y Pagos - $mesNombre');
    sheetResumen.getRangeByName('A2').cellStyle.fontSize = 12;

    sheetResumen.getRangeByName('A4').setText('Socio:');
    sheetResumen.getRangeByName('A4').cellStyle.bold = true;
    sheetResumen.getRangeByName('B4').setText(socio.nombreCompleto);

    sheetResumen.getRangeByName('A5').setText('CI:');
    sheetResumen.getRangeByName('A5').cellStyle.bold = true;
    sheetResumen.getRangeByName('B5').setText(socio.ci);

    if (socio.numeroSocio != null && socio.numeroSocio!.isNotEmpty) {
      sheetResumen.getRangeByName('A6').setText('Código:');
      sheetResumen.getRangeByName('A6').cellStyle.bold = true;
      sheetResumen.getRangeByName('B6').setText(socio.numeroSocio!);
    }

    sheetResumen.getRangeByName('A8').setText('RESUMEN FINANCIERO');
    sheetResumen.getRangeByName('A8').cellStyle.bold = true;
    sheetResumen.getRangeByName('A8').cellStyle.fontSize = 12;

    final totalMultas = multasMes.fold<double>(0, (s, m) => s + m.monto);
    final totalPendiente = multasMes
        .where((m) => m.estado == EstadoMulta.pendiente)
        .fold<double>(0, (s, m) => s + m.monto);
    final totalPagadoMultas = multasMes
        .where((m) => m.estado == EstadoMulta.pagado)
        .fold<double>(0, (s, m) => s + m.monto);
    final totalPagos = pagosMes.fold<double>(0, (s, p) => s + p.monto);

    final summaryData = [
      ['Total multas del período', totalMultas],
      ['Multas pendientes de pago', totalPendiente],
      ['Multas pagadas en el período', totalPagadoMultas],
      ['Total pagos registrados', totalPagos],
    ];

    for (int i = 0; i < summaryData.length; i++) {
      sheetResumen.getRangeByIndex(9 + i, 1).setText(summaryData[i][0] as String);
      sheetResumen.getRangeByIndex(9 + i, 2).setNumber(summaryData[i][1] as double);
      sheetResumen.getRangeByIndex(9 + i, 2).cellStyle.numberFormat = '#,##0.00';
    }

    sheetResumen.autoFitColumn(1);
    sheetResumen.autoFitColumn(2);

    // ── Hoja 2: Multas ──────────────────────────────────────────────────
    final sheetMultas = workbook.worksheets.addWithName('Multas');

    final multaHeaders = ['N°', 'Fecha', 'Tipo', 'Motivo/Observación', 'Monto (Bs)', 'Estado', 'ID Pago'];
    for (int i = 0; i < multaHeaders.length; i++) {
      sheetMultas.getRangeByIndex(1, i + 1).setText(multaHeaders[i]);
      sheetMultas.getRangeByIndex(1, i + 1).cellStyle.bold = true;
    }

    for (int i = 0; i < multasMes.length; i++) {
      final m = multasMes[i];
      sheetMultas.getRangeByIndex(i + 2, 1).setNumber(i + 1);
      sheetMultas.getRangeByIndex(i + 2, 2).setText(fmt.format(m.fecha));
      sheetMultas.getRangeByIndex(i + 2, 3).setText(m.tipoString);
      sheetMultas.getRangeByIndex(i + 2, 4).setText(m.observaciones ?? '-');
      sheetMultas.getRangeByIndex(i + 2, 5).setNumber(m.monto);
      sheetMultas.getRangeByIndex(i + 2, 5).cellStyle.numberFormat = '#,##0.00';
      sheetMultas.getRangeByIndex(i + 2, 6).setText(m.estadoString);
      sheetMultas.getRangeByIndex(i + 2, 7).setText(m.idPago ?? '-');
    }

    if (multasMes.isEmpty) {
      sheetMultas.getRangeByName('A2').setText('Sin multas en este período.');
    } else {
      // Totales
      final lastRow = multasMes.length + 2;
      sheetMultas.getRangeByIndex(lastRow, 4).setText('TOTAL');
      sheetMultas.getRangeByIndex(lastRow, 4).cellStyle.bold = true;
      sheetMultas.getRangeByIndex(lastRow, 5).setNumber(totalMultas);
      sheetMultas.getRangeByIndex(lastRow, 5).cellStyle.bold = true;
      sheetMultas.getRangeByIndex(lastRow, 5).cellStyle.numberFormat = '#,##0.00';
    }

    for (int c = 1; c <= 7; c++) {
      sheetMultas.autoFitColumn(c);
    }

    // ── Hoja 3: Pagos ────────────────────────────────────────────────────
    final sheetPagos = workbook.worksheets.addWithName('Pagos');

    final pagosHeaders = ['N°', 'Fecha', 'Tipo', 'Descripción', 'Monto (Bs)'];
    for (int i = 0; i < pagosHeaders.length; i++) {
      sheetPagos.getRangeByIndex(1, i + 1).setText(pagosHeaders[i]);
      sheetPagos.getRangeByIndex(1, i + 1).cellStyle.bold = true;
    }

    for (int i = 0; i < pagosMes.length; i++) {
      final p = pagosMes[i];
      sheetPagos.getRangeByIndex(i + 2, 1).setNumber(i + 1);
      sheetPagos.getRangeByIndex(i + 2, 2).setText(fmt.format(p.fecha));
      sheetPagos.getRangeByIndex(i + 2, 3).setText(p.tipo);
      sheetPagos.getRangeByIndex(i + 2, 4).setText(p.observaciones ?? '-');
      sheetPagos.getRangeByIndex(i + 2, 5).setNumber(p.monto);
      sheetPagos.getRangeByIndex(i + 2, 5).cellStyle.numberFormat = '#,##0.00';
    }

    if (pagosMes.isEmpty) {
      sheetPagos.getRangeByName('A2').setText('Sin pagos registrados en este período.');
    } else {
      final lastRow = pagosMes.length + 2;
      sheetPagos.getRangeByIndex(lastRow, 4).setText('TOTAL');
      sheetPagos.getRangeByIndex(lastRow, 4).cellStyle.bold = true;
      sheetPagos.getRangeByIndex(lastRow, 5).setNumber(totalPagos);
      sheetPagos.getRangeByIndex(lastRow, 5).cellStyle.bold = true;
      sheetPagos.getRangeByIndex(lastRow, 5).cellStyle.numberFormat = '#,##0.00';
    }

    for (int c = 1; c <= 5; c++) {
      sheetPagos.autoFitColumn(c);
    }

    // Guardar archivo
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final nombreArchivo = 'reporte_${socio.ci}_${anio}_${mes.toString().padLeft(2, '0')}.xlsx';
    final file = File('${directory.path}/$nombreArchivo');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}