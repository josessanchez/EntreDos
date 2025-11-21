import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/models/modelo_disputa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:entredos/utils/app_logger.dart';

class FormularioDisputa extends StatefulWidget {
  final String hijoID;
  final String? pagoID; // opcional, si se lanza desde un pago específico

  const FormularioDisputa({super.key, required this.hijoID, this.pagoID});

  @override
  State<FormularioDisputa> createState() => _FormularioDisputaState();
}

class _FormularioDisputaState extends State<FormularioDisputa> {
  final _formKey = GlobalKey<FormState>();
  String? motivo;
  bool errorRegistro = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Registrar disputa',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Motivo de la disputa',
                ),
                maxLines: 3,
                onSaved: (value) => motivo = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Escribe el motivo' : null,
              ),
              if (errorRegistro)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ Error al registrar la disputa. Intenta nuevamente.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: registrarDisputa,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Registrar disputa',
                  style: TextStyle(fontSize: 16, fontFamily: 'Montserrat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registrarDisputa() async {
    setState(() => errorRegistro = false);

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => errorRegistro = true);
      return;
    }

    try {
      final ref = FirebaseFirestore.instance.collection('disputas').doc();
      final nuevaDisputa = ModeloDisputa(
        id: ref.id,
        pagoID: widget.pagoID ?? '',
        hijoID: widget.hijoID,
        creadorID: user.uid,
        creadorNombre: user.displayName ?? 'Tú',
        motivo: motivo!,
        estado: EstadoDisputa.pendiente,
        fechaCreacion: DateTime.now(),
      );

      await ref.set(nuevaDisputa.toMap());
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ Disputa registrada correctamente')),
      );
      navigator.pop();
    } catch (e, st) {
      appLogger.e('❌ Error al guardar disputa: $e', e, st);
      setState(() => errorRegistro = true);
    }
  }
}
