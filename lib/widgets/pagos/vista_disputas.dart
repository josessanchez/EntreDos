import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/helpers/pago_helper.dart';
import 'package:entredos/models/modelo_disputa.dart';
import 'package:entredos/models/modelo_pago.dart';
import 'package:entredos/widgets/pagos/formulario_disputa.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entredos/widgets/fallback_body.dart';
import 'package:entredos/utils/app_logger.dart';

class VistaDisputas extends StatefulWidget {
  final String hijoID;

  const VistaDisputas({super.key, required this.hijoID});

  @override
  State<VistaDisputas> createState() => _VistaDisputasState();
}

class _TarjetaDisputa extends StatelessWidget {
  final ModeloDisputa disputa;

  const _TarjetaDisputa({required this.disputa});

  @override
  Widget build(BuildContext context) {
    final color = Color(
      PagoHelper.colorEstado(_estadoRelacionado(disputa.estado)),
    );
    final fecha = DateFormat('dd/MM/yyyy').format(disputa.fechaCreacion);
    final estado = disputa.estado.name.toUpperCase();

    return Card(
      color: color.withAlpha((0.1 * 255).round()),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado: $estado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${disputa.motivo}',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            if (disputa.respuesta != null) ...[
              const SizedBox(height: 8),
              Text(
                'Respuesta: ${disputa.respuesta}',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Creado por: ${disputa.creadorNombre}',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            Text(
              'Fecha: $fecha',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            if (disputa.fechaResolucion != null)
              Text(
                'Resuelto el: ${DateFormat('dd/MM/yyyy').format(disputa.fechaResolucion!)}',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
          ],
        ),
      ),
    );
  }

  EstadoPago _estadoRelacionado(EstadoDisputa estado) {
    switch (estado) {
      case EstadoDisputa.pendiente:
        return EstadoPago.validacionPendiente;
      case EstadoDisputa.aceptada:
        return EstadoPago.parcial;
      case EstadoDisputa.rechazada:
        return EstadoPago.enDisputa;
      case EstadoDisputa.resuelta:
        return EstadoPago.completado;
    }
  }
}

class _VistaDisputasState extends State<VistaDisputas> {
  late Future<List<ModeloDisputa>> disputasFuturas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Pagos en disputa',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<ModeloDisputa>>(
        future: disputasFuturas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final err = snapshot.error;
            if (err is FirebaseException && err.code == 'permission-denied') {
              return const FallbackHijosWidget();
            }
            return Center(
              child: Text(
                '❌ Error al cargar las disputas: ${snapshot.error}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Montserrat',
                ),
              ),
            );
          }

          final disputas = snapshot.data ?? [];
          if (disputas.isEmpty) {
            return const Center(
              child: Text(
                'No hay disputas registradas',
                style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: disputas.length,
            itemBuilder: (_, index) =>
                _TarjetaDisputa(disputa: disputas[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Registrar disputa'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormularioDisputa(hijoID: widget.hijoID),
            ),
          );
          if (!mounted) return;
          setState(() {
            disputasFuturas = cargarDisputas();
          });
        },
      ),
    );
  }

  Future<List<ModeloDisputa>> cargarDisputas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('disputas')
          .where('hijoID', isEqualTo: widget.hijoID)
          .get();

      appLogger.i('📦 Disputas encontradas: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        appLogger.d('🧾 Disputa: ${doc.data()}');
      }

      return snapshot.docs
          .map((doc) => ModeloDisputa.fromFirestore(doc))
          .toList();
    } catch (e, st) {
      appLogger.e('❌ Error al cargar disputas: $e', e, st);
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    disputasFuturas = cargarDisputas();
  }
}
