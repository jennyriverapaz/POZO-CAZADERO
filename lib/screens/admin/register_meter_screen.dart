import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class RegisterMeterScreen extends StatefulWidget {
  @override
  _RegisterMeterScreenState createState() => _RegisterMeterScreenState();
}

class _RegisterMeterScreenState extends State<RegisterMeterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _medidor = TextEditingController();
  final _direccion = TextEditingController();
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrar Medidor")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _nombre, decoration: InputDecoration(labelText: "Nombre"), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            TextFormField(controller: _medidor, decoration: InputDecoration(labelText: "Medidor"), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            TextFormField(controller: _direccion, decoration: InputDecoration(labelText: "Dirección")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              if (_formKey.currentState!.validate()) {
                _db.registrarMedidor(_nombre.text, _medidor.text, _direccion.text);
                Navigator.pop(context);
              }
            }, child: Text("GUARDAR"))
          ]),
        ),
      ),
    );
  }
}