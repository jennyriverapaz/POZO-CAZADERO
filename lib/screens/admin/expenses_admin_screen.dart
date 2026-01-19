import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class ExpensesAdminScreen extends StatefulWidget {
  @override
  _ExpensesAdminScreenState createState() => _ExpensesAdminScreenState();
}

class _ExpensesAdminScreenState extends State<ExpensesAdminScreen> {
  final DatabaseService _db = DatabaseService();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Función para CREAR nuevo gasto
  void _guardarGasto() async {
    if (_formKey.currentState!.validate()) {
      await _db.agregarGasto(
        _conceptoController.text,
        double.parse(_montoController.text),
      );
      _conceptoController.clear();
      _montoController.clear();
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gasto registrado exitosamente")));
    }
  }

  // Función para EDITAR un gasto existente
  void _editarGastoExistente(String id) async {
    // Usamos el mismo formulario o uno nuevo, aquí uso validación directa
    // Nota: Como estamos en un Dialog diferente, usamos controladores locales o reseteamos
    // Para simplificar, en _mostrarDialogoEditar ya pre-cargamos los controladores.
    
    if (_conceptoController.text.isNotEmpty && _montoController.text.isNotEmpty) {
       await _db.editarGasto(
        id,
        _conceptoController.text,
        double.parse(_montoController.text),
      );
      _conceptoController.clear();
      _montoController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gasto actualizado")));
    }
  }

  // Ventana para CREAR
  void _mostrarFormularioCrear() {
    // Limpiamos antes de abrir
    _conceptoController.clear();
    _montoController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
          left: 20, right: 20, top: 20
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Registrar Nuevo Gasto", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              TextFormField(
                controller: _conceptoController,
                decoration: InputDecoration(labelText: "Concepto (Ej: Luz Bomba)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _montoController,
                decoration: InputDecoration(labelText: "Monto", prefixText: "\$ ", border: OutlineInputBorder()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarGasto,
                child: Text("GUARDAR GASTO"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ventana para EDITAR
  void _mostrarDialogoEditar(ExpenseModel gasto) {
    // Pre-cargamos los datos actuales
    _conceptoController.text = gasto.concepto;
    _montoController.text = gasto.monto.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar Gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _conceptoController, 
              decoration: InputDecoration(labelText: "Concepto")
            ),
            SizedBox(height: 15),
            TextField(
              controller: _montoController, 
              decoration: InputDecoration(labelText: "Monto", prefixText: "\$ "),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"), 
            onPressed: () {
              _conceptoController.clear();
              _montoController.clear();
              Navigator.pop(ctx);
            }
          ),
          FilledButton(
            child: Text("Guardar Cambios"),
            onPressed: () => _editarGastoExistente(gasto.id),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Administrar Gastos")),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Nuevo Gasto", style: TextStyle(color: Colors.white)),
        onPressed: _mostrarFormularioCrear,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _db.obtenerGastos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No hay gastos registrados"));
          }

          var gastos = snapshot.data!;

          return ListView.builder(
            itemCount: gastos.length,
            padding: EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final gasto = gastos[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50, 
                    child: Icon(Icons.money_off, color: Colors.red)
                  ),
                  title: Text(gasto.concepto, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(gasto.fecha)),
                  
                  // Fila con Precio, Editar y Borrar
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "-\$${gasto.monto.toStringAsFixed(2)}", 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      SizedBox(width: 10),
                      
                      // Botón Editar
                      IconButton(
                        icon: Icon(Icons.edit, size: 20, color: Colors.blue), 
                        tooltip: "Editar",
                        onPressed: () => _mostrarDialogoEditar(gasto)
                      ),
                      
                      // Botón Borrar
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey), 
                        tooltip: "Eliminar",
                        onPressed: () => _db.eliminarGasto(gasto.id)
                      )
                    ],
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