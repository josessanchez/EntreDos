import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarioAcademicoHelper {
  static Future<List<Map<String, dynamic>>> obtenerEventosYActividades(
    String hijoID,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final eventosSnap = await firestore
        .collection('eventos')
        .where('hijoID', isEqualTo: hijoID)
        .get();

    final actividadesSnap = await firestore
        .collection('actividades')
        .where('hijoID', isEqualTo: hijoID)
        .get();

    final eventos = eventosSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'] ?? 'Evento sin título',
        'fecha': data['fecha'],
        'descripcion': data['descripcion'] ?? '',
        'tipo': data['tipo'] ?? 'evento',
        'nombreArchivo': data['nombreArchivo'],
        'urlArchivo': data['urlArchivo'],
        'usuarioID': data['usuarioID'],
        'coleccion': 'eventos',
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
