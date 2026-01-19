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
  final _consumoController = TextEditingController();
  final _montoController = TextEditingController();
  final _periodoController = TextEditingController();

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
                      return snapshot.data!.where((user) => user.nombre.toLowerCase().contains(textValue.text.toLowerCase()) || user.numeroMedidor.contains(textValue.text));
                    },
                    onSelected: (selection) => setState(() => _selectedUser = selection),
                  ),
                  SizedBox(height: 20),
                  TextFormField(controller: _periodoController, decoration: InputDecoration(labelText: "Periodo"), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _consumoController, decoration: InputDecoration(labelText: "Consumo m3"), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  TextFormField(controller: _montoController, decoration: InputDecoration(labelText: "Monto \$"), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && _selectedUser != null) {
                        await _db.agregarRecibo(ReceiptModel(
                          id: '', userId: _selectedUser!.uid, nombreUsuario: _selectedUser!.nombre, numeroMedidor: _selectedUser!.numeroMedidor,
                          fechaEmision: DateTime.now(), consumoM3: double.tryParse(_consumoController.text) ?? 0, montoTotal: double.tryParse(_montoController.text) ?? 0, periodo: _periodoController.text
                        ));
                        Navigator.pop(context);
                      }
                    },
                    child: Text("GUARDAR"),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}