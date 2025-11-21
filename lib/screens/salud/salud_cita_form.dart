import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaludCitaFormScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const SaludCitaFormScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _SaludCitaFormScreenState createState() => _SaludCitaFormScreenState();
}

class _SaludCitaFormScreenState extends State<SaludCitaFormScreen> {
  String? tipoCita;
  String? especialidad;
  DateTime? fechaHora;
  String? ubicacion;
  String? notas;
  File? archivoAdjunto;
  String? tituloUsuario;
  String mensaje = '⏳ Esperando acción...';

  final tiposCita = ['Consulta', 'Intervención', 'Revisión'];
  final especialidades = ['Pediatría', 'Psicología', 'Oftalmología', 'General'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Cargando sesión...')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          'Calendario: ${widget.hijoNombre}',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Registrar nueva cita médica',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipoCita,
              decoration: _inputDecoration('Tipo de cita'),
              items: tiposCita
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (valor) => setState(() => tipoCita = valor),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: especialidad,
              decoration: _inputDecoration('Especialidad'),
              items: especialidades
                  .map((esp) => DropdownMenuItem(value: esp, child: Text(esp)))
                  .toList(),
              onChanged: (valor) => setState(() => especialidad = valor),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                fechaHora != null
                    ? DateFormat('dd/MM/yyyy – HH:mm').format(fechaHora!)
                    : 'Seleccionar fecha y hora',
              ),
              onPressed: seleccionarFechaHora,
              style: _botonEstilo(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _inputDecoration('Ubicación (opcional)'),
              onChanged: (valor) => ubicacion = valor,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _inputDecoration('Notas (opcional)'),
              onChanged: (valor) => notas = valor,
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Adjuntar justificante'),
              onPressed: seleccionarArchivo,
              style: _botonEstilo(),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Registrar cita'),
              onPressed:
                  (tipoCita != null &&
                      especialidad != null &&
                      fechaHora != null)
                  ? registrarCita
                  : null,
              style: _botonEstilo(color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Future<void> registrarCita() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        tipoCita == null ||
        especialidad == null ||
        fechaHora == null) {
      return;
    }

    final navigator = Navigator.of(context);

    String? urlDocumento;
    String? nombreDocumento;

    if (archivoAdjunto != null) {
      final nombreOriginal = archivoAdjunto!.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      nombreDocumento =
          '${user.uid}_${widget.hijoId}_${timestamp}_$nombreOriginal';

      try {
        final ref = FirebaseStorage.instance.ref().child(
          'salud/${user.uid}/$nombreDocumento',
        );
        final metadata = SettableMetadata(
          contentType: 'application/octet-stream',
        );
        await ref.putFile(archivoAdjunto!, metadata);
        urlDocumento = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) setState(() => mensaje = '❌ Error al subir el documento');
        return;
      }
    }

    await FirebaseFirestore.instance.collection('salud').add({
      'tipoEntrada': 'cita',
      'tipo': tipoCita,
      'especialidad': especialidad,
      'fechaHora': Timestamp.fromDate(fechaHora!),
      'responsableID': user.uid,
      'responsableNombre': user.displayName ?? user.email ?? 'Usuario',
      'ubicacion': ubicacion ?? '',
      'notas': notas ?? '',
      'hijoID': widget.hijoId,
      'fechaSubida': Timestamp.now(),
      'urlDocumento': urlDocumento ?? '',
      'nombreDocumento': nombreDocumento ?? '',
      'tituloDocumento': tituloUsuario ?? '$tipoCita • $especialidad',
    });

    if (mounted) setState(() => mensaje = '✅ Cita registrada correctamente');
    // show success message briefly and return to the previous screen (list)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) navigator.pop();
    });
  }

  Future<void> seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        archivoAdjunto = File(result.files.single.path!);
        tituloUsuario = result.files.single.name;
      });
    }
  }

  Future<void> seleccionarFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;

    if (!mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora == null) return;

    setState(() {
      fechaHora = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  ButtonStyle _botonEstilo({Color color = Colors.blueAccent}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1B263B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
