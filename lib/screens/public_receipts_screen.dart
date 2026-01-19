import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../services/database_service.dart';
import 'receipt_detail_screen.dart'; // IMPORTAR LA NUEVA PANTALLA

class PublicReceiptsScreen extends StatelessWidget {
  final String numeroMedidor;
  final DatabaseService _dbService = DatabaseService();

  PublicReceiptsScreen({required this.numeroMedidor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medidor: $numeroMedidor")),
      body: StreamBuilder<List<ReceiptModel>>(
        stream: _dbService.buscarRecibosPorMedidor(numeroMedidor),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error de conexión."));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No se encontraron recibos."));

          var recibos = snapshot.data!;
          
          return ListView.builder(
            itemCount: recibos.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final recibo = recibos[index];
              
              // Estado
              bool pagado = recibo.pagado;
              bool enRevision = !pagado && recibo.comprobanteUrl.isNotEmpty;

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: pagado ? Colors.green : (enRevision ? Colors.orange : Colors.grey.shade300),
                    width: 1.5
                  ),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  // ACCIÓN PRINCIPAL: IR AL DETALLE
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => ReceiptDetailScreen(recibo: recibo))
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Icono de estado
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: pagado ? Colors.green.shade50 : (enRevision ? Colors.orange.shade50 : Colors.grey.shade100),
                            shape: BoxShape.circle
                          ),
                          child: Icon(
                            pagado ? Icons.check_circle : (enRevision ? Icons.access_time_filled : Icons.description),
                            color: pagado ? Colors.green : (enRevision ? Colors.orange : Colors.grey)
                          ),
                        ),
                        SizedBox(width: 16),
                        
                        // Información
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recibo.periodo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text(
                                pagado ? "PAGADO" : (enRevision ? "EN REVISIÓN" : "PENDIENTE"),
                                style: TextStyle(
                                  color: pagado ? Colors.green : (enRevision ? Colors.orange : Colors.red),
                                  fontSize: 12, fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Flechita "Ver más"
                        Icon(Icons.chevron_right, color: Colors.grey)
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}