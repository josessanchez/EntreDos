import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ActividadHelper {
  static Future<void> crear({
    required BuildContext context,
    required String hijoID,
    required VoidCallback onGuardado,
  }) async {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    String? tipoSeleccionado;
    FilePickerResult? archivoSeleccionado;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva actividad escolar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            DropdownButtonFormField<String>(
              value: null,
              items: ['Refuerzo', 'Taller', 'Cultural', 'Otro']
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (val) => tipoSeleccionado = val,
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Adjuntar archivo'),
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
              final titulo = tituloController.text.trim();
              final descripcion = descripcionController.text.trim();
              final tipo = tipoSeleccionado ?? 'Otro';
              final fecha = DateTime.now().toIso8601String();
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              String? urlArchivo;
              String? nombreArchivo;

              if (archivoSeleccionado != null) {
                final archivo = archivoSeleccionado!.files.first;
                final ref = FirebaseStorage.instance.ref(
                  'actividades/${archivo.name}',
                );
                await ref.putData(archivo.bytes!);
                urlArchivo = await ref.getDownloadURL();
                nombreArchivo = archivo.name;
              }

              await FirebaseFirestore.instance.collection('actividades').add({
                'titulo': titulo,
                'descripcion': descripcion,
                'tipo': tipo,
                'fecha': fecha,
                'hijoID': hijoID,
                'usuarioID': uid,
                'nombreArchivo': nombreArchivo,
                'urlArchivo': urlArchivo,
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
        .collection('actividades')
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
