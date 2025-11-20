import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
// intl not needed here after removing citas UI

class SaludUploadScreen extends StatefulWidget {
  final String hijoId;

  const SaludUploadScreen({super.key, required this.hijoId});

  @override
  _SaludUploadScreenState createState() => _SaludUploadScreenState();
}

class _SaludUploadScreenState extends State<SaludUploadScreen> {
  // Documento
  String? tipoDocumento;
  String? tituloDocumento;
  File? archivoSeleccionado;
  String mensajeDocumento = '⏳ Esperando acción...';
  final tiposDocumento = ['Cartilla', 'Informe', 'Vacuna', 'Autorización'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Cargando sesión...')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Salud: Añadir información',
          style: TextStyle(
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
              '📁 Subir documento médico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tipoDocumento,
              decoration: _inputDecoration('Tipo de documento'),
              items: tiposDocumento
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (valor) => setState(() => tipoDocumento = valor),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: _inputDecoration('Título visible'),
              onChanged: (valor) => tituloDocumento = valor,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Seleccionar archivo'),
              onPressed: seleccionarArchivo,
              style: _botonEstilo(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Subir documento'),
              onPressed: (archivoSeleccionado != null && tipoDocumento != null)
                  ? subirDocumento
                  : null,
              style: _botonEstilo(color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              mensajeDocumento,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> seleccionarArchivo() async {
    final resultado = await FilePicker.platform.pickFiles();
    if (resultado == null || resultado.files.single.path == null) {
      setState(() => mensajeDocumento = '❌ No se pudo acceder al archivo');
      return;
    }

    final archivo = File(resultado.files.single.path!);
    final tamano = archivo.lengthSync();
    if (tamano > 5 * 1024 * 1024) {
      setState(() => mensajeDocumento = '❌ El archivo supera 5 MB');
      return;
    }

    setState(() {
      archivoSeleccionado = archivo;
      mensajeDocumento =
          '✅ Archivo seleccionado: ${resultado.files.single.name}';
    });
  }

  Future<void> subirDocumento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || archivoSeleccionado == null || tipoDocumento == null)
      return;

    final nombreOriginal = archivoSeleccionado!.path.split('/').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nombreFinal =
        '${user.uid}_${widget.hijoId}_${timestamp}_$nombreOriginal';

    final ref = FirebaseStorage.instance.ref().child(
      'salud/${user.uid}/$nombreFinal',
    );
    final metadata = SettableMetadata(contentType: 'application/octet-stream');

    await ref.putFile(archivoSeleccionado!, metadata);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('salud').add({
      'tipoEntrada': 'documento',
      'tipoDocumento': tipoDocumento,
      'tituloUsuario': tituloDocumento ?? tipoDocumento,
      'nombre': nombreFinal,
      'url': url,
      'contentType': 'application/octet-stream',
      'fechaSubida': Timestamp.now(),
      'usuarioID': user.uid,
      'usuarioNombre': user.displayName ?? user.email ?? 'Usuario',
      'hijoID': widget.hijoId,
    });

    setState(() => mensajeDocumento = '✅ Documento subido correctamente');
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.pop(context);
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
