import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String tipo; // "Fuga", "Falta de agua", "Calidad", "Otro"
  final String descripcion;
  final String fotoUrl; // La URL de la imagen en internet
  final String estado; // "Pendiente", "En Reparación", "Resuelto"
  final DateTime fechaReporte;

  ReportModel({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.fotoUrl,
    required this.estado,
    required this.fechaReporte,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      tipo: data['tipo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      fotoUrl: data['fotoUrl'] ?? '',
      estado: data['estado'] ?? 'Pendiente',
      fechaReporte: (data['fechaReporte'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'descripcion': descripcion,
      'fotoUrl': fotoUrl,
      'estado': estado,
      'fechaReporte': fechaReporte,
    };
  }
}