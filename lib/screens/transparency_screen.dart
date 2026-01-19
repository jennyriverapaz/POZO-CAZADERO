import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Asegúrate de tener este paquete
import '../models/receipt_model.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';

class TransparencyScreen extends StatelessWidget {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Portal de Transparencia")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text("Balance Financiero", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Estado actual de la caja", style: TextStyle(color: Colors.grey)),
            
            // Stream anidado: Escuchamos Recibos Y Gastos
            StreamBuilder<List<ReceiptModel>>(
              stream: _db.obtenerTodosLosRecibos(),
              builder: (context, snapshotRecibos) {
                return StreamBuilder<List<ExpenseModel>>(
                  stream: _db.obtenerGastos(),
                  builder: (context, snapshotGastos) {
                    
                    if (!snapshotRecibos.hasData || !snapshotGastos.hasData) {
                      return SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                    }

                    // 1. CALCULAR INGRESOS (Suma de recibos PAGADOS)
                    double totalIngresos = 0;
                    for (var r in snapshotRecibos.data!) {
                      if (r.pagado) totalIngresos += r.montoTotal;
                    }

                    // 2. CALCULAR GASTOS (Suma de egresos)
                    double totalGastos = 0;
                    for (var g in snapshotGastos.data!) {
                      totalGastos += g.monto;
                    }

                    // 3. SALDO NETO
                    double saldo = totalIngresos - totalGastos;

                    return Column(
                      children: [
                        // TARJETA DE SALDO EN CAJA
                        Container(
                          margin: EdgeInsets.all(20),
                          padding: EdgeInsets.all(25),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: saldo >= 0 
                                ? [Colors.green.shade400, Colors.green.shade700] 
                                : [Colors.red.shade400, Colors.red.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26, offset: Offset(0, 5))]
                          ),
                          child: Column(
                            children: [
                              Text("SALDO DISPONIBLE", style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2)),
                              SizedBox(height: 10),
                              Text("\$${saldo.toStringAsFixed(2)}", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                        // GRÁFICA DE BARRAS COMPARATIVA
                        SizedBox(height: 20),
                        Text("Ingresos vs Gastos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(
                          height: 250, 
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
                            child: BarChart(
                              BarChartData(
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(show: true, drawVerticalLine: false),
                                titlesData: FlTitlesData(
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (val, meta) => Text(val.compact(), style: TextStyle(fontSize: 10)))),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        if (val == 0) return Padding(padding: EdgeInsets.only(top: 8), child: Text("Ingresos", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));
                                        if (val == 1) return Padding(padding: EdgeInsets.only(top: 8), child: Text("Gastos", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
                                        return Text("");
                                      }
                                    )
                                  ),
                                ),
                                barGroups: [
                                  BarChartGroupData(x: 0, barRods: [
                                    BarChartRodData(toY: totalIngresos, color: Colors.green, width: 40, borderRadius: BorderRadius.circular(6), backDrawRodData: BackgroundBarChartRodData(show: true, toY: (totalIngresos > totalGastos ? totalIngresos : totalGastos) * 1.2, color: Colors.grey.shade100))
                                  ]),
                                  BarChartGroupData(x: 1, barRods: [
                                    BarChartRodData(toY: totalGastos, color: Colors.red, width: 40, borderRadius: BorderRadius.circular(6), backDrawRodData: BackgroundBarChartRodData(show: true, toY: (totalIngresos > totalGastos ? totalIngresos : totalGastos) * 1.2, color: Colors.grey.shade100))
                                  ]),
                                ]
                              )
                            ),
                          ),
                        ),

                        Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(alignment: Alignment.centerLeft, child: Text("Últimos Movimientos (Gastos):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        ),
                        
                        // LISTA DE ÚLTIMOS GASTOS
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: snapshotGastos.data!.length > 5 ? 5 : snapshotGastos.data!.length, // Top 5
                          itemBuilder: (context, index) {
                            var g = snapshotGastos.data![index];
                            return ListTile(
                              title: Text(g.concepto),
                              trailing: Text("-\$${g.monto}", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              leading: Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                              dense: true,
                            );
                          },
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Extensión para formatear números grandes en la gráfica (1k, 1M)
extension CompactNumber on double {
  String compact() {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K';
    return this.toStringAsFixed(0);
  }
}