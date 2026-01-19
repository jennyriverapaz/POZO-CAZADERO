import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatelessWidget {
  final DatabaseService _db = DatabaseService();

  Color _getColor(String estado) {
    if (estado == 'Resuelto') return Colors.green;
    if (estado == 'En Reparación') return Colors.orange;
    return Colors.red;
  }

  void _mostrarImagen(BuildContext context, String base64String) {
    if (base64String.isEmpty) return;
    showDialog(
      context: context, 
      builder: (_) => Dialog(
        child: Image.memory(base64Decode(base64String), fit: BoxFit.contain)
      )
    );
  }

  // --- NUEVA FUNCIÓN: CONFIRMAR ELIMINACIÓN ---
  void _confirmarEliminar(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Eliminar Reporte"),
        content: Text("¿Estás seguro de que quieres borrar este reporte permanentemente?"),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () {
              _db.eliminarReporte(id); // Llamamos al servicio
              Navigator.pop(ctx); // Cerramos la alerta
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reporte eliminado")));
            },
          ),
        ],
      ),
    );
  }
  // ---------------------------------------------

  void _cambiarEstado(BuildContext context, ReportModel reporte) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Cambiar Estado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListTile(leading: Icon(Icons.timelapse, color: Colors.red), title: Text("Pendiente"), onTap: () { _db.actualizarEstadoReporte(reporte.id, 'Pendiente'); Navigator.pop(context); }),
            ListTile(leading: Icon(Icons.build, color: Colors.orange), title: Text("En Reparación"), onTap: () { _db.actualizarEstadoReporte(reporte.id, 'En Reparación'); Navigator.pop(context); }),
            ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text("Resuelto"), onTap: () { _db.actualizarEstadoReporte(reporte.id, 'Resuelto'); Navigator.pop(context); }),
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestión de Reportes")),
      body: StreamBuilder<List<ReportModel>>(
        stream: _db.obtenerReportes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No hay reportes."));

          var reportes = snapshot.data!;

          return ListView.builder(
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final rep = reportes[index];
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  // FOTO
                  leading: GestureDetector(
                    onTap: () => _mostrarImagen(context, rep.fotoUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        width: 50, height: 50, color: Colors.grey[200],
                        child: rep.fotoUrl.isNotEmpty 
                          ? Image.memory(base64Decode(rep.fotoUrl), width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.broken_image, size: 30, color: Colors.grey),
                      ),
                    ),
                  ),
                  
                  // TEXTOS
                  title: Text(rep.tipo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rep.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                      Text(DateFormat('dd/MM HH:mm').format(rep.fechaReporte), style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  
                  // --- CAMBIO AQUÍ: FILA CON BOTÓN ESTADO + BOTÓN BORRAR ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
                    children: [
                      // Botón de Estado
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getColor(rep.estado),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size(70, 30)
                        ),
                        child: Text(rep.estado, style: TextStyle(color: Colors.white, fontSize: 10)),
                        onPressed: () => _cambiarEstado(context, rep),
                      ),
                      
                      SizedBox(width: 8), // Espacio
                      
                      // Botón de Eliminar
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.grey[400], size: 20),
                        tooltip: "Eliminar reporte",
                        onPressed: () => _confirmarEliminar(context, rep.id),
                      )
                    ],
                  ),
                  // ---------------------------------------------------------
                ),
              );
            },
          );
        },
      ),
    );
  }
}