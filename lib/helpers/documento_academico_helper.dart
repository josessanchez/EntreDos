import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DocumentoAcademicoHelper {
  static Future<List<Map<String, dynamic>>> obtenerPorHijo(
    String hijoID,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('rendimiento')
        .where('hijoID', isEqualTo: hijoID)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'titulo': data['titulo'],
        'fecha': data['fecha'],
        'observaciones': data['observaciones'],
        'nombreArchivo': data['nombreArchivo'],
        'urlArchivo': data['urlArchivo'],
        'usuarioID': data['usuarioID'],
      };
    }).toList();
  }

  static Future<void> subir({
    required BuildContext context,
    required String hijoID,
    required VoidCallback onGuardado,
  }) async {
    final tituloController = TextEditingController();
    final observacionesController = TextEditingController();
    FilePickerResult? archivoSeleccionado;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo documento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: observacionesController,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Seleccionar archivo'),
              onPressed: () async {
                archivoSeleccionado = await FilePicker.platform.pickFiles();
              },
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
              final navigator = Navigator.of(context);
              final titulo = tituloController.text.trim();
              final observaciones = observacionesController.text.trim();
              final fecha = DateTime.now().toIso8601String();
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              String? urlArchivo;
              String? nombreArchivo;

              if (archivoSeleccionado != null) {
                final archivo = archivoSeleccionado!.files.first;
                final ref = FirebaseStorage.instance.ref(
                  'rendimiento/${archivo.name}',
                );
                await ref.putData(archivo.bytes!);
                urlArchivo = await ref.getDownloadURL();
                nombreArchivo = archivo.name;
              }

              await FirebaseFirestore.instance.collection('rendimiento').add({
                'titulo': titulo,
                'observaciones': observaciones,
                'fecha': fecha,
                'hijoID': hijoID,
                'usuarioID': uid,
                'nombreArchivo': nombreArchivo,
                'urlArchivo': urlArchivo,
              });
              navigator.pop();
              onGuardado();
            },
          ),
        ],
      ),
    );
  }
}
