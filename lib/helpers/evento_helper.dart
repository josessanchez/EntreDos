import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/evento_model.dart';
import '../widgets/formulario_evento.dart';

class EventoHelper {
  static Future<void> crear({
    required BuildContext context,
    required String hijoID,
    String hijoNombre = '',
    required VoidCallback onGuardado,
    String coleccionDestino = 'eventos',
  }) async {
    // Reuse the existing FormularioEvento dialog so attachments and upload
    // behavior match the full calendar screen.
    final messenger = ScaffoldMessenger.of(context);
    final resultado = await showDialog<Evento>(
      context: context,
      builder: (_) => FormularioEvento(
        hijoId: hijoID,
        hijoNombre: hijoNombre,
        coleccion: coleccionDestino,
      ),
    );

    if (resultado != null) {
      // The form already saved the event to Firestore and returned the Evento.
      // Just call the onGuardado callback and notify the user.
      onGuardado();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            '✅ Evento creado',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerPorHijo(
    String hijoID,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .where('hijoID', isEqualTo: hijoID)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'],
        'fecha': data['fecha'],
        'descripcion': data['descripcion'],
        'tipo': data['tipo'],
        'nombreArchivo': data['nombreArchivo'],
        'urlArchivo': data['urlArchivo'],
        'usuarioID': data['usuarioID'],
      };
    }).toList();
  }
}
