import 'dart:async'; 
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'create_receipt_screen.dart';
import 'admin/register_meter_screen.dart';
import 'admin/meter_detail_screen.dart';
import 'admin/admin_reports_screen.dart'; 
import 'admin/reading_route_screen.dart';
import 'admin/expenses_admin_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  StreamSubscription? _reportesSubscription;
  StreamSubscription? _comprobantesSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _escucharAlertas();
  }

  // --- SISTEMA DE ALERTAS ---
  void _escucharAlertas() {
    _reportesSubscription = FirebaseFirestore.instance
        .collection('reports')
        .where('estado', isEqualTo: 'Pendiente')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          try {
            Timestamp ts = change.doc.get('fechaReporte');
            if (DateTime.now().difference(ts.toDate()).inSeconds < 30) {
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text("¡NUEVA FUGA REPORTADA!")));
            }
          } catch (e) {}
        }
      }
    });

    _comprobantesSubscription = FirebaseFirestore.instance.collection('receipts')
        .where('pagado', isEqualTo: false)
        .where('comprobanteUrl', isNotEqualTo: '')
        .snapshots().listen((snapshot) {
       for (var change in snapshot.docChanges) {
         if (change.type == DocumentChangeType.modified) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.blue, content: Text("¡Comprobante recibido!")));
         }
       }
    });
  }

  // --- FUNCIONES DE ACCIÓN ---
  void _confirmarBorrar(BuildContext context, String titulo, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text("¿Estás seguro? No se puede deshacer."),
        actions: [
          TextButton(child: Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
          TextButton(child: Text("Eliminar", style: TextStyle(color: Colors.red)), onPressed: () { onConfirm(); Navigator.pop(ctx); }),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarRecibo(BuildContext context, ReceiptModel recibo) {
    final _consumoCtrl = TextEditingController(text: recibo.consumoM3.toString());
    final _montoCtrl = TextEditingController(text: recibo.montoTotal.toString());
    final _periodoCtrl = TextEditingController(text: recibo.periodo);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar Recibo"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _periodoCtrl, decoration: InputDecoration(labelText: "Periodo")),
            TextField(controller: _consumoCtrl, decoration: InputDecoration(labelText: "Consumo"), keyboardType: TextInputType.number),
            TextField(controller: _montoCtrl, decoration: InputDecoration(labelText: "Monto"), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(child: Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
          FilledButton(child: Text("Guardar"), onPressed: () {
              _dbService.editarRecibo(recibo.id, double.tryParse(_consumoCtrl.text)??0, double.tryParse(_montoCtrl.text)??0, _periodoCtrl.text);
              Navigator.pop(ctx);
          })
        ],
      ),
    );
  }

  void _mostrarDialogoEditarMedidor(BuildContext context, UserModel user) {
    final _nombreCtrl = TextEditingController(text: user.nombre);
    final _medidorCtrl = TextEditingController(text: user.numeroMedidor);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar Medidor"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _nombreCtrl, decoration: InputDecoration(labelText: "Nombre")),
            TextField(controller: _medidorCtrl, decoration: InputDecoration(labelText: "Medidor")),
        ]),
        actions: [
          TextButton(child: Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
          FilledButton(child: Text("Guardar"), onPressed: () {
              _dbService.editarUsuario(user.uid, _nombreCtrl.text, _medidorCtrl.text, user.direccion ?? '');
              Navigator.pop(ctx);
          })
        ],
      ),
    );
  }

  void _revisarComprobante(BuildContext context, ReceiptModel recibo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
            recibo.comprobanteUrl.isNotEmpty
              ? Image.memory(base64Decode(recibo.comprobanteUrl), height: 300, fit: BoxFit.contain)
              : Text("Sin imagen"),
            SizedBox(height: 10),
            ElevatedButton(child: Text("VALIDAR PAGO"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () async {
               await _dbService.cambiarEstadoPago(recibo.id, true);
               Navigator.pop(ctx);
            })
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _reportesSubscription?.cancel();
    _comprobantesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA), // Fondo gris claro como la imagen
      appBar: AppBar(
        backgroundColor: Color(0xFF004D40), // Verde oscuro del AppBar
        title: Text("Panel Administrativo", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: Icon(Icons.account_balance_wallet), tooltip: "Gastos", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesAdminScreen()))),
          IconButton(icon: Icon(Icons.directions_walk), tooltip: "Ruta", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReadingRouteScreen()))),
          IconButton(icon: Icon(Icons.notifications_active), tooltip: "Reportes", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminReportsScreen())))
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: "RECIBOS", icon: Icon(Icons.receipt)), 
            Tab(text: "MEDIDORES", icon: Icon(Icons.water_drop))
          ]
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReceiptsList(), _buildMetersList()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF004D40),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("NUEVO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          if (_tabController.index == 0) Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReceiptScreen()));
          else Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterMeterScreen()));
        },
      ),
    );
  }

  // --- LISTA DE RECIBOS (ESTILO IDÉNTICO A LA FOTO) ---
  Widget _buildReceiptsList() {
    return StreamBuilder<List<ReceiptModel>>(
      stream: _dbService.obtenerTodosLosRecibos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        var recibos = snapshot.data!;
        
        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: recibos.length,
          itemBuilder: (context, index) {
            final recibo = recibos[index];
            bool pagado = recibo.pagado;
            bool tieneComprobante = recibo.comprobanteUrl.isNotEmpty;

            // Colores del icono circular
            Color bgIcono = pagado ? Colors.green.shade50 : Colors.orange.shade50;
            Color textIcono = pagado ? Colors.green.shade700 : Colors.orange.shade700;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white, // Fondo blanco puro
                borderRadius: BorderRadius.circular(20), // Bordes muy redondeados
                border: Border.all(color: Colors.grey.shade300, width: 1), // Borde gris suave
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: Offset(0, 2))]
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Círculo con símbolo $
                        Container(
                          width: 45, height: 45,
                          decoration: BoxDecoration(color: bgIcono, shape: BoxShape.circle),
                          child: Center(child: Text("\$", style: TextStyle(color: textIcono, fontSize: 22, fontWeight: FontWeight.bold))),
                        ),
                        SizedBox(width: 15),
                        
                        // Textos (Nombre y Detalle)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(recibo.nombreUsuario, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                              SizedBox(height: 4),
                              Text("${recibo.periodo} • \$${recibo.montoTotal}", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                              if (tieneComprobante && !pagado)
                                Text("Revisión Pendiente", style: TextStyle(color: Colors.orange[800], fontSize: 11, fontWeight: FontWeight.bold))
                            ],
                          ),
                        ),

                        // Switch
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: pagado,
                            activeColor: Colors.green,
                            onChanged: (val) async => await _dbService.cambiarEstadoPago(recibo.id, val),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Línea divisoria
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

                  // Botones de Acción (Texto azul y rojo con icono)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (tieneComprobante)
                          TextButton.icon(
                            icon: Icon(Icons.visibility, size: 18, color: Colors.blue),
                            label: Text("Ver Foto", style: TextStyle(color: Colors.blue)),
                            onPressed: () => _revisarComprobante(context, recibo),
                          ),
                        
                        Spacer(),

                        TextButton.icon(
                          icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                          label: Text("Editar", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          onPressed: () => _mostrarDialogoEditarRecibo(context, recibo),
                        ),
                        
                        SizedBox(width: 10),

                        TextButton.icon(
                          icon: Icon(Icons.delete, size: 18, color: Colors.redAccent),
                          label: Text("Eliminar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          onPressed: () => _confirmarBorrar(context, "Borrar Recibo", () => _dbService.eliminarRecibo(recibo.id)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- LISTA DE MEDIDORES (ESTILO IDÉNTICO A LA FOTO) ---
  Widget _buildMetersList() {
    return StreamBuilder<List<UserModel>>(
      stream: _dbService.obtenerTodosLosMedidores(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        var users = snapshot.data!;
        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, i) {
            final user = users[i];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: Offset(0, 2))]
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 45, height: 45,
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.water_drop, color: Colors.blue.shade700),
                    ),
                    title: Text(user.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text("Medidor: ${user.numeroMedidor}"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeterDetailScreen(usuario: user))),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                          label: Text("Editar", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          onPressed: () => _mostrarDialogoEditarMedidor(context, user),
                        ),
                        SizedBox(width: 10),
                        TextButton.icon(
                          icon: Icon(Icons.delete, size: 18, color: Colors.redAccent),
                          label: Text("Eliminar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          onPressed: () => _confirmarBorrar(context, "Borrar Usuario", () => _dbService.eliminarUsuario(user.uid)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}