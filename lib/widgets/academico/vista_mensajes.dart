import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:entredos/helpers/documento_helper.dart';

class Mensaje {
  final String id;
  final String titulo;
  final String contenido;
  final String observaciones;
  final DateTime fecha;
  final String? nombreArchivo;
  final String? urlArchivo;
  final String usuarioID;

  Mensaje({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.observaciones,
    required this.fecha,
    required this.usuarioID,
    this.nombreArchivo,
    this.urlArchivo,
  });

  factory Mensaje.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mensaje(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      contenido: data['contenido'] ?? '',
      observaciones: data['observaciones'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      nombreArchivo: data['nombreArchivo'],
      urlArchivo: data['urlArchivo'],
      usuarioID: data['usuarioID'],
    );
  }
}

class VistaMensajes extends StatefulWidget {
  final String hijoID;
  const VistaMensajes({required this.hijoID});

  @override
  State<VistaMensajes> createState() => _VistaMensajesState();
}

class _VistaMensajesState extends State<VistaMensajes> {
  List<Mensaje> mensajes = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarMensajes();
  }

  Future<void> cargarMensajes() async {
    if (widget.hijoID.isEmpty) return;

    setState(() => cargando = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('mensajes')
        .where('hijoID', isEqualTo: widget.hijoID)
        .orderBy('fecha', descending: true)
        .get();

    final lista = snapshot.docs.map((doc) => Mensaje.fromSnapshot(doc)).toList();

    setState(() {
      mensajes = lista;
      cargando = false;
    });
  }

  Future<void> subirMensaje({Mensaje? mensajeExistente}) async {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController(text: mensajeExistente?.titulo ?? '');
    final contenidoCtrl = TextEditingController(text: mensajeExistente?.contenido ?? '');
    final observacionesCtrl = TextEditingController(text: mensajeExistente?.observaciones ?? '');
    DateTime? fechaSeleccionada = mensajeExistente?.fecha ?? DateTime.now();
    PlatformFile? archivo;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          mensajeExistente == null ? 'Añadir mensaje' : 'Editar mensaje',
          style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: tituloCtrl,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF0D1B2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contenidoCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: const InputDecoration(
                      labelText: 'Contenido',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF0D1B2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(
                      fechaSeleccionada == null
                          ? 'Seleccionar fecha'
                          : DateFormat.yMMMMd('es_ES').format(fechaSeleccionada ?? DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.white),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => fechaSeleccionada = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: observacionesCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF0D1B2A),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Adjuntar documento', style: TextStyle(fontFamily: 'Montserrat')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final resultado = await FilePicker.platform.pickFiles(withData: true);
                      if (resultado != null && resultado.files.isNotEmpty) {
                        setDialogState(() => archivo = resultado.files.first);
                      }
                    },
                  ),
                  if (archivo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('📎 Archivo: ${archivo!.name}', style: const TextStyle(color: Colors.white70)),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Guardar', style: TextStyle(fontFamily: 'Montserrat')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final nombreArchivo = archivo?.name ?? mensajeExistente?.nombreArchivo ?? '';
              String? url;

              if (archivo?.bytes != null) {
                final ref = FirebaseStorage.instance.ref(
                  'mensajes/${widget.hijoID}/${DateTime.now().millisecondsSinceEpoch}_${archivo!.name}',
                );
                await ref.putData(archivo!.bytes!);
                url = await ref.getDownloadURL();
              }

              final datos = {
                'titulo': tituloCtrl.text.trim(),
                'contenido': contenidoCtrl.text.trim(),
                'observaciones': observacionesCtrl.text.trim(),
                'fecha': fechaSeleccionada ?? DateTime.now(),
                'nombreArchivo': nombreArchivo,
                'urlArchivo': url ?? mensajeExistente?.urlArchivo,
                'usuarioID': FirebaseAuth.instance.currentUser!.uid,
                'hijoID': widget.hijoID,
              };

              if (mensajeExistente == null) {
                await FirebaseFirestore.instance.collection('mensajes').add(datos);
              } else {
                await FirebaseFirestore.instance.collection('mensajes').doc(mensajeExistente.id).update(datos);
              }

              Navigator.pop(context);
              await cargarMensajes();
            },
          ),
        ],
      ),
    );
  }

  Icon getIconoPorExtension(String nombre) {
    final ext = nombre.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Icon(Icons.image);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description);
      case 'xls':
      case 'xlsx':
                return const Icon(Icons.table_chart);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : mensajes.isEmpty
              ? Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_comment),
                    label: const Text('Añadir mensaje', style: TextStyle(fontFamily: 'Montserrat')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => subirMensaje(),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];
                    final nombreArchivo = mensaje.nombreArchivo ?? mensaje.urlArchivo?.split('/').last;

                    return Card(
                      color: const Color(0xFF1B263B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    mensaje.titulo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat.yMMMMd('es_ES').format(mensaje.fecha),
                                  style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mensaje.contenido,
                              style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                            ),
                            if (mensaje.observaciones.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '🔍 Observaciones: ${mensaje.observaciones}',
                                style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (mensaje.urlArchivo != null && nombreArchivo != null) ...[
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                                    tooltip: 'Ver documento',
                                    onPressed: () => DocumentoHelper.ver(
                                      context,
                                      nombreArchivo,
                                      mensaje.urlArchivo!,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: Colors.green),
                                    tooltip: 'Descargar documento',
                                    onPressed: () => DocumentoHelper.descargar(
                                      context,
                                      nombreArchivo,
                                      mensaje.urlArchivo!,
                                    ),
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                                  tooltip: 'Editar mensaje',
                                  onPressed: () => subirMensaje(mensajeExistente: mensaje),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  tooltip: 'Eliminar mensaje',
                                  onPressed: () async {
                                    final confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: const Color(0xFF1B263B),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('¿Eliminar mensaje?', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
                                        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
                                        actions: [
                                          TextButton(
                                            child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
                                            onPressed: () => Navigator.pop(context, false),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text('Eliminar', style: TextStyle(fontFamily: 'Montserrat')),
                                            onPressed: () => Navigator.pop(context, true),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmar == true) {
                                      await FirebaseFirestore.instance
                                          .collection('mensajes')
                                          .doc(mensaje.id)
                                          .delete();
                                      await cargarMensajes();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add),
        tooltip: 'Añadir mensaje',
        onPressed: () => subirMensaje(),
      ),
    );
  }
}

