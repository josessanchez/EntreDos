import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/models/modelo_pago.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FormularioPago extends StatefulWidget {
  final String hijoID;

  const FormularioPago({super.key, required this.hijoID});

  @override
  State<FormularioPago> createState() => _FormularioPagoState();
}

class _FormularioPagoState extends State<FormularioPago> {
  final _formKey = GlobalKey<FormState>();

  String? tipoGasto;
  double? importeTotal;
  double? cantidadPagada;
  bool esCompartido = true;
  double porcentajeResponsable = 50;
  bool esRecurrente = false;
  DateTime? fechaLimite;
  String? comentario;
  File? justificante;
  String? nombreJustificante;

  bool errorJustificante = false;
  bool errorImporte = false;
  bool errorDuplicado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Registrar nuevo pago',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo de gasto'),
                items:
                    [
                          'Colegio',
                          'Actividades',
                          'Uniforme',
                          'Pensión de alimentos',
                          'Visita médica',
                          'Excursión',
                          'Otro',
                        ]
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                onChanged: (value) => tipoGasto = value,
                validator: (value) =>
                    value == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Importe total (€)',
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => importeTotal = double.tryParse(value ?? ''),
                validator: (value) => value == null || value.isEmpty
                    ? 'Introduce el importe'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cantidad pagada por ti (€)',
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    cantidadPagada = double.tryParse(value ?? ''),
              ),
              if (errorImporte)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ La cantidad pagada no puede superar el importe total',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              if (errorDuplicado)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ Ya existe un pago registrado con el mismo tipo y fecha',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  '¿Es un pago compartido?',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                value: esCompartido,
                onChanged: (value) => setState(() => esCompartido = value),
              ),
              if (esCompartido) ...[
                const SizedBox(height: 8),
                Text(
                  'Porcentaje que te corresponde: ${porcentajeResponsable.toInt()}%',
                ),
                Slider(
                  value: porcentajeResponsable,
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: '${porcentajeResponsable.toInt()}%',
                  onChanged: (value) =>
                      setState(() => porcentajeResponsable = value),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text(
                  '¿Es un pago recurrente?',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                value: esRecurrente,
                onChanged: (value) => setState(() => esRecurrente = value),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text(
                  'Fecha límite (opcional)',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                subtitle: Text(
                  fechaLimite != null
                      ? DateFormat('dd/MM/yyyy').format(fechaLimite!)
                      : 'No seleccionada',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final seleccionada = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (seleccionada != null) {
                    setState(() => fechaLimite = seleccionada);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                ),
                maxLines: 2,
                onSaved: (value) => comentario = value,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: seleccionarJustificante,
                icon: const Icon(Icons.attach_file),
                label: Text(nombreJustificante ?? 'Subir justificante'),
              ),
              if (errorJustificante)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ Error al subir el justificante. Intenta nuevamente.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: registrarPago,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Registrar pago',
                  style: TextStyle(fontSize: 16, fontFamily: 'Montserrat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registrarPago() async {
    setState(() {
      errorImporte = false;
      errorJustificante = false;
      errorDuplicado = false;
    });

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Validación de campos obligatorios
    if (tipoGasto == null || importeTotal == null) {
      print('❌ tipoGasto o importeTotal son null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Completa todos los campos obligatorios'),
        ),
      );
      return;
    }

    if (cantidadPagada != null && cantidadPagada! > importeTotal!) {
      setState(() => errorImporte = true);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nombre = FirebaseAuth.instance.currentUser?.displayName ?? 'Tú';

    if (uid == null) {
      print('❌ Usuario no autenticado');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Usuario no autenticado')));
      return;
    }

    // Validación de duplicado
    final fechaHoy = DateTime.now();
    final inicioDia = DateTime(fechaHoy.year, fechaHoy.month, fechaHoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    try {
      final duplicado = await FirebaseFirestore.instance
          .collection('pagos')
          .where('hijoID', isEqualTo: widget.hijoID)
          .where('tipoGasto', isEqualTo: tipoGasto)
          .where('fechaRegistro', isGreaterThanOrEqualTo: inicioDia)
          .where('fechaRegistro', isLessThan: finDia)
          .get();

      if (duplicado.docs.isNotEmpty) {
        setState(() => errorDuplicado = true);
        return;
      }
    } catch (e) {
      print('❌ Error al verificar duplicado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al verificar duplicado: $e')),
      );
      return;
    }

    String? urlJustificante;
    if (justificante != null) {
      try {
        final ref = FirebaseStorage.instance.ref(
          'justificantes/${DateTime.now().millisecondsSinceEpoch}_${justificante!.path.split('/').last}',
        );
        final uploadTask = await ref.putFile(justificante!);
        print('📤 Justificante subido: ${uploadTask.state}');
        urlJustificante = await ref.getDownloadURL();
        print('🔗 URL del justificante: $urlJustificante');
      } catch (e) {
        print('❌ Error al subir justificante: $e');
        setState(() => errorJustificante = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al subir justificante: $e')),
        );
        return;
      }
    }

    try {
      final ref = FirebaseFirestore.instance.collection('pagos').doc();
      final nuevoPago = ModeloPago(
        id: ref.id,
        hijoID: widget.hijoID,
        responsableID: uid,
        responsableNombre: nombre,
        tipoGasto: tipoGasto!,
        importeTotal: importeTotal!,
        cantidadPagada: cantidadPagada ?? 0,
        esCompartido: esCompartido,
        porcentajeResponsable: porcentajeResponsable,
        esRecurrente: esRecurrente,
        fechaLimite: fechaLimite,
        comentario: comentario,
        urlJustificante: urlJustificante,
        nombreJustificante: nombreJustificante,
        estado: EstadoPago.pendiente,
        fechaRegistro: DateTime.now(),
      );

      await ref.set(nuevoPago.toMap());

      print('✅ Pago guardado con ID: ${ref.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pago registrado correctamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error al guardar el pago: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al guardar el pago: $e')));
    }
  }

  Future<void> seleccionarJustificante() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        justificante = File(result.files.single.path!);
        nombreJustificante = result.files.single.name;
      });
    }
  }
}
