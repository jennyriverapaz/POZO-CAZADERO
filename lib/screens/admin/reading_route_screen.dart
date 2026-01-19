import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class ReadingRouteScreen extends StatefulWidget {
  @override
  _ReadingRouteScreenState createState() => _ReadingRouteScreenState();
}

class _ReadingRouteScreenState extends State<ReadingRouteScreen> {
  final DatabaseService _db = DatabaseService();
  final _searchController = TextEditingController();
  
  PageController _pageController = PageController();
  
  // Listas para manejar el filtrado
  List<UserModel> _todosLosUsuarios = [];
  List<UserModel> _usuariosFiltrados = [];

  // Función para filtrar
  void _filtrarUsuarios(String query) {
    setState(() {
      if (query.isEmpty) {
        _usuariosFiltrados = _todosLosUsuarios;
      } else {
        _usuariosFiltrados = _todosLosUsuarios.where((user) {
          final nombre = user.nombre.toLowerCase();
          final medidor = user.numeroMedidor.toLowerCase();
          final input = query.toLowerCase();
          return nombre.contains(input) || medidor.contains(input);
        }).toList();
      }
      // Al filtrar, volvemos a la página 0 para evitar errores de índice
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  // Función para avanzar página (Se la pasamos al hijo)
  void _siguientePagina(int index) {
    if (index < _usuariosFiltrados.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Ruta finalizada!")));
    }
  }

  // --- LÓGICA DE EDICIÓN (Global) ---
  void _editarUsuario(UserModel user) {
    final _nombreCtrl = TextEditingController(text: user.nombre);
    final _medidorCtrl = TextEditingController(text: user.numeroMedidor);
    final _lecturaBaseCtrl = TextEditingController(text: user.ultimaLectura.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar Datos"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nombreCtrl, decoration: InputDecoration(labelText: "Nombre")),
              TextField(controller: _medidorCtrl, decoration: InputDecoration(labelText: "Medidor")),
              TextField(controller: _lecturaBaseCtrl, decoration: InputDecoration(labelText: "Lectura Base (Anterior)")),
            ],
          ),
        ),
        actions: [
          TextButton(child: Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            child: Text("Guardar"), 
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'nombre': _nombreCtrl.text,
                'numeroMedidor': _medidorCtrl.text,
                'ultimaLectura': double.tryParse(_lecturaBaseCtrl.text) ?? 0.0,
              });
              Navigator.pop(ctx);
            }
          )
        ],
      ),
    );
  }

  void _eliminarUsuario(String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Eliminar Vecino?"),
        content: Text("Se borrará de la lista permanentemente."),
        actions: [
          TextButton(child: Text("No"), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: Text("Sí, borrar", style: TextStyle(color: Colors.red)), 
            onPressed: () async {
              await _db.eliminarUsuario(uid);
              Navigator.pop(ctx);
            }
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ruta de Lectura"), elevation: 0),
      body: StreamBuilder<List<UserModel>>(
        stream: _db.obtenerRutaLectura(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          
          // Actualizar listas si cambia la base de datos (Ej: si editas o borras)
          if (_todosLosUsuarios.isEmpty || (_searchController.text.isEmpty && snapshot.data!.length != _todosLosUsuarios.length)) {
             _todosLosUsuarios = snapshot.data!;
             if (_searchController.text.isEmpty) {
               _usuariosFiltrados = _todosLosUsuarios;
             }
          }

          if (_usuariosFiltrados.isEmpty) return Center(child: Text("No hay usuarios."));

          return Column(
            children: [
              // Buscador
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: "Buscar usuario",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filtrarUsuarios('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                  ),
                  onChanged: _filtrarUsuarios,
                ),
              ),

              // AREA DE TRABAJO
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(), // Bloqueado para obligar a guardar
                  itemCount: _usuariosFiltrados.length,
                  itemBuilder: (context, index) {
                    // AQUÍ ESTÁ EL CAMBIO CLAVE:
                    // Usamos un Widget separado "ReadingCard" para cada página.
                    // Esto aísla el estado (texto escrito) de cada vecino.
                    return ReadingCard(
                      key: ValueKey(_usuariosFiltrados[index].uid), // Key única para evitar bugs de reciclaje
                      usuario: _usuariosFiltrados[index],
                      index: index,
                      total: _usuariosFiltrados.length,
                      onNext: () => _siguientePagina(index),
                      onEdit: () => _editarUsuario(_usuariosFiltrados[index]),
                      onDelete: () => _eliminarUsuario(_usuariosFiltrados[index].uid),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------
// WIDGET INDEPENDIENTE: TARJETA DE LECTURA
// Al separar esto, el 'setState' solo afecta a esta tarjeta y no rompe el teclado.
// -----------------------------------------------------------------------
class ReadingCard extends StatefulWidget {
  final UserModel usuario;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReadingCard({
    Key? key, 
    required this.usuario, 
    required this.index, 
    required this.total,
    required this.onNext,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ReadingCardState createState() => _ReadingCardState();
}

class _ReadingCardState extends State<ReadingCard> {
  final DatabaseService _db = DatabaseService();
  // Este controlador es ÚNICO para esta tarjeta. Se crea nuevo para cada vecino.
  final TextEditingController _lecturaController = TextEditingController();
  
  double _consumoCalculado = 0;
  double _montoCalculado = 0;
  final double _precioPorM3 = 10.0; // Tarifa

  @override
  void dispose() {
    _lecturaController.dispose();
    super.dispose();
  }

  void _calcular(String val) {
    setState(() {
      double actual = double.tryParse(val) ?? 0;
      _consumoCalculado = actual - widget.usuario.ultimaLectura;
      if (_consumoCalculado < 0) _consumoCalculado = 0;
      _montoCalculado = _consumoCalculado * _precioPorM3;
    });
  }

  String _getPeriodoActual() {
    return DateFormat('MMMM yyyy').format(DateTime.now()); 
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Encabezado
          Text("Registro ${widget.index + 1} de ${widget.total}", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          
          // Datos Usuario + Botones de Edición
          Icon(Icons.home, size: 50, color: Colors.blue),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(widget.usuario.nombre, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(width: 8),
              // Botón Editar
              InkWell(onTap: widget.onEdit, child: Icon(Icons.edit, color: Colors.blue, size: 24)),
              SizedBox(width: 15),
              // Botón Borrar
              InkWell(onTap: widget.onDelete, child: Icon(Icons.delete, color: Colors.red, size: 24)),
            ],
          ),
          Text("Medidor: ${widget.usuario.numeroMedidor}", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
          
          SizedBox(height: 30),

          // Tarjeta Input
          Card(
            elevation: 4,
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Lectura Anterior:", style: TextStyle(fontSize: 16)),
                      Text("${widget.usuario.ultimaLectura}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Divider(height: 30),
                  TextField(
                    controller: _lecturaController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: "LECTURA ACTUAL",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder()
                    ),
                    onChanged: _calcular, // El setState ocurre SOLO AQUÍ dentro
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Resumen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [Text("Consumo"), Text("${_consumoCalculado.toStringAsFixed(1)} m³", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
              Column(children: [Text("A Pagar"), Text("\$${_montoCalculado.toStringAsFixed(2)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green))]),
            ],
          ),

          SizedBox(height: 40),

          // Botón Guardar
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 60), backgroundColor: Colors.blue, foregroundColor: Colors.white),
            icon: Icon(Icons.save),
            label: Text("GUARDAR Y SIGUIENTE", style: TextStyle(fontSize: 18)),
            onPressed: () async {
              if (_lecturaController.text.isEmpty) return;
              
              double actual = double.parse(_lecturaController.text);
              
              // Validación
              if (actual < widget.usuario.ultimaLectura) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.orange, content: Text("⚠️ Lectura menor a la anterior.")));
              }

              await _db.procesarLectura(
                widget.usuario, 
                actual, 
                _consumoCalculado, 
                _montoCalculado, 
                _getPeriodoActual() 
              );

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text("Guardado"), duration: Duration(milliseconds: 500)));
              
              widget.onNext(); // Avanzar
            },
          ),
          
          TextButton(
            child: Text("Saltar esta casa"),
            onPressed: widget.onNext,
          )
        ],
      ),
    );
  }
}