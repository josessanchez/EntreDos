import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evento_model.dart';

class FormularioEvento extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;
  final Evento? eventoExistente;

  const FormularioEvento({
    required this.hijoId,
    required this.hijoNombre,
    this.eventoExistente,
  });

  @override
  _FormularioEventoState createState() => _FormularioEventoState();
}

class _FormularioEventoState extends State<FormularioEvento> {
  final tituloController = TextEditingController();
  final notasController = TextEditingController();
  String tipoSeleccionado = 'Actividad';
  DateTime? fechaEvento;
  File? documento;
  String? documentoNombre;
  bool guardando = false;
  String? documentoActualUrl;

  final tipos = ['Actividad', 'Cumpleaños', 'Médico'];

  @override
  void initState() {
    super.initState();
    final e = widget.eventoExistente;
    if (e != null) {
      tituloController.text = e.titulo;
      tipoSeleccionado = e.tipo;
      fechaEvento = e.fecha;
      documentoActualUrl = e.documentoUrl;
      notasController.text = e.notas ?? '';
    }
  }

  Future<void> seleccionarDocumento() async {
    final resultado = await FilePicker.platform.pickFiles();
    if (resultado == null || resultado.files.single.path == null) return;

    final xfile = resultado.files.single;
    var archivo = File(xfile.path!);
    final nombreOriginal = xfile.name;
    final extension = nombreOriginal.split('.').last.toLowerCase();
    final baseNombre = nombreOriginal.split('.').first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nombreFinal = '${baseNombre}_$timestamp.$extension';
    final tamano = archivo.lengthSync();

    if (tamano > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ El archivo supera 5MB',
              style: TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (['jpg', 'jpeg'].contains(extension)) {
      final tempDir = await getTemporaryDirectory();
      final comprimido = await FlutterImageCompress.compressAndGetFile(
        archivo.path,
        '${tempDir.path}/${baseNombre}_compressed_$timestamp.jpg',
        quality: 60,
      );
      if (comprimido != null) {
        archivo = File(comprimido.path);
      }
    }

    setState(() {
      documento = archivo;
      documentoNombre = nombreFinal;
    });
  }

  Future<void> guardarEvento() async {
    final titulo = tituloController.text.trim();
    if (titulo.isEmpty || fechaEvento == null || guardando) return;

    setState(() => guardando = true);

    String? documentoUrl = documentoActualUrl;
    if (documento != null && documentoNombre != null) {
      final extension = documentoNombre!.split('.').last.toLowerCase();
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
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          contentType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('eventos/${widget.hijoId}/$documentoNombre');
      final uploadTask = ref.putFile(
        documento!,
        SettableMetadata(contentType: contentType),
      );
      final snapshot = await uploadTask.whenComplete(() => null);
      documentoUrl = await snapshot.ref.getDownloadURL();
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final eventoFinal = Evento(
      id: widget.eventoExistente?.id ?? '',
      titulo: titulo,
      tipo: tipoSeleccionado,
      fecha: fechaEvento!,
      hijoId: widget.hijoId,
      hijoNombre: widget.hijoNombre,
      creadorUid: uid,
      documentoUrl: documentoUrl,
      notas: notasController.text.trim(),
    );

    if (widget.eventoExistente != null) {
      await FirebaseFirestore.instance
          .collection('eventos')
          .doc(widget.eventoExistente!.id)
          .update(eventoFinal.toMap());

      Navigator.pop(context, eventoFinal);
    } else {
      final docRef = await FirebaseFirestore.instance
          .collection('eventos')
          .add(eventoFinal.toMap());

      final eventoConId = eventoFinal.copyWith(id: docRef.id);
      Navigator.pop(context, eventoConId);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Evento guardado',
            style: TextStyle(fontFamily: 'Montserrat')),
        backgroundColor: Colors.green,
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final anchoPantalla = MediaQuery.of(context).size.width;
  final anchoCampo = anchoPantalla * 0.8; // 80% del ancho de pantalla
  final anchoMenu = anchoCampo * 0.78;
  return AlertDialog(
    scrollable: true,
    backgroundColor: const Color(0xFF1B263B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.all(20),
    content: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.eventoExistente == null
                  ? 'Añadir evento al calendario'
                  : 'Editar evento',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tituloController,
              style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0D1B2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

const SizedBox(height: 12),
DropdownMenu<String>(
  initialSelection: tipoSeleccionado,
  onSelected: (v) => setState(() => tipoSeleccionado = v ?? 'Actividad'),
  dropdownMenuEntries: tipos.map((tipo) => DropdownMenuEntry(
    value: tipo,
    label: tipo,
    labelWidget: Text(
      tipo,
      style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
    ),
  )).toList(),
  width: anchoCampo,
  textStyle: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
  menuStyle: MenuStyle(
    backgroundColor: MaterialStateProperty.all(const Color(0xFF1B263B)),
    fixedSize: MaterialStateProperty.all(Size(anchoMenu, 160)),
    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 4)),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    labelStyle: TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Color(0xFF0D1B2A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  label: const Text('Tipo de evento'),
),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                fechaEvento == null
                    ? 'Seleccionar fecha del evento'
                    : '${fechaEvento!.day}/${fechaEvento!.month}/${fechaEvento!.year}',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final nuevaFecha = await showDatePicker(
                  context: context,
                  initialDate: fechaEvento ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        dialogBackgroundColor: const Color(0xFF1B263B),
                        colorScheme: const ColorScheme.dark(
                          primary: Colors.blueAccent,
                          onPrimary: Colors.white,
                          surface: Color(0xFF0D1B2A),
                          onSurface: Colors.white,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueAccent,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (nuevaFecha != null) {
                  setState(() => fechaEvento = nuevaFecha);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notasController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
              decoration: InputDecoration(
                labelText: 'Notas',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0D1B2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(
                documento == null
                    ? (documentoActualUrl == null
                        ? 'Adjuntar documento'
                        : 'Cambiar documento')
                    : 'Cambiar documento',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: seleccionarDocumento,
            ),
            if (documento != null &&
                ['jpg', 'jpeg', 'png']
                    .contains(documento!.path.split('.').last.toLowerCase())) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  documento!,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        );
      },
    ),
    actions: [
      TextButton(
        child: const Text('Cancelar',
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
        onPressed: () => Navigator.pop(context),
      ),
      ElevatedButton(
        child: guardando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(widget.eventoExistente == null ? 'Guardar' : 'Guardar cambios',
                style: const TextStyle(fontFamily: 'Montserrat')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: guardando ? null : guardarEvento,
      ),
    ],
  );
}
}