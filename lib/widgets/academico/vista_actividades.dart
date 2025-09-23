import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:entredos/helpers/documento_helper.dart';

class Actividad {
  final String id;
  final String titulo;
  final DateTime fecha;
  final String ubicacion;
  final String observaciones;
  final String estadoAsistencia;
  final String? nombreArchivo;
  final String? urlArchivo;
  final String usuarioID;

  Actividad({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.ubicacion,
    required this.observaciones,
    required this.estadoAsistencia,
    required this.usuarioID,
    this.nombreArchivo,
    this.urlArchivo,
  });

  factory Actividad.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Actividad(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      ubicacion: data['ubicacion'] ?? '',
      observaciones: data['observaciones'] ?? '',
      estadoAsistencia: data['estadoAsistencia'] ?? 'Pendiente',
      nombreArchivo: data['nombreArchivo'],
      urlArchivo: data['urlArchivo'],
      usuarioID: data['usuarioID'],
    );
  }
}

class VistaActividades extends StatefulWidget {
  final String hijoID;
  const VistaActividades({required this.hijoID});

  @override
  State<VistaActividades> createState() => _VistaActividadesState();
}

class _VistaActividadesState extends State<VistaActividades> {
  List<Actividad> actividades = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    cargarActividades();
  }

  Future<void> cargarActividades() async {
    if (widget.hijoID.isEmpty) return;

    setState(() => cargando = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('actividades')
        .where('hijoID', isEqualTo: widget.hijoID)
        .get();

    final lista = snapshot.docs.map((doc) => Actividad.fromSnapshot(doc)).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    setState(() {
      actividades = lista;
      cargando = false;
    });
  }

  Future<void> subirActividad({Actividad? existente}) async {
  final formKey = GlobalKey<FormState>();
  final tituloCtrl = TextEditingController(text: existente?.titulo ?? '');
  final ubicacionCtrl = TextEditingController(text: existente?.ubicacion ?? '');
  final observacionesCtrl = TextEditingController(text: existente?.observaciones ?? '');
  String estadoSeleccionado = existente?.estadoAsistencia ?? 'Pendiente';
  DateTime? fechaSeleccionada = existente?.fecha ?? DateTime.now();
  PlatformFile? archivo;
  final tituloValidoNotifier = ValueNotifier<bool>(tituloCtrl.text.trim().isNotEmpty);

  tituloCtrl.addListener(() {
    tituloValidoNotifier.value = tituloCtrl.text.trim().isNotEmpty;
  });

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        existente == null ? 'Añadir actividad' : 'Editar actividad',
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
                  controller: ubicacionCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  decoration: const InputDecoration(
                    labelText: 'Ubicación (opcional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF0D1B2A),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: estadoSeleccionado,
                  items: ['Pendiente', 'Confirmada'].map((estado) {
                    return DropdownMenuItem(value: estado, child: Text(estado));
                  }).toList(),
                  onChanged: (valor) => setDialogState(() => estadoSeleccionado = valor ?? 'Pendiente'),
                  decoration: const InputDecoration(
                    labelText: 'Estado asistencia',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF0D1B2A),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  dropdownColor: const Color(0xFF1B263B),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacionesCtrl,
                  maxLines: 3,
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
        ValueListenableBuilder<bool>(
          valueListenable: tituloValidoNotifier,
          builder: (context, esValido, _) => ElevatedButton(
            child: const Text('Guardar', style: TextStyle(fontFamily: 'Montserrat')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: esValido
                ? () async {
                    if (!formKey.currentState!.validate()) return;

                    final nombreArchivo = archivo?.name ?? existente?.nombreArchivo ?? '';
                    String? url;

                    if (archivo?.bytes != null) {
                      final ref = FirebaseStorage.instance.ref(
                        'actividades/${widget.hijoID}/${DateTime.now().millisecondsSinceEpoch}_${archivo!.name}',
                      );
                      await ref.putData(archivo!.bytes!);
                      url = await ref.getDownloadURL();
                    }

                    final datos = {
                      'titulo': tituloCtrl.text.trim(),
                      'fecha': fechaSeleccionada ?? DateTime.now(),
                      'ubicacion': ubicacionCtrl.text.trim(),
                      'observaciones': observacionesCtrl.text.trim(),
                      'estadoAsistencia': estadoSeleccionado,
                      'nombreArchivo': nombreArchivo,
                      'urlArchivo': url ?? existente?.urlArchivo,
                      'usuarioID': FirebaseAuth.instance.currentUser!.uid,
                      'hijoID': widget.hijoID,
                    };

                    if (existente == null) {
                      await FirebaseFirestore.instance.collection('actividades').add(datos);
                    } else {
                      await FirebaseFirestore.instance.collection('actividades').doc(existente.id).update(datos);
                    }

                    Navigator.pop(context);
                    await cargarActividades();
                  }
                : null,
          ),
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
          : actividades.isEmpty
              ? Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Añadir actividad', style: TextStyle(fontFamily: 'Montserrat')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => subirActividad(),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: actividades.length,
                  itemBuilder: (context, index) {
                    final act = actividades[index];
                    final nombreArchivo = act.nombreArchivo ?? act.urlArchivo?.split('/').last;

                    final esConfirmada = act.estadoAsistencia == 'Confirmada';
                    final colorFondo = esConfirmada ? Colors.green[100] : Colors.amber[100];
                    final iconoEstado = esConfirmada
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.hourglass_top, color: Colors.orange);

                    return Card(
                      color: colorFondo,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                iconoEstado,
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    act.titulo,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMMd('es_ES').format(act.fecha),
                                  style: const TextStyle(color: Colors.black54, fontFamily: 'Montserrat'),
                                ),
                              ],
                            ),
                            if (act.ubicacion.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '📍 ${act.ubicacion}',
                                  style: const TextStyle(color: Colors.black87, fontFamily: 'Montserrat'),
                                ),
                              ),
                            if (act.observaciones.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '💬 ${act.observaciones}',
                                  style: const TextStyle(color: Colors.black54, fontFamily: 'Montserrat'),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (act.urlArchivo != null && nombreArchivo != null) ...[
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                                    tooltip: 'Ver documento',
                                    onPressed: () => DocumentoHelper.ver(context, nombreArchivo, act.urlArchivo!),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: Colors.green),
                                    tooltip: 'Descargar documento',
                                    onPressed: () => DocumentoHelper.descargar(context, nombreArchivo, act.urlArchivo!),
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                                  tooltip: 'Editar actividad',
                                  onPressed: () => subirActividad(existente: act),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  tooltip: 'Eliminar actividad',
                                  onPressed: () async {
                                    final confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: const Color(0xFF1B263B),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('¿Eliminar actividad?', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
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
                                      await FirebaseFirestore.instance.collection('actividades').doc(act.id).delete();
                                      await cargarActividades();
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
        tooltip: 'Añadir actividad',
        onPressed: () => subirActividad(),
      ),
    );
  }
}
