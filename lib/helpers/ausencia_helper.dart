import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AusenciaHelper {
  static Future<void> crear({
    required BuildContext context,
    required String hijoID,
    required VoidCallback onGuardado,
  }) async {
    final motivoController = TextEditingController();
    final observacionesController = TextEditingController();
    String? tipoSeleccionado;
    FilePickerResult? archivoSeleccionado;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar ausencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
            DropdownButtonFormField<String>(
              value: null,
              items: ['Justificada', 'Injustificada', 'Médica', 'Otro']
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (val) => tipoSeleccionado = val,
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            TextField(
              controller: observacionesController,
              decoration: const InputDecoration(labelText: 'Observaciones'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Adjuntar justificante'),
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
              final motivo = motivoController.text.trim();
              final observaciones = observacionesController.text.trim();
              final tipo = tipoSeleccionado ?? 'Otro';
              final fecha = DateTime.now().toIso8601String();
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              String? urlArchivo;
              String? nombreArchivo;

              if (archivoSeleccionado != null) {
                final archivo = archivoSeleccionado!.files.first;
                final ref = FirebaseStorage.instance.ref(
                  'ausencias/${archivo.name}',
                );
                await ref.putData(archivo.bytes!);
                urlArchivo = await ref.getDownloadURL();
                nombreArchivo = archivo.name;
              }

              await FirebaseFirestore.instance.collection('ausencias').add({
                'fecha': fecha,
                'motivo': motivo,
                'tipo': tipo,
                'observaciones': observaciones,
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
        .collection('ausencias')
        .where('hijoID', isEqualTo: hijoID)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'fecha': data['fecha'],
        'motivo': data['motivo'],
        'tipo': data['tipo'],
        'observaciones': data['observaciones'],
        'nombreArchivo': data['nombreArchivo'],
        'urlArchivo': data['urlArchivo'],
        'usuarioID': data['usuarioID'],
      };
    }).toList();
  }
}
