import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoPago {
  pendiente,
  parcial,
  completado,
  enDisputa,
  validacionPendiente,
}

class ModeloPago {
  final String id;
  final String hijoID;
  final String responsableID;
  final String responsableNombre;
  final String tipoGasto;
  final double importeTotal;
  final double cantidadPagada;
  final bool esCompartido;
  final double porcentajeResponsable;
  final bool esRecurrente;
  final DateTime? fechaLimite;
  final String? comentario;
  final String? urlJustificante;
  final String? nombreJustificante;
  final EstadoPago estado;
  final DateTime fechaRegistro;

  String estadoCalculado = 'Pendiente';

  ModeloPago({
    required this.id,
    required this.hijoID,
    required this.responsableID,
    required this.responsableNombre,
    required this.tipoGasto,
    required this.importeTotal,
    required this.cantidadPagada,
    required this.esCompartido,
    required this.porcentajeResponsable,
    required this.esRecurrente,
    required this.fechaLimite,
    required this.comentario,
    required this.urlJustificante,
    required this.nombreJustificante,
    required this.estado,
    required this.fechaRegistro,
  });

  factory ModeloPago.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModeloPago(
      id: doc.id,
      hijoID: data['hijoID'],
      responsableID: data['responsableID'],
      responsableNombre: data['responsableNombre'],
      tipoGasto: data['tipoGasto'],
      importeTotal: (data['importeTotal'] as num).toDouble(),
      cantidadPagada: (data['cantidadPagada'] as num).toDouble(),
      esCompartido: data['esCompartido'] ?? false,
      porcentajeResponsable: (data['porcentajeResponsable'] as num).toDouble(),
      esRecurrente: data['esRecurrente'] ?? false,
      fechaLimite: (data['fechaLimite'] != null)
          ? (data['fechaLimite'] as Timestamp).toDate()
          : null,
      comentario: data['comentario'],
      urlJustificante: data['urlJustificante'],
      nombreJustificante: data['nombreJustificante'],
      estado: EstadoPago.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoPago.pendiente,
      ),
      fechaRegistro: (data['fechaRegistro'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hijoID': hijoID,
      'responsableID': responsableID,
      'responsableNombre': responsableNombre,
      'tipoGasto': tipoGasto,
      'importeTotal': importeTotal,
      'cantidadPagada': cantidadPagada,
      'esCompartido': esCompartido,
      'porcentajeResponsable': porcentajeResponsable,
      'esRecurrente': esRecurrente,
      'fechaLimite': fechaLimite != null
          ? Timestamp.fromDate(fechaLimite!)
          : null,
      'comentario': comentario,
      'urlJustificante': urlJustificante,
      'nombreJustificante': nombreJustificante,
      'estado': estado.name,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
    };
  }
}
