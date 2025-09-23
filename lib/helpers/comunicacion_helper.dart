import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ComunicacionHelper {
  static Future<void> crear({
    required BuildContext context,
    required String hijoID,
    required VoidCallback onGuardado,
  }) async {
    final tituloController = TextEditingController();
    final contenidoController = TextEditingController();
    String? tipoSeleccionado;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva comunicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: contenidoController,
              decoration: const InputDecoration(labelText: 'Contenido'),
              maxLines: 3,
            ),
            DropdownButtonFormField<String>(
              value: null,
              items: ['General', 'Urgente', 'Recordatorio', 'Otro']
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (val) => tipoSeleccionado = val,
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () async {
              final titulo = tituloController.text.trim();
              final contenido = contenidoController.text.trim();
              final tipo = tipoSeleccionado ?? 'General';
              final fecha = DateTime.now().toIso8601String();
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

              await FirebaseFirestore.instance
                  .collection('comunicaciones')
                  .add({
                    'titulo': titulo,
                    'contenido': contenido,
                    'tipo': tipo,
                    'fecha': fecha,
                    'hijoID': hijoID,
                    'usuarioID': uid,
                  });

              Navigator.pop(context);
              onGuardado();
            },
          ),
        ],
      ),
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerPorHijo(
    String hijoID,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('comunicaciones')
        .where('hijoID', isEqualTo: hijoID)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'],
        'fecha': data['fecha'],
        'contenido': data['contenido'],
        'tipo': data['tipo'],
        'usuarioID': data['usuarioID'],
      };
    }).toList();
  }
}
