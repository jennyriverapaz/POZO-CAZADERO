import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class CreateReceiptScreen extends StatefulWidget {
  @override
  _CreateReceiptScreenState createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  UserModel? _selectedUser;
  
  // Controladores originales
  final _periodoController = TextEditingController();
  final _consumoController = TextEditingController();
  final _montoController = TextEditingController();

  // --- NUEVOS CONTROLADORES ---
  final _direccionController = TextEditingController();
  final _lecturaAnteriorController = TextEditingController();
  final _lecturaActualController = TextEditingController();
  final _adeudoAnteriorController = TextEditingController();
  final _recargosController = TextEditingController();
  final _extrasController = TextEditingController();
  final _faltaAsambleaController = TextEditingController();
  final _drenajeController = TextEditingController();

  @override
  void dispose() {
    // Es buena práctica limpiar los controladores al cerrar la pantalla
    _periodoController.dispose();
    _consumoController.dispose();
    _montoController.dispose();
    _direccionController.dispose();
    _lecturaAnteriorController.dispose();
    _lecturaActualController.dispose();
    _adeudoAnteriorController.dispose();
    _recargosController.dispose();
    _extrasController.dispose();
    _faltaAsambleaController.dispose();
    _drenajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nuevo Recibo")),
      body: StreamBuilder<List<UserModel>>(
        stream: _db.obtenerTodosLosMedidores(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          
          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text("Buscar Vecino:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Autocomplete<UserModel>(
                    displayStringForOption: (option) => "${option.nombre} (${option.numeroMedidor})",
                    optionsBuilder: (textValue) {
                      if (textValue.text == '') return const Iterable<UserModel>.empty();
                      return snapshot.data!.where((user) => 
                        user.nombre.toLowerCase().contains(textValue.text.toLowerCase()) || 
                        user.numeroMedidor.contains(textValue.text));
                    },
                    onSelected: (selection) => setState(() => _selectedUser = selection),
                  ),
                  SizedBox(height: 20),
                  
                  // --- DATOS BÁSICOS ---
                  TextFormField(controller: _direccionController, decoration: InputDecoration(labelText: "Dirección (Opcional)")),
                  TextFormField(controller: _periodoController, decoration: InputDecoration(labelText: "Periodo (Ej. Enero 2024)"), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  
                  SizedBox(height: 20),
                  Text("Lecturas y Consumo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Divider(),
                  
                  // LECTURAS (En fila para ahorrar espacio)
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _lecturaAnteriorController, decoration: InputDecoration(labelText: "Lectura Anterior"), keyboardType: TextInputType.number)),
                      SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: _lecturaActualController, decoration: InputDecoration(labelText: "Lectura Actual"), keyboardType: TextInputType.number)),
                    ],
                  ),
                  TextFormField(controller: _consumoController, decoration: InputDecoration(labelText: "Consumo m3"), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  
                  SizedBox(height: 20),
                  Text("Cargos y Totales", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Divider(),

                  // CARGOS EXTRA (En filas)
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _adeudoAnteriorController, decoration: InputDecoration(labelText: "Adeudo Ant. \$"), keyboardType: TextInputType.number)),
                      SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: _recargosController, decoration: InputDecoration(labelText: "Recargos \$"), keyboardType: TextInputType.number)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _extrasController, decoration: InputDecoration(labelText: "Extras \$"), keyboardType: TextInputType.number)),
                      SizedBox(width: 10),
                      Expanded(child: TextFormField(controller: _faltaAsambleaController, decoration: InputDecoration(labelText: "Falta Asam. \$"), keyboardType: TextInputType.number)),
                    ],
                  ),
                  TextFormField(controller: _drenajeController, decoration: InputDecoration(labelText: "Drenaje \$"), keyboardType: TextInputType.number),
                  
                  SizedBox(height: 10),
                  // MONTO TOTAL
                  TextFormField(controller: _montoController, decoration: InputDecoration(labelText: "MONTO TOTAL A PAGAR \$", labelStyle: TextStyle(fontWeight: FontWeight.bold)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _selectedUser != null) {
                        
                        // --- GUARDAR CON TODOS LOS CAMPOS NUEVOS ---
                        await _db.agregarRecibo(ReceiptModel(
                          id: '', 
                          userId: _selectedUser!.uid, 
                          nombreUsuario: _selectedUser!.nombre, 
                          numeroMedidor: _selectedUser!.numeroMedidor,
                          fechaEmision: DateTime.now(), 
                          periodo: _periodoController.text,
                          consumoM3: double.tryParse(_consumoController.text) ?? 0, 
                          montoTotal: double.tryParse(_montoController.text) ?? 0, 
                          pagado: false,
                          comprobanteUrl: '',
                          // Nuevos datos (Si están vacíos, se pone 0 o texto por defecto)
                          direccion: _direccionController.text.isNotEmpty ? _direccionController.text : "CONOCIDO",
                          lecturaAnterior: double.tryParse(_lecturaAnteriorController.text) ?? 0,
                          lecturaActual: double.tryParse(_lecturaActualController.text) ?? 0,
                          adeudoAnterior: double.tryParse(_adeudoAnteriorController.text) ?? 0,
                          recargos: double.tryParse(_recargosController.text) ?? 0,
                          extras: double.tryParse(_extrasController.text) ?? 0,
                          faltaAsamblea: double.tryParse(_faltaAsambleaController.text) ?? 0,
                          drenaje: double.tryParse(_drenajeController.text) ?? 0,
                        ));
                        
                        Navigator.pop(context);
                      } else if (_selectedUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Por favor selecciona un vecino primero.")));
                      }
                    },
                    child: Text("GUARDAR RECIBO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}