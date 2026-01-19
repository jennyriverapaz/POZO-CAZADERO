import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/receipt_model.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ReceiptDetailScreen extends StatefulWidget {
  final ReceiptModel recibo;

  const ReceiptDetailScreen({Key? key, required this.recibo}) : super(key: key);

  @override
  _ReceiptDetailScreenState createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  final PdfService _pdfService = PdfService();
  final DatabaseService _dbService = DatabaseService();
  bool _isUploading = false;

  // Reutilizamos la lógica de subir comprobante aquí
  Future<void> _subirComprobante() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        imageQuality: 40
      );

      if (image != null) {
        setState(() => _isUploading = true);
        var f = await image.readAsBytes();
        
        if (f.lengthInBytes > 800000) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Imagen muy pesada.")));
          setState(() => _isUploading = false);
          return;
        }

        String base64String = base64Encode(f);
        await _dbService.subirComprobante(widget.recibo.id, base64String);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text("Comprobante enviado exitosamente.")));
          setState(() => _isUploading = false);
          Navigator.pop(context); // Regresamos para actualizar la lista
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores según estado
    bool pagado = widget.recibo.pagado;
    bool revision = !pagado && widget.recibo.comprobanteUrl.isNotEmpty;
    Color estadoColor = pagado ? Colors.green : (revision ? Colors.orange : Colors.red);
    String estadoTexto = pagado ? "PAGADO" : (revision ? "EN REVISIÓN" : "PENDIENTE DE PAGO");

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo gris para resaltar la "hoja"
      appBar: AppBar(title: Text("Detalle del Recibo")),
      body: _isUploading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // --- LA HOJA DEL RECIBO (Simulación de Papel) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12, offset: Offset(0, 5))]
                ),
                child: Column(
                  children: [
                    // ENCABEZAOD
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.water_drop, size: 40, color: Colors.blue),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Comité de Agua", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Recibo Oficial", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ESTADO GRANDE
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: estadoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: estadoColor)
                              ),
                              child: Text(estadoTexto, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                          ),
                          SizedBox(height: 30),

                          // DATOS DEL USUARIO
                          _buildDetailRow("Usuario:", widget.recibo.nombreUsuario),
                          _buildDetailRow("Medidor:", widget.recibo.numeroMedidor),
                          _buildDetailRow("Periodo:", widget.recibo.periodo),
                          _buildDetailRow("Fecha Emisión:", DateFormat('dd/MM/yyyy').format(widget.recibo.fechaEmision)),
                          
                          Divider(height: 40),
                          
                          // DETALLE DE CONSUMO
                          Text("Detalles del Servicio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 10),
                          _buildDetailRow("Consumo Registrado:", "${widget.recibo.consumoM3} m³"),
                          _buildDetailRow("Servicio de Alcantarillado:", "Incluido"), // Ejemplo de dato extra
                          _buildDetailRow("Mantenimiento Red:", "Incluido"), // Ejemplo
                          
                          Divider(height: 40),

                          // TOTAL
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("TOTAL A PAGAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("\$${widget.recibo.montoTotal.toStringAsFixed(2)}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // PIE DE RECIBO DECORATIVO
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: 30),

              // --- BOTONES DE ACCIÓN ---
              
              // 1. DESCARGAR PDF
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("DESCARGAR PDF OFICIAL"),
                  onPressed: () => _pdfService.imprimirRecibo(widget.recibo),
                ),
              ),

              SizedBox(height: 15),

              // 2. SUBIR COMPROBANTE (Solo si debe)
              if (!pagado && !revision)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    icon: Icon(Icons.upload_file, color: Colors.blue),
                    label: Text("SUBIR COMPROBANTE DE PAGO", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    onPressed: _subirComprobante,
                  ),
                ),
                
              if (revision)
                Text("Tu comprobante está siendo revisado por el administrador.", style: TextStyle(color: Colors.orange[800], fontStyle: FontStyle.italic)),
                
              SizedBox(height: 20),
            ],
          ),
        ),
    );
  }

  // Widget auxiliar para filas de texto alineadas
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ],
      ),
    );
  }
}