import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/models/modelo_pago.dart';
import 'package:entredos/widgets/pagos/formulario_pago.dart';
import 'package:entredos/widgets/pagos/tarjeta_pago.dart';
import 'package:flutter/material.dart';
import 'package:entredos/widgets/fallback_body.dart';
import 'package:entredos/utils/app_logger.dart';

class VistaPagosActivos extends StatefulWidget {
  final String hijoID;

  const VistaPagosActivos({super.key, required this.hijoID});

  @override
  State<VistaPagosActivos> createState() => _VistaPagosActivosState();
}

class _VistaPagosActivosState extends State<VistaPagosActivos> {
  late Future<List<ModeloPago>> pagosFuturos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Pagos activos',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<ModeloPago>>(
        future: pagosFuturos,
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
                '❌ Error al cargar los pagos: ${snapshot.error}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Montserrat',
                ),
              ),
            );
          }

          final pagos = snapshot.data ?? [];
          if (pagos.isEmpty) {
            return const Center(
              child: Text(
                'No hay pagos registrados aún',
                style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: pagos.length,
            itemBuilder: (_, index) => TarjetaPago(pago: pagos[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Registrar pago'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormularioPago(hijoID: widget.hijoID),
            ),
          );
          if (!mounted) return;
          setState(() {
            pagosFuturos = cargarPagos();
          });
        },
      ),
    );
  }

  Future<List<ModeloPago>> cargarPagos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pagos')
          .where('hijoID', isEqualTo: widget.hijoID)
          .get();

      appLogger.i('📦 Pagos encontrados: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        appLogger.d('🧾 Pago: ${doc.data()}');
      }

      return snapshot.docs.map((doc) => ModeloPago.fromFirestore(doc)).toList();
    } catch (e, st) {
      appLogger.e('❌ Error al cargar pagos: $e', e, st);
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    pagosFuturos = cargarPagos();
  }
}
