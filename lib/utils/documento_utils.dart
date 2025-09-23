import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../screens/visor_pdf_local_screen.dart';

final _scanner = const MethodChannel('media_scanner');

Future<void> verDocumentoDesdeCalendario(
  BuildContext context,
  String url,
  String nombre,
) async {
  if (url.isEmpty || nombre.isEmpty) return;

  try {
    final ext = nombre.split('.').last.toLowerCase();
    final uri = Uri.parse(url);

    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('No se pudo descargar');

    final dirTemp = await getTemporaryDirectory();
    final archivoLocal = File('${dirTemp.path}/$nombre');
    await archivoLocal.writeAsBytes(response.bodyBytes, flush: true);

    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          child: InteractiveViewer(
            child: Image.file(archivoLocal, fit: BoxFit.contain),
          ),
        ),
      );
    } else if (ext == 'pdf') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VisorPdfLocalScreen(localPath: archivoLocal.path, nombre: nombre),
      ));
    } else {
      final result = await OpenFilex.open(archivoLocal.path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ No se pudo abrir "$nombre"')),
        );
      }
    }
  } catch (e) {
    print('❌ Error verDocumento: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ No se pudo abrir el documento')),
    );
  }
}

Future<void> descargarDocumentoDesdeCalendario(
  BuildContext context,
  String url,
  String nombre,
) async {
  if (url.isEmpty || nombre.isEmpty) return;

  try {
    final dir = Directory('/storage/emulated/0/Download');
    final ext = nombre.split('.').last.toLowerCase();
    String finalNombre = nombre;
    String ruta = '${dir.path}/$finalNombre';

    if (await File(ruta).exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final base = nombre.split('.').first;
      finalNombre = '${base}_$timestamp.$ext';
      ruta = '${dir.path}/$finalNombre';
    }

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir.path,
      fileName: finalNombre,
      showNotification: true,
      openFileFromNotification: false,
    );

    if (taskId == null) throw Exception('No se pudo iniciar descarga');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📥 Descargando "$finalNombre"...')),
    );

    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      await Future.delayed(Duration(seconds: 3));
      await _scanner.invokeMethod('scanFile', {'path': ruta});
    }
  } catch (e) {
    print('❌ Error descargarDocumento: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error al descargar el documento')),
    );
  }
}