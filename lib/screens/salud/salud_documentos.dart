import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:entredos/screens/salud/salud_upload.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entredos/widgets/fallback_body.dart';

class SaludDocumentosScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const SaludDocumentosScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _SaludDocumentosScreenState createState() => _SaludDocumentosScreenState();
}

class _SaludDocumentosScreenState extends State<SaludDocumentosScreen> {
  String? tipoDocumento;
  String? tituloDocumento;
  File? archivoSeleccionado;
  String mensaje = '⏳ Esperando acción...';

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
        title: Text(
          'Documentos de salud: ${widget.hijoNombre}',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SaludUploadScreen(hijoId: widget.hijoId),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('salud')
                    .where('hijoID', isEqualTo: widget.hijoId)
                    .where('tipoEntrada', isEqualTo: 'documento')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final err = snapshot.error;
                    if (err is FirebaseException &&
                        err.code == 'permission-denied') {
                      return const FallbackHijosWidget();
                    }
                    return const Center(
                      child: Text(
                        '❌ Error cargando documentos',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '📭 No hay documentos registrados',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: docs.map(_buildDocumentoCard).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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
      mensaje = '✅ Archivo seleccionado: ${resultado.files.single.name}';
    });
  }

  Future<void> subirDocumento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || archivoSeleccionado == null || tipoDocumento == null) {
      return;
    }

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
    if (!mounted) return;
    setState(() => mensaje = '✅ Documento subido correctamente');
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        tipoDocumento = null;
        tituloDocumento = null;
        archivoSeleccionado = null;
        mensaje = '⏳ Esperando acción...';
      });
    });
  }

  Widget _buildDocumentoCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final tipo = data['tipoDocumento'] ?? 'Documento';
    final titulo = data['tituloUsuario'] ?? tipo;
    final url = data['url'] ?? '';
    final nombre = data['nombre'] ?? '';
    final fecha = (data['fechaSubida'] as Timestamp?)?.toDate();
    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(fecha)
        : 'Sin fecha';
    final usuario = data['usuarioNombre'] ?? 'Sin autor';
    final uidPropietario = data['usuarioID'] ?? '';
    final docId = doc.id;

    final icono = _iconoPorTipo(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icono, color: Colors.white70, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subido por $usuario • $fechaTexto',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.greenAccent,
                ),
                tooltip: 'Ver documento',
                onPressed: () => DocumentoHelper.ver(context, nombre, url),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.amberAccent),
                tooltip: 'Descargar',
                onPressed: () =>
                    DocumentoHelper.descargar(context, nombre, url),
              ),
              if (uidPropietario == FirebaseAuth.instance.currentUser?.uid)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar',
                  onPressed: () => DocumentoHelper.delete(
                    context,
                    docId,
                    nombre,
                    url,
                    FirebaseAuth.instance.currentUser!.uid,
                    uidPropietario,
                    'salud',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'cartilla':
        return Icons.medical_services;
      case 'informe':
        return Icons.description;
      case 'vacuna':
        return Icons.vaccines;
      case 'autorización':
        return Icons.assignment_turned_in;
      default:
        return Icons.folder_shared;
    }
  }
}
