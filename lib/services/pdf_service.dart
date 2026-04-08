import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../models/receipt_model.dart';
import '../services/api_service.dart';

class PdfService {
  final ApiService _apiService = ApiService();

  Future<void> imprimirRecibo(ReceiptModel recibo) async {
    // 1. Le pedimos el archivo PDF oficial a la API
    final List<int>? bytes = await _apiService.descargarTicketPdfBytes(recibo.id);

    if (bytes != null) {
      // 2. Convertimos los datos al formato que usa Flutter para imprimir
      final Uint8List pdfData = Uint8List.fromList(bytes);

      // 3. Abrimos la pantalla nativa del celular para Imprimir o Compartir el PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        // Le damos un nombre bonito al archivo por si el usuario lo guarda en su celular
        name: 'Ticket_${recibo.periodo.replaceAll(" ", "_")}',
      );
    } else {
      // Si por alguna razón de red falla la descarga
      print("Error: No se pudo descargar el ticket oficial del servidor.");
    }
  }
}