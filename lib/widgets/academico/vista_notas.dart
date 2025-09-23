import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VistaNotas extends StatefulWidget {
  final String hijoID;
  const VistaNotas({required this.hijoID});

  @override
  State<VistaNotas> createState() => _VistaNotasState();
}

class _VistaNotasState extends State<VistaNotas> {
  bool _subiendo = false;

  Future<void> subirNota() async {
    final resultado = await FilePicker.platform.pickFiles(withData: true);
    if (resultado == null || resultado.files.isEmpty) return;

    final archivo = resultado.files.first;
    final nombre = archivo.name;
    final fecha = DateTime.now();

    if (archivo.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se pudo leer el archivo')),
      );
      return;
    }

    final tituloCtrl = TextEditingController();
    final observacionCtrl = TextEditingController();
    final errores = <String, String>{};

    await showDialog(
  context: context,
  builder: (context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Subir nota',
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  decoration: InputDecoration(
                    labelText: 'Título del documento',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D1B2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: errores.containsKey('titulo') ? errores['titulo'] : null,
                  ),
                  onChanged: (_) => setState(() {
                    if (tituloCtrl.text.trim().isEmpty) {
                      errores['titulo'] = 'Este campo es obligatorio';
                    } else {
                      errores.remove('titulo');
                    }
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacionCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D1B2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: tituloCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);
                      setState(() => _subiendo = true);

                      try {
                        final ref = FirebaseStorage.instance.ref(
                          'notas/${widget.hijoID}/${DateTime.now().millisecondsSinceEpoch}_$nombre',
                        );
                        await ref.putData(archivo.bytes!);
                        final url = await ref.getDownloadURL();

                        await FirebaseFirestore.instance.collection('notas').add({
                          'hijoID': widget.hijoID,
                          'usuarioID': FirebaseAuth.instance.currentUser!.uid,
                          'tituloNota': tituloCtrl.text.trim(),
                          'nombreArchivo': nombre,
                          'observaciones': observacionCtrl.text.trim(),
                          'fechaSubida': fecha,
                          'urlArchivo': url,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Documento subido')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Error: $e')),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _subiendo = false);
                      });
                    },
              child: const Text('Aceptar', style: TextStyle(fontFamily: 'Montserrat')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  },
);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return Container(
      color: const Color(0xFF0D1B2A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir documento', style: TextStyle(fontFamily: 'Montserrat')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: subirNota,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notas')
                  .where('hijoID', isEqualTo: widget.hijoID)
                  .orderBy('fechaSubida', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active || !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '📭 No se han subido documentos',
                      style: TextStyle(fontFamily: 'Montserrat', color: Colors.white70),
                    ),
                  );
                }

                return ListView(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
                  children: docs.map((doc) {
                    final datos = doc.data() as Map<String, dynamic>;
                    final fecha = (datos['fechaSubida'] as Timestamp).toDate();
                    final formato = DateFormat.yMMMMd('es_ES').format(fecha);
                    final nombre = datos['nombreArchivo'] ?? 'Documento';
                    final titulo = datos['tituloNota'] ?? nombre;
                    final url = datos['urlArchivo'];

                    return Card(
                      color: const Color(0xFF1B263B),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(titulo, style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((datos['observaciones'] ?? '').toString().trim().isNotEmpty)
                              Text('🗒️ ${datos['observaciones']}',
                                  style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
                            Text('📅 Subido el $formato',
                                style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.white),
                              onPressed: () => DocumentoHelper.ver(context, nombre, url),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.white),
                              onPressed: () => DocumentoHelper.descargar(context, nombre, url),
                            ),
                            if (datos['usuarioID'] == FirebaseAuth.instance.currentUser?.uid)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => DocumentoHelper.delete(
                                  context,
                                  doc.id,
                                  nombre,
                                  url,
                                  FirebaseAuth.instance.currentUser!.uid,
                                  datos['usuarioID'],
                                  'notas',
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}