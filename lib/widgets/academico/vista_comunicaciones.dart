import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/tarjeta_mensaje.dart';
import 'package:entredos/helpers/comunicacion_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VistaComunicaciones extends StatefulWidget {
  final String hijoID;

  const VistaComunicaciones({super.key, required this.hijoID});

  @override
  State<VistaComunicaciones> createState() => _VistaComunicacionesState();
}

class _VistaComunicacionesState extends State<VistaComunicaciones> {
  List<Map<String, dynamic>> mensajes = [];
  bool cargando = true;

  Future<void> anadirMensajeAsync() async {
    await ComunicacionHelper.crear(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarMensajes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Comunicaciones del centro')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : mensajes.isEmpty
          ? const Center(
              child: Text(
                'No hay comunicaciones registradas aún.',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mensajes.length,
              itemBuilder: (_, index) {
                final msg = mensajes[index];
                final esPropio = msg['usuarioID'] == uidActual;

                return TarjetaMensaje(
                  titulo: msg['titulo'],
                  fecha: msg['fecha'],
                  contenido: msg['contenido'] ?? '',
                  tipo: msg['tipo'] ?? 'comunicación',
                  docId: msg['id'],
                  uidActual: uidActual,
                  uidPropietario: msg['usuarioID'],
                  coleccion: 'comunicaciones',
                  puedeEditar: esPropio,
                  onEliminado: cargarMensajes,
                );
              },
            ),
      floatingActionButton: BotonAnadir(
        onPressed: anadirMensajeAsync,
        tooltip: 'Añadir comunicación',
      ),
    );
  }

  Future<void> cargarMensajes() async {
    final resultado = await ComunicacionHelper.obtenerPorHijo(widget.hijoID);

    // Diagnóstico: imprime cada mensaje para verificar campos
    for (var msg in resultado) {
      print('📬 ${msg['titulo']} - ${msg['hijoID']} - ${msg['usuarioID']}');
    }

    setState(() {
      mensajes = resultado;
      cargando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarMensajes();
  }
}
