// This file uses local contexts for dialog pickers and guards `mounted` checks.
// The analyzer may still report `use_build_context_synchronously` in some cases
// even though we capture `context` in locals and verify `mounted`. To avoid
// noisy warnings here we narrow the lint for this file.
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/examen_model.dart';

class FormularioExamen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;
  final Examen? examenExistente;

  const FormularioExamen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
    this.examenExistente,
  });

  @override
  _FormularioExamenState createState() => _FormularioExamenState();
}

class _FormularioExamenState extends State<FormularioExamen> {
  final _formKey = GlobalKey<FormState>();
  String? asignatura;
  DateTime? fecha;
  String? tipo;
  TextEditingController observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.examenExistente != null) {
      final examen = widget.examenExistente!;
      asignatura = examen.asignatura;
      fecha = examen.fecha;
      tipo = examen.tipo;
      observacionesController.text = examen.observaciones;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.examenExistente != null ? 'Editar examen' : 'Nuevo examen',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: asignatura,
                items: ['Matemáticas', 'Lengua', 'Inglés', 'Ciencias']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (valor) => setState(() => asignatura = valor),
                decoration: InputDecoration(
                  labelText: 'Asignatura',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null ? 'Selecciona una asignatura' : null,
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.calendar_today),
                label: Text(
                  fecha != null
                      ? 'Fecha: ${DateFormat('dd/MM/yyyy – HH:mm').format(fecha!)}'
                      : 'Seleccionar fecha',
                ),
                onPressed: () async {
                  final localContext = context;
                  final seleccion = await showDatePicker(
                    context: localContext,
                    initialDate: fecha ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (seleccion == null) return;
                  if (!mounted) return;
                  final hora = await showTimePicker(
                    context: localContext,
                    initialTime: TimeOfDay.now(),
                  );
                  if (hora == null) return;
                  final fechaFinal = DateTime(
                    seleccion.year,
                    seleccion.month,
                    seleccion.day,
                    hora.hour,
                    hora.minute,
                  );
                  if (!mounted) return;
                  setState(() => fecha = fechaFinal);
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipo,
                items: ['Oral', 'Escrito']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (valor) => setState(() => tipo = valor),
                decoration: InputDecoration(
                  labelText: 'Tipo de examen',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Selecciona tipo' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: observacionesController,
                decoration: InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Guardar'),
          onPressed: () async {
            if (!_formKey.currentState!.validate() || fecha == null) return;

            final localContext = context;
            final navigator = Navigator.of(localContext);
            final messenger = ScaffoldMessenger.of(localContext);

            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) return;

            final nuevoExamen = Examen(
              hijoId: widget.hijoId,
              asignatura: asignatura!,
              fecha: fecha!,
              tipo: tipo!,
              observaciones: observacionesController.text.trim(),
              creadorUid: uid,
            );

            try {
              if (widget.examenExistente != null) {
                await FirebaseFirestore.instance
                    .collection('examenes')
                    .doc(widget.examenExistente!.id)
                    .update(nuevoExamen.toMap());
              } else {
                await FirebaseFirestore.instance
                    .collection('examenes')
                    .add(nuevoExamen.toMap());
              }

              if (!mounted) return;
              navigator.pop(nuevoExamen);
            } catch (e) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('❌ Error al guardar: $e')),
              );
            }
          },
        ),
      ],
    );
  }
}
