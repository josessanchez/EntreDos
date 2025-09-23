import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:entredos/screens/visor_pdf_screen.dart';

class DocumentoHelper {
  static Future<void> ver(BuildContext context, String nombre, String url) async {
    final mime = lookupMimeType(nombre) ?? '';
    final extension = nombre.split('.').last.toLowerCase();
    final extensionesOffice = ['doc', 'docx', 'xls', 'xlsx'];

    if (mime.startsWith('image/')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B263B),
            title: Text(nombre, style: const TextStyle(fontFamily: 'Montserrat')),
          ),
          body: Center(child: Image.network(url)),
        ),
      ));
    } else if (mime == 'application/pdf') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VisorPdfScreen(url: url, nombre: nombre),
      ));
    } else if (extensionesOffice.contains(extension)) {
      try {
        final response = await http.get(Uri.parse(url));
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final localPath = '${dir.path}/$nombre'.replaceAll(' ', '_');
        final archivoLocal = File(localPath);
        await archivoLocal.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(archivoLocal.path);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al abrir "$nombre": $e', style: const TextStyle(fontFamily: 'Montserrat')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> descargar(BuildContext context, String nombre, String url) async {
    try {
      final dir = Directory('/storage/emulated/0/Download');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreFinal = '${nombre.split('.').first}_$timestamp.${nombre.split('.').last}';

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: dir.path,
        fileName: nombreFinal,
        headers: {},
        showNotification: true,
        openFileFromNotification: false,
      );

      if (taskId == null) throw Exception('No se pudo encolar la descarga');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📥 Descarga iniciada para "$nombre"', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      final extension = nombre.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(extension)) {
        await Future.delayed(const Duration(seconds: 3));
        await _scanFile('${dir.path}/$nombreFinal');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al descargar "$nombre": $e', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  static Future<void> delete(
    BuildContext context,
    String docId,
    String nombre,
    String? url,
    String uidActual,
    String uidPropietario,
    String coleccion,
  ) async {
    if (uidActual != uidPropietario) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ No tienes permisos para eliminar este archivo', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Eliminar "$nombre"?',
          style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white),
        ),
        content: const Text(
          'Esta acción eliminará el documento de la base de datos y del almacenamiento si lo tuviera. ¿Estás seguro?',
          style: TextStyle(fontFamily: 'Montserrat', color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('Eliminar', style: TextStyle(fontFamily: 'Montserrat')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (url != null && url.isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      }

      await FirebaseFirestore.instance.collection(coleccion).doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Documento "$nombre" eliminado', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al eliminar: $e', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  static Future<void> _scanFile(String path) async {
    const channel = MethodChannel('entredos/scan');
    try {
      await channel.invokeMethod('scanFile', {'path': path});
    } catch (e) {
      debugPrint('⚠️ Error escaneando imagen: $e');
    }
  }
}