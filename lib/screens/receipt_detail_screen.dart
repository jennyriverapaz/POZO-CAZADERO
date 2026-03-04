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
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  // --- Herramientas para dibujar la tabla estilo Excel ---

  Widget _buildGridRow(List<Widget> cells, {bool isLast = false, double minHeight = 25}) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.black, width: 1.0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {
    int flex = 1,
    bool rightBorder = true,
    bool bold = false,
    bool italic = false,
    double fontSize = 10,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: rightBorder ? Border(right: BorderSide(color: Colors.black, width: 1.0)) : null,
        ),
        alignment: alignment,
        child: Text(
          text,
          textAlign: alignment == Alignment.center ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            fontSize: fontSize,
            color: Colors.black,
            fontFamily: 'Arial', // Arial se parece más a Excel
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCell(double val, {int flex = 1, bool rightBorder = true}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: rightBorder ? Border(right: BorderSide(color: Colors.black, width: 1.0)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
            Text(val == 0 ? '-' : val.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool pagado = widget.recibo.pagado;
    bool revision = !pagado && widget.recibo.comprobanteUrl.isNotEmpty;
    Color estadoColor = pagado ? Colors.green : (revision ? Colors.orange : Colors.red);
    String estadoTexto = pagado ? "PAGADO" : (revision ? "EN REVISIÓN" : "PENDIENTE DE PAGO");

    double costoConsumo = widget.recibo.montoTotal - (widget.recibo.adeudoAnterior + widget.recibo.recargos + widget.recibo.extras + widget.recibo.faltaAsamblea + widget.recibo.drenaje);

    return Scaffold(
      backgroundColor: Colors.grey[200], 
      appBar: AppBar(title: Text("Detalle del Recibo")),
      body: _isUploading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              // ESTADO FLOTANTE (Para que el usuario sepa su status sin arruinar el diseño)
              Container(
                margin: EdgeInsets.only(bottom: 15),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: estadoColor, width: 2)
                ),
                child: Text(estadoTexto, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ),

              // --- LA TABLA EXACTA ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5), 
                ),
                child: Column(
                  children: [
                    // Fila 1: Título pequeño
                    _buildGridRow([
                      _buildCell("RECIBO DE PAGO", flex: 1, rightBorder: false, alignment: Alignment.center, fontSize: 9)
                    ]),
                    // Fila 2: MES GRANDE
                    _buildGridRow([
                      _buildCell(widget.recibo.periodo.toUpperCase(), flex: 1, rightBorder: false, bold: true, fontSize: 20, alignment: Alignment.center)
                    ], minHeight: 35),
                    
                    // --- Inicia cuadrícula de 10 columnas (Flex 4 + 3 + 3) ---
                    // Fila 3: Mes, Medidor
                    _buildGridRow([
                      _buildCell("MES DE FACTURACION\n", flex: 4, bold: true, alignment: Alignment.topLeft),
                      _buildCell("MEDIDOR", flex: 3, bold: true, alignment: Alignment.center),
                      _buildCell(widget.recibo.numeroMedidor, flex: 3, bold: true, rightBorder: false, alignment: Alignment.center, fontSize: 16),
                    ]),
                    // Fila 4: Nombre
                    _buildGridRow([
                      _buildCell("NOMBRE", flex: 4, bold: true),
                      _buildCell(widget.recibo.nombreUsuario.toUpperCase(), flex: 6, bold: true, italic: true, rightBorder: false, alignment: Alignment.center, fontSize: 12),
                    ]),
                    // Fila 5: Dirección
                    _buildGridRow([
                      _buildCell("DIRECCION", flex: 4, bold: true),
                      _buildCell(widget.recibo.direccion.toUpperCase(), flex: 6, rightBorder: false, alignment: Alignment.center),
                    ]),
                    // Fila 6: # Medidor
                    _buildGridRow([
                      _buildCell("# DE MEDIDOR", flex: 4, bold: true),
                      _buildCell(widget.recibo.numeroMedidor, flex: 6, rightBorder: false, alignment: Alignment.center),
                    ]),
                    // Fila 7: Lecturas (Ajustamos los Flex para que sumen 10)
                    _buildGridRow([
                      _buildCell("LECTURA ANTERIOR", flex: 3, bold: true),
                      _buildCell("${widget.recibo.lecturaAnterior.toInt()}", flex: 2, alignment: Alignment.center),
                      _buildCell("LECTURA ACTUAL", flex: 3, bold: true),
                      _buildCell("${widget.recibo.lecturaActual.toInt()}", flex: 2, rightBorder: false, alignment: Alignment.center),
                    ]),
                    // Fila 8: M3 Consumo
                    _buildGridRow([
                      _buildCell("M3 DE CONSUMO\nACTUAL", flex: 4, bold: true, alignment: Alignment.center),
                      _buildCell("     ${widget.recibo.consumoM3.toInt()}      M³", flex: 6, rightBorder: false, bold: true, fontSize: 16, alignment: Alignment.centerLeft),
                    ]),
                    // Fila 9: Títulos de Tabla
                    _buildGridRow([
                      _buildCell("CONCEPTO", flex: 4, bold: true),
                      _buildCell("IMPORTE", flex: 3, bold: true, alignment: Alignment.center),
                      _buildCell("", flex: 3, rightBorder: false),
                    ]),
                    
                    // --- CONCEPTOS ---
                    _buildGridRow([ _buildCell("CONSUMO ACTUAL", flex: 4, bold: true), _buildCurrencyCell(costoConsumo, flex: 3), _buildCell("", flex: 3, rightBorder: false) ]),
                    _buildGridRow([ _buildCell("ADEUDO ANTERIOR", flex: 4, bold: true), _buildCurrencyCell(widget.recibo.adeudoAnterior, flex: 3), _buildCell("", flex: 3, rightBorder: false) ]),
                    _buildGridRow([ _buildCell("RECARGOS", flex: 4, bold: true), _buildCurrencyCell(widget.recibo.recargos, flex: 3), _buildCell("", flex: 3, rightBorder: false) ]),
                    _buildGridRow([ _buildCell("EXTRAS", flex: 4, bold: true), _buildCurrencyCell(widget.recibo.extras, flex: 3), _buildCell("", flex: 3, rightBorder: false) ]),
                    _buildGridRow([ _buildCell("FALTA ASAMBLEA", flex: 4, bold: true), _buildCurrencyCell(widget.recibo.faltaAsamblea, flex: 3), _buildCell("", flex: 3, rightBorder: false) ]),
                    _buildGridRow([ _buildCell("DRENAJE", flex: 4, bold: true), _buildCurrencyCell(widget.recibo.drenaje, flex: 3), _buildCell("", flex: 3, rightBorder: false) ]),
                    
                    // Fila 10: TOTAL A PAGAR (Igualando el error de ortografía si es necesario, o lo puedes cambiar a "A PAGAR")
                    _buildGridRow([
                      _buildCell("TOTAL APAGAR", flex: 4, bold: true),
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                              Text(widget.recibo.montoTotal.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                            ],
                          ),
                        ),
                      )
                    ]),
                    
                    // Fila 11: NOTA
                    _buildGridRow([
                      _buildCell("NOTA:\n\n\n\n", flex: 4, bold: true, alignment: Alignment.topLeft),
                      _buildCell("0", flex: 6, rightBorder: false, alignment: Alignment.topLeft),
                    ]),

                    // Fila 12: PERIODO DE PAGO
                    _buildGridRow([
                      _buildCell("PERIODO DE PAGO", flex: 4, bold: true),
                      _buildCell(DateFormat('dd-MMM-yy', 'es').format(widget.recibo.fechaEmision).toLowerCase(), flex: 2, bold: true, alignment: Alignment.center),
                      _buildCell("AL", flex: 1, bold: true, alignment: Alignment.center),
                      _buildCell(DateFormat('dd-MMM-yy', 'es').format(widget.recibo.fechaEmision.add(Duration(days: 30))).toLowerCase(), flex: 3, rightBorder: false, bold: true, alignment: Alignment.center),
                    ]),

                    // Fila 13: FECHA DE PAGO 1
                    _buildGridRow([
                      _buildCell("FECHA DE PAGO", flex: 4, bold: true),
                      _buildCell("SABADO 31/ENERO/2026", flex: 6, bold: true, rightBorder: false, alignment: Alignment.center, fontSize: 11),
                    ]),
                    _buildGridRow([
                      _buildCell("HORARIOS", flex: 4),
                      _buildCell("10:00-15:00 HRS", flex: 6, rightBorder: false, alignment: Alignment.center),
                    ]),

                    // Fila 14: FECHA DE PAGO 2
                    _buildGridRow([
                      _buildCell("FECHA DE PAGO", flex: 4, bold: true),
                      _buildCell("MIERCOLES 04/FEBRERO/2026", flex: 6, bold: true, rightBorder: false, alignment: Alignment.center, fontSize: 11),
                    ]),
                    _buildGridRow([
                      _buildCell("HORARIOS", flex: 4),
                      _buildCell("16:00 A 19:00 HRS", flex: 6, rightBorder: false, alignment: Alignment.center),
                    ]),

                    // PIE DE PÁGINA: Aclaraciones, Logo y Cédula
                    Container(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text(
                            "PARA CUALQUIER ACLARACION TRAER RECIBO ANTERIOR",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[900]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Placeholder para el Logo
                              Column(
                                children: [
                                  Icon(Icons.water_drop, size: 40, color: Colors.blue),
                                  Text("POZO EL CAZADERO, A.C.", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              // Placeholder para la Cédula Fiscal (Reemplazar con Image.asset cuando tengas la foto real)
                              Container(
                                width: 150,
                                height: 80,
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey), color: Colors.grey[200]),
                                alignment: Alignment.center,
                                child: Text("Cédula SAT\n(Imagen aquí)", textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: 20),

              // --- BOTONES DE ACCIÓN (Fuera de la hoja) ---
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

              if (!pagado && !revision)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white,
                    ),
                    icon: Icon(Icons.upload_file, color: Colors.blue),
                    label: Text("SUBIR COMPROBANTE DE PAGO", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    onPressed: _subirComprobante,
                  ),
                ),
                
              if (revision)
                Text("Tu comprobante está siendo revisado por el administrador.", style: TextStyle(color: Colors.orange[800], fontStyle: FontStyle.italic)),
                
              SizedBox(height: 30),
            ],
          ),
        ),
    );
  }
}