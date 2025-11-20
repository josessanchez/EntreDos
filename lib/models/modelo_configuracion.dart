import 'package:cloud_firestore/cloud_firestore.dart';

class ModeloConfiguracion {
  final String tipoCustodia;
  final bool divisionFlexible;
  final String notasPersonalizadas;
  final List<String> gastosCompartidos;
  final List<String> gastosIndividuales;

  ModeloConfiguracion({
    required this.tipoCustodia,
    required this.divisionFlexible,
    required this.notasPersonalizadas,
    required this.gastosCompartidos,
    required this.gastosIndividuales,
  });

  factory ModeloConfiguracion.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModeloConfiguracion(
      tipoCustodia: data['tipoCustodia'] ?? '',
      divisionFlexible: data['divisionFlexible'] ?? false,
      notasPersonalizadas: data['notasPersonalizadas'] ?? '',
      gastosCompartidos: List<String>.from(data['gastosCompartidos'] ?? []),
      gastosIndividuales: List<String>.from(data['gastosIndividuales'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipoCustodia': tipoCustodia,
      'divisionFlexible': divisionFlexible,
      'notasPersonalizadas': notasPersonalizadas,
      'gastosCompartidos': gastosCompartidos,
      'gastosIndividuales': gastosIndividuales,
    };
  }
}
