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
    final observacionesController = TextEditingController();
    String tipoSeleccionado = 'Boletín de notas (trimestre)';
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
                  style: const TextStyle(fontSize: 16),
                  items:
                      [
                            'Boletín de notas (trimestre)',
                            'Boletín de notas (anual)',
                          ]
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(
                                tipo,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      tipoSeleccionado = val ?? 'Boletín de notas (trimestre)';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                if (tipoSeleccionado.contains('Boletín')) ...[
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
                                  style: const TextStyle(fontSize: 16),
                                  decoration: const InputDecoration(
                                    labelText: 'Asignatura',
                                    labelStyle: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: entry.value['nota'],
                                  style: const TextStyle(fontSize: 16),
                                  decoration: const InputDecoration(
                                    labelText: 'Nota',
                                    labelStyle: TextStyle(fontSize: 16),
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

                if (tipoSeleccionado != 'Boletín de notas (anual)')
                  DropdownButtonFormField<String>(
                    value: trimestreSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Trimestre',
                      labelStyle: TextStyle(fontSize: 16),
                    ),
                    style: const TextStyle(fontSize: 16),
                    items:
                        const ['1º Trimestre', '2º Trimestre', '3º Trimestre']
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: TextStyle(fontSize: 16)),
                              ),
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
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final observaciones = observacionesController.text.trim();
                final fecha = DateTime.now().toIso8601String();
                String? urlArchivo;
                String? nombreArchivo;

                if (archivoSeleccionado?.files.first != null) {
                  final archivo = archivoSeleccionado!.files.first;
                  final ref = FirebaseStorage.instance.ref(
                    'rendimiento/${archivo.name}',
                  );
                  await ref.putData(archivo.bytes!);
                  urlArchivo = await ref.getDownloadURL();
                  nombreArchivo = archivo.name;
                }

                final Map<String, dynamic> datos = {
                  'tipo': tipoSeleccionado,
                  'observaciones': observaciones,
                  'fecha': fecha,
                  'nombreArchivo': nombreArchivo,
                  'urlArchivo': urlArchivo,
                  'usuarioID': uid,
                  'hijoID': hijoID,
                };

                if (tipoSeleccionado.contains('Boletín')) {
                  datos['notasBoletin'] = notasBoletin
                      .map(
                        (fila) => {
                          'asignatura': fila['asignatura']!.text.trim(),
                          'nota':
                              double.tryParse(fila['nota']!.text.trim()) ?? 0.0,
                        },
                      )
                      .toList();
                  if (tipoSeleccionado == 'Boletín de notas (trimestre)') {
                    datos['trimestre'] = trimestreSeleccionado;
                  }
                }

                // Validación para boletines duplicados y ordenados
                if (tipoSeleccionado == 'Boletín de notas (trimestre)') {
                  final query = FirebaseFirestore.instance
                      .collection('rendimiento')
                      .where('hijoID', isEqualTo: hijoID)
                      .where('tipo', isEqualTo: 'Boletín de notas (trimestre)');

                  final existing = await query.get();
                  final trimestresExistentes = existing.docs
                      .map((doc) => doc['trimestre'] as String)
                      .toList();

                  if (trimestresExistentes.contains(trimestreSeleccionado)) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ya existe un boletín para ese trimestre.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (trimestreSeleccionado == '2º Trimestre' &&
                      !trimestresExistentes.contains('1º Trimestre')) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes añadir primero el boletín del 1º Trimestre.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (trimestreSeleccionado == '3º Trimestre' &&
                      !trimestresExistentes.contains('2º Trimestre')) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Debes añadir primero el boletín del 2º Trimestre.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                }

                await FirebaseFirestore.instance
                    .collection('rendimiento')
                    .add(datos);

                navigator.pop();
                onGuardado();
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> editar({
    required BuildContext context,
    required Map<String, dynamic> doc,
    required VoidCallback onGuardado,
  }) async {
    final observacionesController = TextEditingController(
      text: doc['observaciones'] ?? '',
    );

    String tipoSeleccionado = doc['tipo'] ?? 'Boletín de notas (trimestre)';
    String trimestreSeleccionado = doc['trimestre'] ?? '1º Trimestre';
    final List<Map<String, TextEditingController>> notasBoletin = [];

    if (doc['notasBoletin'] != null && doc['notasBoletin'] is List) {
      for (var entrada in doc['notasBoletin']) {
        notasBoletin.add({
          'asignatura': TextEditingController(
            text: entrada['asignatura'] ?? '',
          ),
          'nota': TextEditingController(
            text: entrada['nota']?.toString() ?? '',
          ),
        });
      }
    } else {
      notasBoletin.add({
        'asignatura': TextEditingController(),
        'nota': TextEditingController(),
      });
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar registro de rendimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  items:
                      [
                            'Boletín de notas (trimestre)',
                            'Boletín de notas (anual)',
                          ]
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      tipoSeleccionado = val ?? 'Boletín de notas (trimestre)';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                if (tipoSeleccionado.contains('Boletín')) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notas del boletín',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: notasBoletin.asMap().entries.map((entry) {
                      return Row(
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
                      );
                    }).toList(),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir asignatura'),
                    onPressed: () {
                      setState(() {
                        notasBoletin.add({
                          'asignatura': TextEditingController(),
                          'nota': TextEditingController(),
                        });
                      });
                    },
                  ),
                ],
                if (tipoSeleccionado != 'Boletín de notas (anual)')
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
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Guardar cambios'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final observaciones = observacionesController.text.trim();
                final fecha = DateTime.now().toIso8601String();

                final Map<String, dynamic> datos = {
                  'tipo': tipoSeleccionado,
                  'observaciones': observaciones,
                  'fecha': fecha,
                  'usuarioID': doc['usuarioID'],
                  'hijoID': doc['hijoID'],
                };

                if (tipoSeleccionado.contains('Boletín')) {
                  datos['notasBoletin'] = notasBoletin
                      .map(
                        (fila) => {
                          'asignatura': fila['asignatura']!.text.trim(),
                          'nota':
                              double.tryParse(fila['nota']!.text.trim()) ?? 0.0,
                        },
                      )
                      .toList();
                  if (tipoSeleccionado == 'Boletín de notas (trimestre)') {
                    datos['trimestre'] = trimestreSeleccionado;
                  }
                }

                await FirebaseFirestore.instance
                    .collection('rendimiento')
                    .doc(doc['id'])
                    .update(datos);

                navigator.pop();
                onGuardado();
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> eliminar(String id) async {
    await FirebaseFirestore.instance.collection('rendimiento').doc(id).delete();
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
        'hijoID': data['hijoID'],
      };
    }).toList();
  }
}
