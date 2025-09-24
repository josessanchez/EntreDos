import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class RendimientoHelper {
  static Future<void> crear({
    required BuildContext context,
    required String hijoID,
    required VoidCallback onGuardado,
  }) async {
    final tituloController = TextEditingController();
    final observacionesController = TextEditingController();
    final notaController = TextEditingController();
    final asignaturaController = TextEditingController();
    String tipoSeleccionado = 'nota';
    String trimestreSeleccionado = '1º Trimestre';
    FilePickerResult? archivoSeleccionado;

    final List<Map<String, TextEditingController>> notasBoletin = [];

    void agregarFilaBoletin() {
      notasBoletin.add({
        'asignatura': TextEditingController(),
        'nota': TextEditingController(),
      });
    }

    agregarFilaBoletin();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo registro de rendimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  items: ['nota', 'boletín', 'informe']
                      .map(
                        (tipo) =>
                            DropdownMenuItem(value: tipo, child: Text(tipo)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      tipoSeleccionado = val ?? 'nota';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                if (tipoSeleccionado == 'nota') ...[
                  TextField(
                    controller: asignaturaController,
                    decoration: const InputDecoration(labelText: 'Asignatura'),
                  ),
                  TextField(
                    controller: notaController,
                    decoration: const InputDecoration(labelText: 'Nota'),
                    keyboardType: TextInputType.number,
                  ),
                ],
                if (tipoSeleccionado == 'boletín') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notas del boletín',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: notasBoletin
                        .asMap()
                        .entries
                        .map(
                          (entry) => Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: entry.value['asignatura'],
                                  decoration: const InputDecoration(
                                    labelText: 'Asignatura',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: entry.value['nota'],
                                  decoration: const InputDecoration(
                                    labelText: 'Nota',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    notasBoletin.removeAt(entry.key);
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir asignatura'),
                    onPressed: () {
                      setState(() {
                        agregarFilaBoletin();
                      });
                    },
                  ),
                ],
                if (tipoSeleccionado == 'nota' || tipoSeleccionado == 'boletín')
                  DropdownButtonFormField<String>(
                    value: trimestreSeleccionado,
                    decoration: const InputDecoration(labelText: 'Trimestre'),
                    items:
                        const ['1º Trimestre', '2º Trimestre', '3º Trimestre']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        trimestreSeleccionado = val ?? '1º Trimestre';
                      });
                    },
                  ),
                TextField(
                  controller: observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 3,
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
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final titulo = tituloController.text.trim();
                final observaciones = observacionesController.text.trim();
                final nota = notaController.text.trim();
                final asignatura = asignaturaController.text.trim();
                final fecha = DateTime.now().toIso8601String();
                String? urlArchivo;
                String? nombreArchivo;

                if (archivoSeleccionado != null) {
                  final archivo = archivoSeleccionado?.files.first;
                  if (archivo != null) {
                    final ref = FirebaseStorage.instance.ref(
                      'rendimiento/${archivo.name}',
                    );
                    await ref.putData(archivo.bytes!);
                    urlArchivo = await ref.getDownloadURL();
                    nombreArchivo = archivo.name;
                  }
                }

                final Map<String, dynamic> datos = {
                  'titulo': titulo,
                  'tipo': tipoSeleccionado,
                  'observaciones': observaciones,
                  'fecha': fecha,
                  'nombreArchivo': nombreArchivo,
                  'urlArchivo': urlArchivo,
                  'usuarioID': uid,
                  'hijoID': hijoID,
                };

                if (tipoSeleccionado == 'nota') {
                  datos['nota'] = double.tryParse(nota) ?? 0.0;
                  datos['asignatura'] = asignatura;
                  datos['trimestre'] = trimestreSeleccionado;
                }

                if (tipoSeleccionado == 'boletín') {
                  datos['notasBoletin'] = notasBoletin
                      .map(
                        (fila) => {
                          'asignatura': fila['asignatura']!.text.trim(),
                          'nota':
                              double.tryParse(fila['nota']!.text.trim()) ?? 0.0,
                        },
                      )
                      .toList();
                  datos['trimestre'] = trimestreSeleccionado;
                }

                await FirebaseFirestore.instance
                    .collection('rendimiento')
                    .add(datos);

                Navigator.pop(context);
                onGuardado();
              },
            ),
          ],
        ),
      ),
    );
  }

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
        'tipo': data['tipo'],
        'fecha': data['fecha'],
        'observaciones': data['observaciones'],
        'nota': data['nota'],
        'asignatura': data['asignatura'],
        'notasBoletin': data['notasBoletin'],
        'trimestre': data['trimestre'],
        'nombreArchivo': data['nombreArchivo'],
        'urlArchivo': data['urlArchivo'],
        'usuarioID': data['usuarioID'],
      };
    }).toList();
  }
}
