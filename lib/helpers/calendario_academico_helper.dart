import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarioAcademicoHelper {
  static Future<List<Map<String, dynamic>>> obtenerEventosYActividades(
    String hijoID, {
    String coleccionEventos = 'eventos',
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Firestore field naming has varied across the app ('hijoId' vs 'hijoID').
    // Query the canonical saved field name 'hijoId'. If your DB uses a
    // different field, update here accordingly.
    final eventosSnap = await firestore
        .collection(coleccionEventos)
        .where('hijoId', isEqualTo: hijoID)
        .get();

    final actividadesSnap = await firestore
        .collection('actividades')
        .where('hijoID', isEqualTo: hijoID)
        .get();

    final eventos = eventosSnap.docs.map((doc) {
      final data = doc.data();
      // Normalize fields: support both old keys (nombreArchivo/urlArchivo)
      // and new keys (documentoNombre/documentoUrl). Also convert
      // Timestamp fecha to ISO string to keep the consumer code stable.
      String fechaVal;
      final rawFecha = data['fecha'];
      if (rawFecha is Timestamp) {
        fechaVal = rawFecha.toDate().toIso8601String();
      } else if (rawFecha is DateTime) {
        fechaVal = rawFecha.toIso8601String();
      } else {
        fechaVal = rawFecha?.toString() ?? DateTime.now().toIso8601String();
      }

      final nombreArchivo = data['nombreArchivo'] ?? data['documentoNombre'];
      final urlArchivo = data['urlArchivo'] ?? data['documentoUrl'];
      final usuarioID = data['usuarioID'] ?? data['creadorUid'];
      final descripcion = data['descripcion'] ?? data['notas'] ?? '';

      return {
        'id': doc.id,
        'titulo': data['titulo'] ?? 'Evento sin título',
        'fecha': fechaVal,
        'descripcion': descripcion,
        'tipo': data['tipo'] ?? 'evento',
        'nombreArchivo': nombreArchivo,
        'urlArchivo': urlArchivo,
        // also expose the original keys for compatibility
        'documentoNombre': data['documentoNombre'],
        'documentoUrl': data['documentoUrl'],
        'usuarioID': usuarioID,
        'coleccion': coleccionEventos,
        'hijoNombre': data['hijoNombre'] ?? '',
        'hijoId': data['hijoId'] ?? data['hijoID'] ?? '',
      };
    });

    final actividades = actividadesSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'] ?? 'Actividad sin título',
        'fecha': data['fecha'],
        'tipo': 'actividad',
        'coleccion': 'actividades',
      };
    });

    final combinados = [...eventos, ...actividades];

    combinados.sort((a, b) => a['fecha'].compareTo(b['fecha']));

    return combinados;
  }
}
