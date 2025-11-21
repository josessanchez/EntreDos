import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class IdentificacionUploadScreen extends StatefulWidget {
  final String hijoId;

  const IdentificacionUploadScreen({super.key, required this.hijoId});

  @override
  _IdentificacionUploadScreenState createState() =>
      _IdentificacionUploadScreenState();
}

class _IdentificacionUploadScreenState
    extends State<IdentificacionUploadScreen> {
  String mensaje = '⏳ Esperando acción...';
  String? tipoSeleccionado;
  File? archivoSeleccionado;
  String? nombreOriginal;

  final List<String> tiposDocumento = [
    'DNI',
    'Pasaporte',
    'Tarjeta de residente',
    'NIE',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Subir documento de identidad',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonFormField<String>(
                value: tipoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de documento',
                  labelStyle: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Montserrat',
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1B263B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                dropdownColor: const Color(0xFF1B263B),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
                items: tiposDocumento
                    .map(
                      (tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(
                          tipo,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (valor) => setState(() => tipoSeleccionado = valor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar archivo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: seleccionarArchivo,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Subir documento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (archivoSeleccionado != null && tipoSeleccionado != null)
                    ? confirmarSubida
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> confirmarSubida() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || archivoSeleccionado == null || nombreOriginal == null) {
      setState(() => mensaje = '❌ Sesión inválida o archivo no seleccionado');
      return;
    }

    final navigator = Navigator.of(context);

    String extension = nombreOriginal!.split('.').last.toLowerCase();
    final baseNombre = nombreOriginal!.split('.').first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    bool esImagenJpg = ['jpg', 'jpeg'].contains(extension);

    File archivoFinal = archivoSeleccionado!;
    String nombreFinal;

    if (esImagenJpg) {
      final tempDir = await getTemporaryDirectory();
      final comprimido = await FlutterImageCompress.compressAndGetFile(
        archivoFinal.path,
        '${tempDir.path}/${baseNombre}_compressed_$timestamp.jpg',
        quality: 60,
      );
      if (comprimido != null) {
        archivoFinal = File(comprimido.path);
        extension = 'jpg';
        nombreFinal = '${baseNombre}_compressed_$timestamp.jpg';
      } else {
        nombreFinal = '${baseNombre}_$timestamp.$extension';
      }
    } else {
      nombreFinal = '${baseNombre}_$timestamp.$extension';
    }

    String contentType;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'pdf':
        contentType = 'application/pdf';
        break;
      default:
        contentType = 'application/octet-stream';
    }

    final refStorage = FirebaseStorage.instance.ref().child(
      'identificacion/${user.uid}/$nombreFinal',
    );
    final metadata = SettableMetadata(contentType: contentType);

    await refStorage.putFile(archivoFinal, metadata);
    final url = await refStorage.getDownloadURL();

    await FirebaseFirestore.instance.collection('identificacion').add({
      'nombre': nombreFinal,
      'tituloUsuario': nombreOriginal,
      'tipo': tipoSeleccionado,
      'url': url,
      'contentType': contentType,
      'fechaSubida': Timestamp.now(),
      'usuarioID': user.uid,
      'hijoID': widget.hijoId,
      'usuarioNombre': user.displayName ?? user.email ?? 'Usuario desconocido',
    });

    if (mounted) setState(() => mensaje = '✅ Documento subido correctamente');

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) navigator.pop();
    });
  }

  Future<void> seleccionarArchivo() async {
    final resultado = await FilePicker.platform.pickFiles();
    if (resultado == null || resultado.files.single.path == null) {
      setState(() => mensaje = '❌ No se pudo acceder al archivo');
      return;
    }

    final archivo = File(resultado.files.single.path!);
    final tamano = archivo.lengthSync();

    if (tamano > 5 * 1024 * 1024) {
      setState(() => mensaje = '❌ El archivo supera 5 MB');
      return;
    }

    setState(() {
      archivoSeleccionado = archivo;
      nombreOriginal = resultado.files.single.name;
      mensaje = '✅ Archivo seleccionado: $nombreOriginal';
    });
  }
}
