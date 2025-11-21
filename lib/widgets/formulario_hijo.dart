import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:entredos/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

class FormularioHijo extends StatefulWidget {
  final DocumentSnapshot? hijoExistente;

  const FormularioHijo({super.key, this.hijoExistente});

  @override
  _FormularioHijoState createState() => _FormularioHijoState();
}

class _FormularioHijoState extends State<FormularioHijo> {
  final nombreController = TextEditingController();
  final apellidosController = TextEditingController();
  final docIdController = TextEditingController();
  final colegioController = TextEditingController();
  final observacionesController = TextEditingController();

  DateTime? fechaNacimiento;
  File? foto;
  String? fotoUrl;
  bool guardando = false;

  bool nombreError = false;
  bool apellidosError = false;
  bool fechaError = false;
  bool docIdError = false;
  String? docIdErrorText;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.hijoExistente != null) {
      final data = widget.hijoExistente!.data() as Map<String, dynamic>;
      nombreController.text = data['nombre'] ?? '';
      apellidosController.text = data['apellidos'] ?? '';
      docIdController.text = data['dni'] ?? '';
      colegioController.text = data['colegio'] ?? '';
      observacionesController.text = data['observaciones'] ?? '';
      fechaNacimiento = (data['fechaNacimiento'] as Timestamp?)?.toDate();
      fotoUrl = data['fotoUrl'] ?? '';
    }
  }

  bool esDocumentoValido(String texto) {
    return texto.trim().length >= 6;
  }

  Future<void> seleccionarFoto() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) setState(() => foto = File(result.path));
  }

  String generarCodigoInvitacion(String nombre) {
    final uuid = Uuid().v4().substring(0, 6).toUpperCase();
    final base = nombre.trim().replaceAll(' ', '').toUpperCase();
    return 'ED-$base-$uuid';
  }

  Future<void> guardarHijo() async {
    final nombre = nombreController.text.trim();
    final apellidos = apellidosController.text.trim();
    final identificador = docIdController.text.trim();
    final colegio = colegioController.text.trim();
    final observaciones = observacionesController.text.trim();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      nombreError = nombre.isEmpty;
      apellidosError = apellidos.isEmpty;
      fechaError =
          fechaNacimiento == null || fechaNacimiento!.isAfter(DateTime.now());

      docIdError = false;
      docIdErrorText = null;
      if (identificador.isNotEmpty && !esDocumentoValido(identificador)) {
        docIdError = true;
        docIdErrorText = 'El número parece demasiado corto';
      }
    });

    if (nombreError ||
        apellidosError ||
        fechaError ||
        docIdError ||
        user?.uid == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ Corrige los errores del formulario'),
          backgroundColor: Color(0xFF0D1B2A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      if (foto != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'hijos/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final uploadTask = ref.putFile(
          foto!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask.whenComplete(() => null);
        fotoUrl = await snapshot.ref.getDownloadURL();
      }
    } catch (e, st) {
      appLogger.e('❌ Error al subir imagen: $e', e, st);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('❌ Error al subir imagen'),
          backgroundColor: Color(0xFF0D1B2A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final datosHijo = {
      'nombre': nombre,
      'apellidos': apellidos,
      'dni': identificador,
      'colegio': colegio,
      'observaciones': observaciones,
      'fechaNacimiento': fechaNacimiento,
      'fotoUrl': fotoUrl ?? '',
    };

    try {
      if (widget.hijoExistente != null) {
        await widget.hijoExistente!.reference.update(datosHijo);
        navigator.pop(null);
      } else {
        final codigo = generarCodigoInvitacion(nombre);
        await FirebaseFirestore.instance.collection('hijos').add({
          ...datosHijo,
          'progenitores': [user!.uid],
          'uidCreador': user!.uid,
          'creadorNombre':
              user?.displayName ?? user?.email ?? 'Usuario desconocido',
          'codigoInvitacion': codigo,
          'fechaCreacion': Timestamp.now(),
        });
        navigator.pop(codigo);
      }
    } catch (e, st) {
      appLogger.e('❌ Error al guardar hijo: $e', e, st);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('❌ Error al guardar hijo'),
          backgroundColor: Color(0xFF0D1B2A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => guardando = false);
    }
  }

  InputDecoration campo(String label, bool error, [String? errorText]) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontFamily: 'Montserrat',
      ),
      filled: true,
      fillColor: const Color(0xFF0D1B2A),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.greenAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esValido =
        nombreController.text.trim().isNotEmpty &&
        apellidosController.text.trim().isNotEmpty &&
        fechaNacimiento != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.hijoExistente != null ? 'Editar hijo/a' : 'Añadir hijo/a',
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.photo, size: 20),
                label: Text(foto == null ? 'Seleccionar foto' : 'Cambiar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: seleccionarFoto,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: campo('Nombre *', nombreError),
                controller: nombreController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
                onChanged: (_) => setState(() => nombreError = false),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: campo('Apellidos *', apellidosError),
                controller: apellidosController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
                onChanged: (_) => setState(() => apellidosError = false),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: campo(
                  'Documento identificativo',
                  docIdError,
                  docIdErrorText,
                ),
                controller: docIdController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
                onChanged: (_) => setState(() {
                  docIdError = false;
                  docIdErrorText = null;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: campo('Colegio', false),
                controller: colegioController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: campo('Observaciones', false),
                controller: observacionesController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  fechaNacimiento == null
                      ? 'Seleccionar fecha nacimiento *'
                      : 'Fecha: ${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                  style: TextStyle(
                    color: fechaError ? Colors.red : Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),

                onPressed: () async {
                  final nuevaFecha = await showDatePicker(
                    context: context,
                    initialDate: fechaNacimiento ?? DateTime(2010),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (nuevaFecha != null) {
                    setState(() {
                      fechaNacimiento = nuevaFecha;
                      fechaError = false;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'Montserrat',
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: esValido ? Colors.greenAccent : Colors.grey,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: guardando || !esValido ? null : guardarHijo,
          child: guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Guardar',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
