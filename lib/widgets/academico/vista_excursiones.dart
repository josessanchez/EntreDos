import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/tarjeta_evento.dart';
import 'package:entredos/helpers/excursion_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VistaExcursiones extends StatefulWidget {
  final String hijoID;

  const VistaExcursiones({super.key, required this.hijoID});

  @override
  State<VistaExcursiones> createState() => _VistaExcursionesState();
}

class _VistaExcursionesState extends State<VistaExcursiones> {
  List<Map<String, dynamic>> excursiones = [];
  bool cargando = true;

  Future<void> anadirExcursionAsync() async {
    await ExcursionHelper.crear(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarExcursiones,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Excursiones escolares')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : excursiones.isEmpty
          ? const Center(
              child: Text(
                'No hay excursiones registradas aún.',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: excursiones.length,
              itemBuilder: (_, index) {
                final excursion = excursiones[index];
                final esPropio = excursion['usuarioID'] == uidActual;

                return TarjetaEvento(
                  titulo: excursion['titulo'],
                  fecha: DateFormat.yMMMd(
                    'es_ES',
                  ).format(DateTime.parse(excursion['fecha'])),
                  descripcion: excursion['descripcion'] ?? '',
                  tipo: excursion['tipo'] ?? 'excursión',
                  nombreArchivo: excursion['nombreArchivo'],
                  urlArchivo: excursion['urlArchivo'],
                  docId: excursion['id'],
                  uidActual: uidActual,
                  uidPropietario: excursion['usuarioID'],
                  coleccion: 'excursiones',
                  puedeEditar: esPropio,
                  onEliminado: cargarExcursiones,
                );
              },
            ),
      floatingActionButton: BotonAnadir(
        onPressed: anadirExcursionAsync,
        tooltip: 'Añadir excursión escolar',
      ),
    );
  }

  Future<void> cargarExcursiones() async {
    final resultado = await ExcursionHelper.obtenerPorHijo(widget.hijoID);

    // Diagnóstico: imprime cada excursión para verificar campos
    for (var e in resultado) {
      print('🚌 ${e['titulo']} - ${e['hijoID']} - ${e['usuarioID']}');
    }

    setState(() {
      excursiones = resultado;
      cargando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarExcursiones();
  }
}
