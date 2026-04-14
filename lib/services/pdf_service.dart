import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
// Eliminamos la importación del receipt_model.dart

class PdfService {
  final ApiService _apiService = ApiService();

  // Ahora recibimos el JSON dinámico directamente (Map<String, dynamic>)
  Future<void> imprimirRecibo(Map<String, dynamic> recibo) async {
    // Extraemos el ID y el nombre del periodo usando las llaves exactas de tu JSON
    final String reciboId = recibo['recibo_id'] ?? '';
    final String periodoLabel = recibo['periodo_label'] ?? 'Recibo';

    if (reciboId.isEmpty) {
      print("Error: El recibo no tiene un ID válido.");
      return;
    }

    // 1. Le pedimos el archivo PDF oficial a la API usando el reciboId
    final List<int>? bytes = await _apiService.descargarTicketPdfBytes(reciboId);

    if (bytes != null) {
      // 2. Convertimos los datos al formato que usa Flutter para imprimir
      final Uint8List pdfData = Uint8List.fromList(bytes);

      // 3. Abrimos la pantalla nativa del celular para Imprimir o Compartir el PDF
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        // Le damos un nombre bonito al archivo (ej. Ticket_ABRIL_DE_2026)
        name: 'Ticket_${periodoLabel.replaceAll(" ", "_")}',
      );
    } else {
      // Si por alguna razón de red falla la descarga o el token expiró
      print("Error: No se pudo descargar el ticket oficial del servidor.");
    }
  }
}