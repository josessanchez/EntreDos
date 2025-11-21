import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class VisorPdfScreen extends StatefulWidget {
  final String url;
  final String nombre;

  const VisorPdfScreen({super.key, required this.url, required this.nombre});

  @override
  _VisorPdfScreenState createState() => _VisorPdfScreenState();
}

class _VisorPdfScreenState extends State<VisorPdfScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _descargarPdf();
  }

  Future<void> _descargarPdf() async {
    final response = await http.get(Uri.parse(widget.url));
    final bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${widget.nombre}');

    await file.writeAsBytes(bytes, flush: true);

    setState(() {
      localPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre)),
      body: localPath == null
          ? Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            ),
    );
  }
}
