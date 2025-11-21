import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class VisorPdfLocalScreen extends StatelessWidget {
  final String localPath;
  final String nombre;

  const VisorPdfLocalScreen({
    super.key,
    required this.localPath,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: PDFView(
        filePath: localPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
    );
  }
}
