import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/receipt_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class MeterDetailScreen extends StatelessWidget {
  final UserModel usuario;
  final DatabaseService _db = DatabaseService();

  MeterDetailScreen({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Historial: ${usuario.nombre}")),
      body: StreamBuilder<List<ReceiptModel>>(
        // Buscamos los recibos de este medidor
        stream: _db.buscarRecibosPorMedidor(usuario.numeroMedidor),
        builder: (context, snapshot) {
          
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          var recibos = snapshot.data!;
          // Ordenamos por fecha (del más viejo al más nuevo) para que la gráfica tenga sentido
          recibos.sort((a, b) => a.fechaEmision.compareTo(b.fechaEmision));

          if (recibos.isEmpty) return Center(child: Text("Sin historial de consumo"));

          return Column(
            children: [
              SizedBox(height: 20),
              Text("Historial de Consumo (m3)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              
              // --- GRÁFICA DE LÍNEA ---
              SizedBox(
                height: 250,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: true),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                      
                      lineBarsData: [
                        LineChartBarData(
                          // Mapeamos los recibos a puntos (X=Indice, Y=Consumo)
                          spots: recibos.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.consumoM3);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                        ),
                      ],
                      
                      titlesData: FlTitlesData(
                        // EJE INFERIOR (Meses)
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 1, // <--- CLAVE: Evita que se repitan los nombres
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < recibos.length) {
                                String texto = recibos[index].periodo;
                                // Si es muy largo, tomamos las primeras 3 letras
                                if (texto.length > 3) texto = texto.substring(0, 3);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(texto, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                        // EJE IZQUIERDO (Consumo)
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: TextStyle(fontSize: 10)),
                          )
                        ),
                        // Ocultar ejes superior y derecho
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
              ),
              
              Divider(),
              
              // --- LISTA DE RECIBOS ---
              Expanded(
                child: ListView.builder(
                  itemCount: recibos.length,
                  itemBuilder: (context, i) {
                     // Invertimos el orden para mostrar el más reciente arriba en la lista
                     var item = recibos[recibos.length - 1 - i]; 
                     
                     return ListTile(
                       dense: true,
                       leading: Icon(Icons.date_range, color: Colors.blueGrey),
                       title: Text(item.periodo, style: TextStyle(fontWeight: FontWeight.bold)),
                       subtitle: Text("Consumo: ${item.consumoM3} m³"),
                       trailing: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Text("\$${item.montoTotal}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                           Text(
                             item.pagado ? "PAGADO" : "PENDIENTE", 
                             style: TextStyle(fontSize: 10, color: item.pagado ? Colors.green : Colors.red)
                           ),
                         ],
                       ),
                     );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}