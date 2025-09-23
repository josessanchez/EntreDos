import 'package:cloud_firestore/cloud_firestore.dart';

class Pago {
  final String id;
  final String hijoID;
  final String tipo; // "Común" | "Privado"
  final String titulo;
  final double montoTotal;
  final String descripcion;
  final String observaciones;
  final String estado; // "Pendiente" | "Pagado" | "En disputa"
  final String motivoEstado;
  final DateTime fechaRegistro;
  final DateTime fechaCambioEstado;
  final String usuarioRegistroID;
  final String usuarioCambioID;
  final String? nombreArchivo;
  final String? urlArchivo;
  final Map<String, double> aportaciones; // uid → monto

  Pago({
    required this.id,
    required this.hijoID,
    required this.tipo,
    required this.titulo,
    required this.montoTotal,
    required this.descripcion,
    required this.observaciones,
    required this.estado,
    required this.motivoEstado,
    required this.fechaRegistro,
    required this.fechaCambioEstado,
    required this.usuarioRegistroID,
    required this.usuarioCambioID,
    required this.aportaciones,
    this.nombreArchivo,
    this.urlArchivo,
  });

  factory Pago.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final aportacionesRaw = data['aportaciones'] as Map<String, dynamic>? ?? {};
    final aportacionesConvertidas = aportacionesRaw.map((key, value) =>
        MapEntry(key, value is num ? value.toDouble() : 0.0));

    return Pago(
      id: doc.id,
      hijoID: data['hijoID'] ?? '',
      tipo: data['tipo'] ?? 'Común',
      titulo: data['titulo'] ?? '',
      montoTotal: (data['montoTotal'] ?? 0).toDouble(),
      descripcion: data['descripcion'] ?? '',
      observaciones: data['observaciones'] ?? '',
      estado: data['estado'] ?? 'Pendiente',
      motivoEstado: data['motivoEstado'] ?? '',
      fechaRegistro: (data['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaCambioEstado: (data['fechaCambioEstado'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usuarioRegistroID: data['usuarioRegistroID'] ?? '',
      usuarioCambioID: data['usuarioCambioID'] ?? '',
      nombreArchivo: data['nombreArchivo'],
      urlArchivo: data['urlArchivo'],
      aportaciones: aportacionesConvertidas,
    );
  }
}