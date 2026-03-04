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
  final String direccion;
  final double lecturaAnterior;
  final double lecturaActual;
  final double adeudoAnterior;
  final double recargos;
  final double extras;
  final double faltaAsamblea;
  final double drenaje;

  ReceiptModel({
    required this.id,
    required this.userId,
    required this.nombreUsuario,
    required this.numeroMedidor,
    required this.fechaEmision,
    required this.consumoM3,
    required this.montoTotal,
    required this.periodo,
    required this.pagado,
    required this.comprobanteUrl,
    required this.direccion,
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.adeudoAnterior,
    required this.recargos,
    required this.extras,
    required this.faltaAsamblea,
    required this.drenaje,
  });

  factory ReceiptModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    // 🛠️ HERRAMIENTA SALVAVIDAS: Convierte lo que sea en número sin chocar
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ReceiptModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      nombreUsuario: data['nombreUsuario'] ?? '',
      numeroMedidor: data['numeroMedidor']?.toString() ?? '',
      fechaEmision: (data['fechaEmision'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodo: data['periodo'] ?? '',
      pagado: data['pagado'] ?? false,
      comprobanteUrl: data['comprobanteUrl'] ?? '',
      direccion: data['direccion'] ?? 'CONOCIDO',
      
      // Aplicando la protección a todos los números
      consumoM3: parseDouble(data['consumoM3']),
      montoTotal: parseDouble(data['montoTotal']),
      lecturaAnterior: parseDouble(data['lecturaAnterior']),
      lecturaActual: parseDouble(data['lecturaActual']),
      adeudoAnterior: parseDouble(data['adeudoAnterior']),
      recargos: parseDouble(data['recargos']),
      extras: parseDouble(data['extras']),
      faltaAsamblea: parseDouble(data['faltaAsamblea']),
      drenaje: parseDouble(data['drenaje']),
    );
  }

  // Esta función sirve para cuando guardas un recibo nuevo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombreUsuario': nombreUsuario,
      'numeroMedidor': numeroMedidor,
      'fechaEmision': Timestamp.fromDate(fechaEmision),
      'consumoM3': consumoM3,
      'montoTotal': montoTotal,
      'periodo': periodo,
      'pagado': pagado,
      'comprobanteUrl': comprobanteUrl,
      'direccion': direccion,
      'lecturaAnterior': lecturaAnterior,
      'lecturaActual': lecturaActual,
      'adeudoAnterior': adeudoAnterior,
      'recargos': recargos,
      'extras': extras,
      'faltaAsamblea': faltaAsamblea,
      'drenaje': drenaje,
    };
  }
}