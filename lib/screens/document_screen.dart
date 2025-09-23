

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';

class DocumentScreen extends StatefulWidget {
  final String hijoId;

  const DocumentScreen({required this.hijoId});

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}


class _DocumentScreenState extends State<DocumentScreen> {
  String mensaje = '⏳ Esperando acción...';

  Future<void> subirDocumento() async {
    await Permission.storage.request();
    print('📂 Iniciando selección de archivo...');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Usuario no autenticado');
      setState(() => mensaje = '❌ Debes iniciar sesión para subir documentos');
      return;
    }

    try {
      final resultado = await FilePicker.platform.pickFiles();
      print('📦 Resultado del selector: $resultado');

      if (resultado == null || resultado.files.single.path == null) {
        print('❌ No se seleccionó archivo o no tiene ruta válida');
        setState(() => mensaje = '❌ No se pudo acceder al archivo');
        return;
      }

      File archivo = File(resultado.files.single.path!);
      String nombreOriginal = resultado.files.single.name;
      int tamano = archivo.lengthSync();

      print('📄 Archivo seleccionado: $nombreOriginal');
      print('📁 Ruta del archivo: ${archivo.path}');
      print('📏 Tamaño: $tamano bytes');

      if (tamano > 5 * 1024 * 1024) {
        print('⚠️ El archivo es demasiado grande');
        setState(() => mensaje = '❌ El archivo supera 5 MB');
        return;
      }

      String extension = nombreOriginal.split('.').last.toLowerCase();
      final baseNombre = nombreOriginal.split('.').first;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      bool esImagenJpg = ['jpg', 'jpeg'].contains(extension);

      String nombreFinal;

      // Compresión solo si es .jpg/.jpeg
      if (esImagenJpg) {
        print('🖼️ Imagen JPEG detectada, comprimiendo...');
        final tempDir = await getTemporaryDirectory();
        final comprimido = await FlutterImageCompress.compressAndGetFile(
          archivo.path,
          '${tempDir.path}/${baseNombre}_compressed_$timestamp.jpg',
          quality: 60,
        );
        if (comprimido != null) {
          archivo = File(comprimido.path);
          extension = 'jpg';
          nombreFinal = '${baseNombre}_compressed_$timestamp.jpg';
        } else {
          print('⚠️ Compresión fallida, usando original');
          nombreFinal = '${baseNombre}_$timestamp.$extension';
        }
      } else {
        print('🔒 No se comprime imagen PNG o documento');
        nombreFinal = '${baseNombre}_$timestamp.$extension';
      }

      // Tipo MIME
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
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xlsx':
          contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      print('📂 Archivo final: $nombreFinal');
      final refStorage = FirebaseStorage.instance
          .ref()
          .child('documentos/${user.uid}/$nombreFinal');
      final metadata = SettableMetadata(contentType: contentType);

      await refStorage.putFile(archivo, metadata);
      print('📤 Subida completada');

      final url = await refStorage.getDownloadURL();
      print('🌐 URL: $url');

      await FirebaseFirestore.instance.collection('documentos').add({
        'nombre': nombreFinal,
        'url': url,
        'contentType': contentType,
        'fechaSubida': Timestamp.now(),
        'usuarioID': user.uid,
        'hijoID': widget.hijoId,
      });

      print('✅ Documento registrado en Firestore');
      setState(() => mensaje = '✅ Documento subido correctamente');
    } catch (e) {
      print('🔥 Error inesperado: $e');
      setState(() => mensaje = '❌ Error al subir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subir documento')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: subirDocumento,
              child: Text('Seleccionar archivo'),
            ),
            SizedBox(height: 12),
            Text(mensaje, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}