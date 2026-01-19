import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptModel {
  final String id;
  final String userId;
  final String nombreUsuario;
  final String numeroMedidor;
  final DateTime fechaEmision;
  final double consumoM3;
  final double montoTotal;
  final String periodo;
  final bool pagado;
  final String comprobanteUrl;

  ReceiptModel({
    required this.id,
    required this.userId,
    required this.nombreUsuario,
    required this.numeroMedidor,
    required this.fechaEmision,
    required this.consumoM3,
    required this.montoTotal,
    required this.periodo,
    this.pagado = false,
    this.comprobanteUrl = '',
  });

  factory ReceiptModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ReceiptModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      nombreUsuario: data['nombreUsuario'] ?? '',
      numeroMedidor: data['numeroMedidor'].toString(),
      fechaEmision: (data['fechaEmision'] as Timestamp).toDate(),
      consumoM3: (data['consumoM3'] ?? 0).toDouble(),
      montoTotal: (data['montoTotal'] ?? 0).toDouble(),
      periodo: data['periodo'] ?? '',
      pagado: data['pagado'] ?? false,
      comprobanteUrl: data['comprobanteUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombreUsuario': nombreUsuario,
      'numeroMedidor': numeroMedidor,
      'fechaEmision': fechaEmision,
      'consumoM3': consumoM3,
      'montoTotal': montoTotal,
      'periodo': periodo,
      'pagado': pagado,
      'comprobanteUrl': comprobanteUrl,
    };
  }
}