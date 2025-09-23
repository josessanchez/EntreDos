import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/models/config_pagos.dart';
import 'package:entredos/helpers/pago_helper.dart';

Future<void> formularioPago({
  required BuildContext context,
  required String hijoID,
  Map<String, dynamic>? datosIniciales,
  VoidCallback? onGuardado,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final tituloCtrl = TextEditingController(text: datosIniciales?['titulo'] ?? '');
  final montoCtrl = TextEditingController(text: datosIniciales?['montoTotal']?.toString() ?? '');
  final descripcionCtrl = TextEditingController(text: datosIniciales?['descripcion'] ?? '');
  final observacionesCtrl = TextEditingController(text: datosIniciales?['observaciones'] ?? '');
  final motivoCtrl = TextEditingController(text: datosIniciales?['motivoEstado'] ?? '');
  final aportacionInicial = datosIniciales?['aportaciones']?[uid]?.toString() ?? '';
  final aportacionCtrl = TextEditingController(text: aportacionInicial);

  PlatformFile? archivo;
  String estadoSeleccionado = datosIniciales?['estado'] ?? 'Pendiente';
  String tipoSeleccionado = datosIniciales?['tipo'] ?? 'Común';

  ConfigPagos? config;

  final doc = await FirebaseFirestore.instance
      .collection('hijos')
      .doc(hijoID)
      .collection('configuracion')
      .doc('pagos')
      .get();

  if (doc.exists) {
    config = ConfigPagos.fromSnapshot(doc);
  }

  await showDialog(
    context: context,
    builder: (context) {
      final anchoPantalla = MediaQuery.of(context).size.width;
      final anchoCampo = anchoPantalla * 0.8;
      final anchoMenu = anchoCampo * 0.8;

      return StatefulBuilder(
        builder: (context, setState) {
          final errores = <String, String>{};

          void validarCampos() {
  errores.clear();
  if (tituloCtrl.text.trim().isEmpty) {
    errores['titulo'] = 'Este campo es obligatorio';
  }

  final montoTotal = double.tryParse(montoCtrl.text.trim().replaceAll(',', '.'));
  if (montoTotal == null || montoTotal <= 0) {
    errores['monto'] = 'Introduce un importe válido';
  }

  final aportacionActual = double.tryParse(aportacionCtrl.text.trim().replaceAll(',', '.'));
  if (aportacionActual == null || aportacionActual < 0) {
    errores['aportacion'] = 'Introduce una aportación válida';
  }
}

          tituloCtrl.addListener(() => setState(() => validarCampos()));
          montoCtrl.addListener(() => setState(() => validarCampos()));
          aportacionCtrl.addListener(() => setState(() => validarCampos()));

          bool camposValidos() {
            validarCampos();
            return errores.isEmpty;
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(20),
            title: Text(
              datosIniciales == null ? 'Registrar pago' : 'Editar pago',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tituloCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Nombre del pago',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0D1B2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: errores['titulo'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Importe (€)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0D1B2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: errores['monto'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aportacionCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Aportación del progenitor actual (€)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0D1B2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: errores['aportacion'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownMenu<String>(
                    initialSelection: tipoSeleccionado,
                    onSelected: (val) => setState(() => tipoSeleccionado = val ?? 'Común'),
                    dropdownMenuEntries: ['Común', 'Privado'].map((e) => DropdownMenuEntry(
                      value: e,
                      label: e,
                      labelWidget: Text(
                        e,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                      ),
                    )).toList(),
                    width: anchoCampo,
                    textStyle: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    menuStyle: MenuStyle(
                      backgroundColor: MaterialStateProperty.all(const Color(0xFF1B263B)),
                      fixedSize: MaterialStateProperty.all(Size(anchoMenu, 120)),
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 4)),
                    ),
                    inputDecorationTheme: const InputDecorationTheme(
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF0D1B2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    label: const Text('Tipo de pago'),
                  ),

                                    const SizedBox(height: 12),
                  TextField(
                    controller: descripcionCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0D1B2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: observacionesCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF0D1B2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  if (tipoSeleccionado == 'Privado')
                    DropdownMenu<String>(
                      initialSelection: estadoSeleccionado,
                      onSelected: (val) => setState(() => estadoSeleccionado = val ?? 'Pendiente'),
                      dropdownMenuEntries: ['Pagado', 'Pendiente', 'En disputa'].map((e) => DropdownMenuEntry(
                        value: e,
                        label: e,
                        labelWidget: Text(
                          e,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                        ),
                      )).toList(),
                      width: anchoCampo,
                      textStyle: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                      menuStyle: MenuStyle(
                        backgroundColor: MaterialStateProperty.all(const Color(0xFF1B263B)),
                        fixedSize: MaterialStateProperty.all(Size(anchoMenu, 160)),
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 4)),
                      ),
                      inputDecorationTheme: const InputDecorationTheme(
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF0D1B2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      label: const Text('Estado del pago'),
                    ),

                  if (estadoSeleccionado == 'En disputa')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextField(
                        controller: motivoCtrl,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                        decoration: InputDecoration(
                          labelText: 'Motivo de disputa',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF0D1B2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ),

                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Adjuntar justificante', style: TextStyle(fontFamily: 'Montserrat')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final resultado = await FilePicker.platform.pickFiles(withData: true);
                      if (resultado != null) {
                        setState(() => archivo = resultado.files.first);
                      }
                    },
                  ),
                  if (archivo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '📎 Archivo seleccionado: ${archivo!.name}',
                        style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: camposValidos()
                    ? () async {
                        final montoTotal = double.tryParse(montoCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
final aportacionActual = double.tryParse(aportacionCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
final nombre = archivo?.name;
String? url;

if (archivo?.bytes != null) {
  final ref = FirebaseStorage.instance
      .ref('pagos/$hijoID/${DateTime.now().millisecondsSinceEpoch}_${archivo!.name}');
  await ref.putData(archivo!.bytes!);
  url = await ref.getDownloadURL();
}

final aportaciones = Map<String, double>.from(datosIniciales?['aportaciones'] ?? {});
aportaciones[uid] = aportacionActual;

String estadoFinal = estadoSeleccionado;
if (tipoSeleccionado == 'Común') {
  final totalAportado = aportaciones.values.fold(0.0, (a, b) => a + b);
  estadoFinal = totalAportado >= montoTotal ? 'Pagado' : 'Pendiente';
}

final datosFinales = {
  'hijoID': hijoID,
  'tipo': tipoSeleccionado,
  'titulo': tituloCtrl.text.trim(),
  'montoTotal': montoTotal,
  'descripcion': descripcionCtrl.text.trim(),
  'observaciones': observacionesCtrl.text.trim(),
  'estado': estadoFinal,
  'motivoEstado': motivoCtrl.text.trim(),
  'fechaRegistro': datosIniciales?['fechaRegistro'] ?? DateTime.now(),
  'fechaCambioEstado': DateTime.now(),
  'usuarioRegistroID': datosIniciales?['usuarioRegistroID'] ?? uid,
  'usuarioCambioID': uid,
  'nombreArchivo': nombre ?? datosIniciales?['nombreArchivo'],
  'urlArchivo': url ?? datosIniciales?['urlArchivo'],
  'aportaciones': aportaciones,
};

if (datosIniciales == null) {
  await FirebaseFirestore.instance.collection('pagos').add(datosFinales);
} else {
  await FirebaseFirestore.instance
      .collection('pagos')
      .doc(datosIniciales['id'])
      .update(datosFinales);
}

Navigator.pop(context);
if (onGuardado != null) onGuardado();
                      }
                    : null,
                child: const Text('Guardar', style: TextStyle(fontFamily: 'Montserrat')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}