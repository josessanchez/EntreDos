import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

class AusenciaHelper {
  static Future<void> crear({
    required BuildContext context,
    required String hijoID,
    required VoidCallback onGuardado,
  }) async {
    final motivoController = TextEditingController();
    final observacionesController = TextEditingController();
    String? categoriaSeleccionada;
    String? justificacionSeleccionada;
    DateTime? fechaSeleccionada;
    FilePickerResult? archivoSeleccionado;

    final categorias = ['Médica', 'Viaje', 'Otro'];
    final justificaciones = ['Justificada', 'Injustificada'];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar ausencia'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  items: categorias
                      .map(
                        (categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => categoriaSeleccionada = val,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
                DropdownButtonFormField<String>(
                  value: justificacionSeleccionada,
                  items: justificaciones
                      .map(
                        (estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => justificacionSeleccionada = val,
                  decoration: const InputDecoration(
                    labelText: '¿Está justificada?',
                  ),
                ),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del motivo',
                  ),
                ),
                TextField(
                  controller: observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    fechaSeleccionada == null
                        ? 'Seleccionar fecha y hora'
                        : '${fechaSeleccionada!.day}/${fechaSeleccionada!.month} ${fechaSeleccionada!.hour}:${fechaSeleccionada!.minute.toString().padLeft(2, '0')}',
                  ),
                  onPressed: () async {
                    final dialogContext = context;
                    final fecha = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha != null) {
                      final hora = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.now(),
                      );
                      if (hora != null) {
                        setState(() {
                          fechaSeleccionada = DateTime(
                            fecha.year,
                            fecha.month,
                            fecha.day,
                            hora.hour,
                            hora.minute,
                          );
                        });
                      }
                    }
                  },
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
              final motivo = motivoController.text.trim();
              final observaciones = observacionesController.text.trim();
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
                'fecha': Timestamp.fromDate(
                  fechaSeleccionada ?? DateTime.now(),
                ),
                'motivo': motivo,
                'tipo': categoriaSeleccionada ?? 'Otro',
                'justificada': justificacionSeleccionada == 'Justificada',
                'observaciones': observaciones,
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

  static Future<void> editar({
    required BuildContext context,
    required String ausenciaID,
    required Map<String, dynamic> datos,
    required VoidCallback onGuardado,
  }) async {
    final motivoController = TextEditingController(text: datos['motivo'] ?? '');
    final observacionesController = TextEditingController(
      text: datos['observaciones'] ?? '',
    );
    DateTime? fechaSeleccionada = datos['fechaInicio'];
    FilePickerResult? archivoSeleccionado;
    String? nombreArchivo = datos['nombreArchivo'];
    String? urlArchivo = datos['urlArchivo'];

    final categorias = ['Médica', 'Viaje', 'Otro'];
    final justificaciones = ['Justificada', 'Injustificada'];

    String? categoriaSeleccionada = categorias.contains(datos['tipo'])
        ? datos['tipo']
        : null;
    String? justificacionSeleccionada = (datos['justificada'] ?? false)
        ? 'Justificada'
        : 'Injustificada';
    if (!justificaciones.contains(justificacionSeleccionada)) {
      justificacionSeleccionada = null;
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar ausencia'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  items: categorias
                      .map(
                        (categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => categoriaSeleccionada = val,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                ),
                DropdownButtonFormField<String>(
                  value: justificacionSeleccionada,
                  items: justificaciones
                      .map(
                        (estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => justificacionSeleccionada = val,
                  decoration: const InputDecoration(
                    labelText: '¿Está justificada?',
                  ),
                ),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del motivo',
                  ),
                ),
                TextField(
                  controller: observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    fechaSeleccionada == null
                        ? 'Seleccionar fecha y hora'
                        : '${fechaSeleccionada!.day}/${fechaSeleccionada!.month} ${fechaSeleccionada!.hour}:${fechaSeleccionada!.minute.toString().padLeft(2, '0')}',
                  ),
                  onPressed: () async {
                    final dialogContext = context;
                    final fecha = await showDatePicker(
                      context: dialogContext,
                      initialDate: fechaSeleccionada ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (fecha != null) {
                      final hora = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(
                          fechaSeleccionada ?? DateTime.now(),
                        ),
                      );
                      if (hora != null) {
                        setState(() {
                          fechaSeleccionada = DateTime(
                            fecha.year,
                            fecha.month,
                            fecha.day,
                            hora.hour,
                            hora.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Reemplazar justificante'),
                  onPressed: () async {
                    archivoSeleccionado = await FilePicker.platform.pickFiles();
                  },
                ),
              ],
            ),
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
              final motivo = motivoController.text.trim();
              final observaciones = observacionesController.text.trim();
              String? nuevoNombreArchivo = nombreArchivo;
              String? nuevaUrlArchivo = urlArchivo;

              if (archivoSeleccionado != null) {
                final archivo = archivoSeleccionado!.files.first;
                final ref = FirebaseStorage.instance.ref(
                  'ausencias/${archivo.name}',
                );
                await ref.putData(archivo.bytes!);
                nuevaUrlArchivo = await ref.getDownloadURL();
                nuevoNombreArchivo = archivo.name;
              }

              await FirebaseFirestore.instance
                  .collection('ausencias')
                  .doc(ausenciaID)
                  .update({
                    'fechaInicio': Timestamp.fromDate(
                      fechaSeleccionada ?? DateTime.now(),
                    ),
                    'motivo': motivo,
                    'tipo': categoriaSeleccionada ?? 'Otro',
                    'justificada': justificacionSeleccionada == 'Justificada',
                    'observaciones': observaciones,
                    'nombreArchivo': nuevoNombreArchivo,
                    'urlArchivo': nuevaUrlArchivo,
                  });

              navigator.pop();
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
        'fechaInicio': (data['fecha'] as Timestamp).toDate(),
        'fechaFin': null,
        'motivo': data['motivo'],
        'tipo': data['tipo'],
        'justificada': data['justificada'] ?? false,
        'observaciones': data['observaciones'],
        'nombreArchivo': data['nombreArchivo'],
        'urlArchivo': data['urlArchivo'],
        'usuarioID': data['usuarioID'],
      };
    }).toList();
  }
}
