import 'package:cloud_firestore/cloud_firestore.dart';

class Examen {
  final String id;
  final String hijoId;
  final String asignatura;
  final DateTime fecha;
  final String tipo;
  final String observaciones;
  final String creadorUid;

  Examen({
    this.id = '',
    required this.hijoId,
    required this.asignatura,
    required this.fecha,
    required this.tipo,
    required this.observaciones,
    required this.creadorUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'hijoId': hijoId,
      'asignatura': asignatura,
      'fecha': Timestamp.fromDate(fecha),
      'tipo': tipo,
      'observaciones': observaciones,
      'creadorUid': creadorUid,
    };
  }

  static Examen fromSnapshot(DocumentSnapshot doc) {
    final datos = doc.data() as Map<String, dynamic>? ?? {};
    return Examen(
      id: doc.id,
      hijoId: datos['hijoId'] ?? '',
      asignatura: datos['asignatura'] ?? '',
      fecha: (datos['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipo: datos['tipo'] ?? '',
      observaciones: datos['observaciones'] ?? '',
      creadorUid: datos['creadorUid'] ?? '',
    );
  }
}