import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/tarjeta_ausencia.dart';
import 'package:entredos/helpers/ausencia_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VistaAusencias extends StatefulWidget {
  final String hijoID;

  const VistaAusencias({super.key, required this.hijoID});

  @override
  State<VistaAusencias> createState() => _VistaAusenciasState();
}

class _VistaAusenciasState extends State<VistaAusencias> {
  List<Map<String, dynamic>> ausencias = [];
  bool cargando = true;

  Future<void> anadirAusenciaAsync() async {
    await AusenciaHelper.crear(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarAusencias,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Ausencias')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ausencias.isEmpty
          ? const Center(
              child: Text(
                'No hay ausencias registradas aún.',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ausencias.length,
              itemBuilder: (_, index) {
                final ausencia = ausencias[index];
                final esPropio = ausencia['usuarioID'] == uidActual;

                return TarjetaAusencia(
                  fecha: ausencia['fecha'],
                  motivo: ausencia['motivo'] ?? '',
                  tipo: ausencia['tipo'] ?? 'ausencia',
                  observaciones: ausencia['observaciones'] ?? '',
                  nombreArchivo: ausencia['nombreArchivo'],
                  urlArchivo: ausencia['urlArchivo'],
                  docId: ausencia['id'],
                  uidActual: uidActual,
                  uidPropietario: ausencia['usuarioID'],
                  coleccion: 'ausencias',
                  puedeEditar: esPropio,
                  onEliminado: cargarAusencias,
                );
              },
            ),
      floatingActionButton: BotonAnadir(
        onPressed: anadirAusenciaAsync,
        tooltip: 'Registrar ausencia',
      ),
    );
  }

  Future<void> cargarAusencias() async {
    final resultado = await AusenciaHelper.obtenerPorHijo(widget.hijoID);

    // Diagnóstico: imprime cada ausencia para verificar campos
    for (var a in resultado) {
      print('🚫 ${a['motivo']} - ${a['hijoID']} - ${a['usuarioID']}');
    }

    setState(() {
      ausencias = resultado;
      cargando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarAusencias();
  }
}
