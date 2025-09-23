import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:entredos/helpers/documento_helper.dart';

class VistaMatricula extends StatefulWidget {
  final String hijoID;
  const VistaMatricula({required this.hijoID});

  @override
  State<VistaMatricula> createState() => _VistaMatriculaState();
}

class _VistaMatriculaState extends State<VistaMatricula> {
  List<Map<String, dynamic>> matriculas = [];

  @override
  void initState() {
    super.initState();
    cargarMatriculas();
  }

  Future<void> cargarMatriculas() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('matricula')
      .orderBy('fechaSubida', descending: true)
      .get();

  print('🔍 Total matrículas encontradas: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    final data = doc.data();
    print('📄 Matrícula: ${data['anioAcademico']} - hijoID: ${data['hijoID']}');
  }

  setState(() {
    matriculas = snapshot.docs
        .where((doc) => doc['hijoID'] == widget.hijoID)
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
  });
}

  Future<void> subirMatricula({bool editar = false, Map<String, dynamic>? matriculaExistente}) async {
    String? estadoSeleccionado = editar ? (matriculaExistente?['estado'] ?? 'Pendiente') : 'Pendiente';
    final anioCtrl = TextEditingController(text: editar ? (matriculaExistente?['anioAcademico'] ?? '') : '');
    PlatformFile? archivo;
    bool errorEstado = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          editar ? 'Editar matrícula' : 'Subir matrícula',
          style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: estadoSeleccionado,
                  items: ['Pendiente', 'Matriculado/a'].map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (valor) => setDialogState(() => estadoSeleccionado = valor ?? 'Pendiente'),
                  decoration: const InputDecoration(
                    labelText: 'Estado del trámite',
                    labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                    filled: true,
                    fillColor: Color(0xFF0D1B2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  dropdownColor: const Color(0xFF1B263B),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: anioCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  decoration: const InputDecoration(
                    labelText: 'Año académico (opcional)',
                    labelStyle: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                    filled: true,
                    fillColor: Color(0xFF0D1B2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    editar ? 'Sustituir documento' : 'Adjuntar documento',
                    style: const TextStyle(fontFamily: 'Montserrat'),
                  ),
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
                    child: Text(
                      '📎 Archivo: ${archivo!.name}',
                      style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Guardar', style: TextStyle(fontFamily: 'Montserrat')),
            onPressed: () async {
              if (estadoSeleccionado?.isEmpty ?? true) {
                setState(() => errorEstado = true);
                return;
              }

              String? url;
              String nombreArchivo = archivo?.name ?? matriculaExistente?['nombreArchivo'] ?? '';
              final ahora = DateTime.now();

              if (archivo?.bytes != null) {
                final ref = FirebaseStorage.instance.ref(
                  'matricula/${widget.hijoID}/${ahora.millisecondsSinceEpoch}_${archivo!.name}',
                );
                await ref.putData(archivo!.bytes!);
                url = await ref.getDownloadURL();
              }

              final datos = {
                'usuarioID': FirebaseAuth.instance.currentUser!.uid,
                'hijoID': widget.hijoID,
                'nombreArchivo': nombreArchivo,
                'urlArchivo': url ?? matriculaExistente?['urlArchivo'],
                'estado': estadoSeleccionado,
                'fechaSubida': ahora,
                'anioAcademico': anioCtrl.text.trim(),
              };

              if (editar && matriculaExistente != null && matriculaExistente['id'] != null) {
                await FirebaseFirestore.instance.collection('matricula').doc(matriculaExistente['id']).set(datos);
              } else {
                await FirebaseFirestore.instance.collection('matricula').add(datos);
              }

              Navigator.pop(context);
              await cargarMatriculas();
            },
          ),
        ],
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matriculas.length,
        itemBuilder: (context, index) {
          final matricula = matriculas[index];
          final fecha = (matricula['fechaSubida'] as Timestamp?)?.toDate();
          final fechaFormateada = fecha != null ? DateFormat('d MMMM y, HH:mm', 'es_ES').format(fecha) : '';

          return Card(
            color: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matricula['anioAcademico'] ?? 'Año no especificado',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: ${matricula['estado']}',
                    style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subido el: $fechaFormateada',
                    style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                  ),
const SizedBox(height: 12),
Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    IconButton(
      icon: const Icon(Icons.visibility, color: Colors.blueAccent),
      tooltip: 'Ver documento',
      onPressed: () => DocumentoHelper.ver(
        context,
        matricula['nombreArchivo'],
        matricula['urlArchivo'],
      ),
    ),
    IconButton(
      icon: const Icon(Icons.download, color: Colors.green),
      tooltip: 'Descargar documento',
      onPressed: () => DocumentoHelper.descargar(
        context,
        matricula['nombreArchivo'],
        matricula['urlArchivo'],
      ),
    ),
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.orangeAccent),
      tooltip: 'Editar matrícula',
      onPressed: () => subirMatricula(
        editar: true,
        matriculaExistente: matricula,
      ),
    ),
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.redAccent),
      tooltip: 'Eliminar matrícula',
      onPressed: () async {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('¿Eliminar matrícula?', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
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
              .collection('matricula')
              .doc(matricula['id'])
              .delete();
          await cargarMatriculas();
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
        onPressed: () => subirMatricula(),
      ),
    );
  }
}
