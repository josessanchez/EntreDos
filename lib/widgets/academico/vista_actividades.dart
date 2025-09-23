import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/tarjeta_evento.dart';
import 'package:entredos/helpers/actividad_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VistaActividades extends StatefulWidget {
  final String hijoID;

  const VistaActividades({super.key, required this.hijoID});

  @override
  State<VistaActividades> createState() => _VistaActividadesState();
}

class _VistaActividadesState extends State<VistaActividades> {
  List<Map<String, dynamic>> actividades = [];
  bool cargando = true;

  Future<void> anadirActividadAsync() async {
    await ActividadHelper.crear(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarActividades,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Actividades escolares')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : actividades.isEmpty
          ? const Center(
              child: Text(
                'No hay actividades escolares registradas aún.',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: actividades.length,
              itemBuilder: (_, index) {
                final actividad = actividades[index];
                final esPropio = actividad['usuarioID'] == uidActual;

                return TarjetaEvento(
                  titulo: actividad['titulo'],
                  fecha: DateFormat.yMMMd(
                    'es_ES',
                  ).format(DateTime.parse(actividad['fecha'])),
                  descripcion: actividad['descripcion'] ?? '',
                  tipo: actividad['tipo'] ?? 'actividad',
                  nombreArchivo: actividad['nombreArchivo'],
                  urlArchivo: actividad['urlArchivo'],
                  docId: actividad['id'],
                  uidActual: uidActual,
                  uidPropietario: actividad['usuarioID'],
                  coleccion: 'actividades',
                  puedeEditar: esPropio,
                  onEliminado: cargarActividades,
                );
              },
            ),
      floatingActionButton: BotonAnadir(
        onPressed: anadirActividadAsync,
        tooltip: 'Añadir actividad escolar',
      ),
    );
  }

  Future<void> cargarActividades() async {
    final resultado = await ActividadHelper.obtenerPorHijo(widget.hijoID);

    // Diagnóstico: imprime cada actividad para verificar campos
    for (var a in resultado) {
      print('🎯 ${a['titulo']} - ${a['hijoID']} - ${a['usuarioID']}');
    }

    setState(() {
      actividades = resultado;
      cargando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarActividades();
  }
}
