import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/receipt_model.dart';

class PdfService {
  Future<void> imprimirRecibo(ReceiptModel recibo) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32), // Margen para que se vea mejor
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. ENCABEZADO CON ESTADO DE PAGO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Comité de Agua Potable", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Comprobante de Servicio", style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                  // Sello de PAGADO o PENDIENTE
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: recibo.pagado ? PdfColors.green : PdfColors.red, 
                        width: 2
                      ),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      recibo.pagado ? "PAGADO" : "PENDIENTE",
                      style: pw.TextStyle(
                        color: recibo.pagado ? PdfColors.green : PdfColors.red, 
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // 2. DATOS DEL USUARIO Y PERIODO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Usuario:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(recibo.nombreUsuario, style: pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(height: 5),
                      pw.Text("No. Medidor:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(recibo.numeroMedidor, style: pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Periodo:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(recibo.periodo, style: pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(height: 5),
                      pw.Text("Fecha Emisión:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('dd/MM/yyyy').format(recibo.fechaEmision)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // 3. TABLA DE DETALLES
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                cellAlignment: pw.Alignment.centerLeft,
                data: <List<String>>[
                  <String>['Concepto', 'Detalle'],
                  <String>['Consumo Registrado', '${recibo.consumoM3} m³'],
                  <String>['Tarifa Base', 'Estándar'],
                ],
              ),
              
              pw.SizedBox(height: 10),

              // 4. TOTAL A PAGAR (Alineado a la derecha)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("TOTAL A PAGAR: ", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text("\$${recibo.montoTotal.toStringAsFixed(2)} MXN", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                ],
              ),

              pw.Spacer(),
              
              // 5. PIE DE PÁGINA
              pw.Divider(),
              pw.Center(
                child: pw.Text("Gracias por su pago puntual. Este documento es un comprobante oficial.", 
                style: pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    // Esto abre la vista previa de impresión
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Recibo_${recibo.periodo}_${recibo.numeroMedidor}',
    );
  }
}