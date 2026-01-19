import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import '../services/database_service.dart';
// 1. IMPORTAMOS EL SERVICIO DE NOTIFICACIONES
import '../services/notification_service.dart';

class CreateReportScreen extends StatefulWidget {
  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  
  String _tipoSeleccionado = 'Fuga de Agua';
  final List<String> _tipos = ['Fuga de Agua', 'Falta de Agua', 'Calidad del Agua', 'Otro'];
  
  Uint8List? _webImage;
  String? _base64Image;
  
  bool _isProcessing = false;
  String _statusMessage = ""; 

  Future<void> _seleccionarFoto() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = "Abriendo cámara/galería...";
      });

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 25 
      );
      
      if (image != null) {
        var f = await image.readAsBytes();
        
        // Límite de seguridad para Firestore (aprox 700kb)
        if (f.lengthInBytes > 700000) {
          setState(() {
            _isProcessing = false;
            _statusMessage = "Imagen muy pesada, intenta otra.";
          });
          return;
        }

        String base64String = base64Encode(f);
        
        setState(() {
          _webImage = f;
          _base64Image = base64String;
          _isProcessing = false;
          _statusMessage = "Imagen lista para enviar";
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = "";
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  void _enviarReporte() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
        _statusMessage = "Enviando reporte...";
      });

      // --- INICIO DEL PROCESO ---
      try {
        final reporte = ReportModel(
          id: '',
          tipo: _tipoSeleccionado,
          descripcion: _descController.text,
          fotoUrl: _base64Image ?? "", 
          estado: 'Pendiente',
          fechaReporte: DateTime.now(),
        );

        // PASO 1: GUARDAR EN LA BASE DE DATOS
        // Si esto falla, salta al 'catch' de abajo y muestra error.
        await _db.crearReporte(reporte).timeout(Duration(seconds: 15));

        // PASO 2: ENVIAR NOTIFICACIÓN (Aislado)
        // Lo ponemos en su propio try-catch. Si falla (común en web por CORS),
        // NO afecta al usuario, el reporte ya se guardó.
        try {
           print("Intentando notificar a admins...");
           await NotificationService().notifyAdminsOfNewReport(_tipoSeleccionado);
        } catch (pushError) {
           print("La notificación falló pero el reporte está a salvo: $pushError");
        }

        // PASO 3: ÉXITO
        if (mounted) {
           setState(() => _isProcessing = false);
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               backgroundColor: Colors.green, 
               content: Text("¡Reporte enviado exitosamente!")
             )
           );
        }
      } catch (e) {
        // ERROR AL GUARDAR EN BASE DE DATOS
        print("Error DB: $e");
        if (mounted) {
          setState(() {
             _isProcessing = false;
             _statusMessage = "No se pudo guardar: Verifica tu conexión o permisos.";
          });
        }
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reportar Problema")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(10),
                  color: _statusMessage.contains("Error") || _statusMessage.contains("No se pudo") 
                      ? Colors.red[100] 
                      : Colors.yellow[100],
                  child: Text(
                    _statusMessage, 
                    style: TextStyle(color: Colors.black87), 
                    textAlign: TextAlign.center
                  ),
                ),
              SizedBox(height: 10),

              DropdownButtonFormField(
                value: _tipoSeleccionado,
                items: _tipos.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _tipoSeleccionado = val.toString()),
                decoration: InputDecoration(labelText: "Tipo de Problema", border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Descripción", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'La descripción es obligatoria' : null,
              ),
              SizedBox(height: 20),

              GestureDetector(
                onTap: _isProcessing ? null : _seleccionarFoto,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _webImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_webImage!, fit: BoxFit.cover)
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            Text("Tocar para agregar foto (Opcional)", style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                ),
              ),
              
              if (_webImage != null)
                TextButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red, size: 18),
                  label: Text("Quitar foto", style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    setState(() {
                      _webImage = null;
                      _base64Image = null;
                      _statusMessage = "";
                    });
                  },
                ),

              SizedBox(height: 30),
              
              _isProcessing
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _enviarReporte,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text("ENVIAR REPORTE", style: TextStyle(fontSize: 18)),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    )
            ],
          ),
        ),
      ),
    );
  }
}