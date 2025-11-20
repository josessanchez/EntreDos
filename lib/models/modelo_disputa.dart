import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoDisputa { pendiente, aceptada, rechazada, resuelta }

class ModeloDisputa {
  final String id;
  final String pagoID;
  final String hijoID;
  final String creadorID;
  final String creadorNombre;
  final String? receptorID;
  final String? receptorNombre;
  final String motivo;
  final String? respuesta;
  final EstadoDisputa estado;
  final DateTime fechaCreacion;
  final DateTime? fechaResolucion;

  ModeloDisputa({
    required this.id,
    required this.pagoID,
    required this.hijoID,
    required this.creadorID,
    required this.creadorNombre,
    this.receptorID,
    this.receptorNombre,
    required this.motivo,
    this.respuesta,
    required this.estado,
    required this.fechaCreacion,
    this.fechaResolucion,
  });

  factory ModeloDisputa.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModeloDisputa(
      id: doc.id,
      pagoID: data['pagoID'],
      hijoID: data['hijoID'],
      creadorID: data['creadorID'],
      creadorNombre: data['creadorNombre'],
      receptorID: data['receptorID'],
      receptorNombre: data['receptorNombre'],
      motivo: data['motivo'],
      respuesta: data['respuesta'],
      estado: EstadoDisputa.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoDisputa.pendiente,
      ),
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaResolucion: data['fechaResolucion'] != null
          ? (data['fechaResolucion'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pagoID': pagoID,
      'hijoID': hijoID,
      'creadorID': creadorID,
      'creadorNombre': creadorNombre,
      'receptorID': receptorID,
      'receptorNombre': receptorNombre,
      'motivo': motivo,
      'respuesta': respuesta,
      'estado': estado.name,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaResolucion': fechaResolucion != null
          ? Timestamp.fromDate(fechaResolucion!)
          : null,
    };
  }
}
