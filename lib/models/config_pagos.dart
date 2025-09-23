import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigPagos {
  final String tipoCustodia; // "Compartida", "No compartida", "Otro"
  final List<String> gastosCompartidos;
  final List<String> gastosIndividuales;
  final bool divisionFlexible; // Si permite diferentes porcentajes
  final String notasPersonalizadas;

  ConfigPagos({
    required this.tipoCustodia,
    required this.gastosCompartidos,
    required this.gastosIndividuales,
    required this.divisionFlexible,
    required this.notasPersonalizadas,
  });

  factory ConfigPagos.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConfigPagos(
      tipoCustodia: data['tipoCustodia'] ?? 'Compartida',
      gastosCompartidos: List<String>.from(data['gastosCompartidos'] ?? []),
      gastosIndividuales: List<String>.from(data['gastosIndividuales'] ?? []),
      divisionFlexible: data['divisionFlexible'] ?? true,
      notasPersonalizadas: data['notasPersonalizadas'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'tipoCustodia': tipoCustodia,
        'gastosCompartidos': gastosCompartidos,
        'gastosIndividuales': gastosIndividuales,
        'divisionFlexible': divisionFlexible,
        'notasPersonalizadas': notasPersonalizadas,
      };
}