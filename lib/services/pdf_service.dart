import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/receipt_model.dart'; // Asegúrate de que esta ruta sea correcta

class PdfService {
  Future<void> imprimirRecibo(ReceiptModel recibo) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40), // Márgenes típicos de impresión
        build: (pw.Context context) {
          
          // --- FUNCIÓN AUXILIAR PARA CREAR LAS "CELDAS" TIPO EXCEL ---
          pw.Widget buildCell(
            String text, {
            int flex = 1,
            bool isBold = false,
            pw.Alignment align = pw.Alignment.centerLeft,
            double fontSize = 10,
            double? height,
          }) {
            return pw.Expanded(
              flex: flex,
              child: pw.Container(
                height: height,
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5, color: PdfColors.black),
                ),
                alignment: align,
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    fontSize: fontSize,
                  ),
                ),
              ),
            );
          }

          // --- FUNCIÓN AUXILIAR PARA LA TABLA DE CONCEPTOS ---
          pw.Widget buildConceptRow(String concepto, String importe) {
            return pw.Row(
              children: [
                buildCell(concepto, flex: 2, isBold: true),
                buildCell(importe, flex: 1, align: pw.Alignment.centerRight),
                buildCell("", flex: 2), // Espacio en blanco de la derecha
              ],
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. ENCABEZADO: RECIBO DE PAGO
              pw.Container(
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text("RECIBO DE PAGO", style: pw.TextStyle(fontSize: 10)),
              ),

              // 2. PERIODO GIGANTE
              pw.Container(
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: const pw.BorderSide(width: 0.5), 
                    right: const pw.BorderSide(width: 0.5), 
                    bottom: const pw.BorderSide(width: 0.5)
                  )
                ),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  recibo.periodo.toUpperCase(), 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
                ),
              ),

              // 3. MES DE FACTURACION Y MEDIDOR
              pw.Row(
                children: [
                  buildCell("MES DE FACTURACION", flex: 2, isBold: true),
                  buildCell("MEDIDOR", flex: 2, align: pw.Alignment.center, isBold: true),
                  buildCell(recibo.numeroMedidor, flex: 1, align: pw.Alignment.center, isBold: true, fontSize: 16),
                ]
              ),

              // 4. DATOS DEL CLIENTE
              pw.Row(
                children: [
                  buildCell("NOMBRE", flex: 2, isBold: true),
                  buildCell(recibo.nombreUsuario.toUpperCase(), flex: 3, align: pw.Alignment.center, isBold: true, fontSize: 12),
                ]
              ),
              pw.Row(
                children: [
                  buildCell("DIRECCION", flex: 2, isBold: true),
                  buildCell("CONOCIDO", flex: 3, align: pw.Alignment.center), // *Placeholder*
                ]
              ),
              pw.Row(
                children: [
                  buildCell("# DE MEDIDOR", flex: 2, isBold: true),
                  buildCell(recibo.numeroMedidor, flex: 3, align: pw.Alignment.center),
                ]
              ),

              // 5. LECTURAS
              pw.Row(
                children: [
                  buildCell("LECTURA ANTERIOR", flex: 2, isBold: true),
                  buildCell("0", flex: 1, align: pw.Alignment.center), // *Placeholder*
                  buildCell("LECTURA ACTUAL", flex: 2, isBold: true, align: pw.Alignment.center),
                  buildCell("0", flex: 1, align: pw.Alignment.center), // *Placeholder*
                ]
              ),

              // 6. CONSUMOS M3
              pw.Row(
                children: [
                  buildCell("M3 DE CONSUMO\nACTUAL", flex: 2, isBold: true, align: pw.Alignment.center),
                  buildCell("${recibo.consumoM3} M3", flex: 3, align: pw.Alignment.center, isBold: true, fontSize: 14),
                ]
              ),

              // 7. TABLA DE CONCEPTOS
              pw.Row(
                children: [
                  buildCell("CONCEPTO", flex: 2, isBold: true),
                  buildCell("IMPORTE", flex: 1, isBold: true, align: pw.Alignment.center),
                  buildCell("", flex: 2), 
                ]
              ),
              buildConceptRow("CONSUMO ACTUAL", "\$ ${recibo.montoTotal.toStringAsFixed(2)}"),
              buildConceptRow("ADEUDO ANTERIOR", "\$ -"),
              buildConceptRow("RECARGOS", "\$ -"),
              buildConceptRow("EXTRAS", "\$ -"),
              buildConceptRow("FALTA ASAMBLEA", "\$ -"),
              buildConceptRow("DRENAJE", "\$ -"), // Si el drenaje es fijo, lo podemos sumar al modelo luego.

              // 8. TOTAL A PAGAR
              pw.Row(
                children: [
                  buildCell("TOTAL A PAGAR", flex: 2, isBold: true),
                  buildCell("\$ ${recibo.montoTotal.toStringAsFixed(2)}", flex: 1, align: pw.Alignment.centerRight, isBold: true, fontSize: 16),
                  buildCell("", flex: 2),
                ]
              ),

              // 9. NOTA (Caja grande)
              pw.Row(
                children: [
                  buildCell("NOTA:", flex: 1, isBold: true, align: pw.Alignment.topLeft, height: 60),
                  buildCell("", flex: 4, height: 60), // Espacio para escribir
                ]
              ),

              // 10. FECHAS Y HORARIOS (Placeholders por ahora)
              pw.Row(
                children: [
                  buildCell("PERIODO DE PAGO", flex: 2, isBold: true),
                  buildCell("INICIO", flex: 1, align: pw.Alignment.center),
                  buildCell("AL", flex: 1, align: pw.Alignment.center, isBold: true),
                  buildCell("FIN", flex: 1, align: pw.Alignment.center),
                ]
              ),
              pw.Row(
                children: [
                  buildCell("FECHA DE PAGO", flex: 2, isBold: true),
                  buildCell("SÁBADO", flex: 3, align: pw.Alignment.center),
                ]
              ),
              pw.Row(
                children: [
                  buildCell("HORARIOS", flex: 2),
                  buildCell("10:00 - 15:00 HRS", flex: 3, align: pw.Alignment.center),
                ]
              ),

              pw.SizedBox(height: 10),

              // 11. PIE DE PÁGINA
              pw.Center(
                child: pw.Text(
                  "PARA CUALQUIER ACLARACION TRAER RECIBO ANTERIOR",
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.SizedBox(height: 20),

              // 12. LOGOS (Marcadores de posición)
              // Aquí pondremos las imágenes cuando las subas a tu proyecto
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text("[Espacio para Logo Gota]"),
                  pw.Text("[Espacio para Código SAT]"),
                ]
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Recibo_${recibo.periodo}_${recibo.numeroMedidor}',
    );
  }
}