import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/models/modelo_disputa.dart';
import 'package:entredos/models/modelo_pago.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VistaHistorial extends StatefulWidget {
  final String hijoID;
  const VistaHistorial({super.key, required this.hijoID});

  @override
  State<VistaHistorial> createState() => _VistaHistorialState();
}

class _VistaHistorialState extends State<VistaHistorial> {
  DateTime mesSeleccionado = DateTime.now();
  String filtroEstado = 'Todos';
  late Future<List<dynamic>> registrosDelMes;

  @override
  Widget build(BuildContext context) {
    final formatoMes = DateFormat('MMMM yyyy', 'es_ES').format(mesSeleccionado);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Historial mensual',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1B263B),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => cambiarMes(-1),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      formatoMes,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                      ),
                    ),
                    DropdownButton<String>(
                      value: filtroEstado,
                      dropdownColor: const Color(0xFF1B263B),
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                      underline: const SizedBox(),
                      items:
                          [
                                'Todos',
                                'Pendiente',
                                'Parcial',
                                'Completado',
                                'En disputa',
                              ]
                              .map(
                                (estado) => DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          filtroEstado = value!;
                          registrosDelMes = cargarRegistrosDelMes();
                        });
                      },
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => cambiarMes(1),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: registrosDelMes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      '❌ Error al cargar el historial',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  );
                }
                final registros = snapshot.data ?? [];
                if (registros.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay registros este mes',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: registros.length,
                  itemBuilder: (_, index) {
                    final r = registros[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == registros.length - 1 ? 32 : 16,
                      ),
                      child: Card(
                        color: _colorPorEstado(r),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r is ModeloPago
                                    ? r.tipoGasto
                                    : 'Disputa registrada',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (r is ModeloPago &&
                                  r.comentario != null &&
                                  r.comentario!.isNotEmpty)
                                Text(
                                  'Comentario: ${r.comentario}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              if (r is ModeloPago) ...[
                                Text(
                                  'Registrado por: ${r.responsableNombre}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Importe total: ${r.importeTotal.toStringAsFixed(2)} €',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Pagado: ${r.cantidadPagada.toStringAsFixed(2)} €',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Estado: ${r.estadoCalculado}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy').format(r.fechaRegistro)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ] else if (r is ModeloDisputa) ...[
                                Text(
                                  'Motivo: ${r.motivo}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Creado por: ${r.creadorNombre}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy').format(r.fechaCreacion)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void cambiarMes(int offset) {
    setState(() {
      mesSeleccionado = DateTime(
        mesSeleccionado.year,
        mesSeleccionado.month + offset,
        1,
      );
      registrosDelMes = cargarRegistrosDelMes();
    });
  }

  Future<List<dynamic>> cargarRegistrosDelMes() async {
    final inicioMes = DateTime(mesSeleccionado.year, mesSeleccionado.month, 1);
    final finMes = DateTime(mesSeleccionado.year, mesSeleccionado.month + 1, 1);

    try {
      final pagosSnap = await FirebaseFirestore.instance
          .collection('pagos')
          .where('hijoID', isEqualTo: widget.hijoID)
          .get();

      final disputasSnap = await FirebaseFirestore.instance
          .collection('disputas')
          .where('hijoID', isEqualTo: widget.hijoID)
          .get();

      final pagos = pagosSnap.docs
          .map((doc) => ModeloPago.fromFirestore(doc))
          .where(
            (p) =>
                p.fechaRegistro.isAfter(inicioMes) &&
                p.fechaRegistro.isBefore(finMes),
          )
          .toList();

      final disputas = disputasSnap.docs
          .map((doc) => ModeloDisputa.fromFirestore(doc))
          .where(
            (d) =>
                d.fechaCreacion.isAfter(inicioMes) &&
                d.fechaCreacion.isBefore(finMes),
          )
          .toList();

      final pagosEnDisputa = disputas.map((d) => d.pagoID).toSet();

      for (var pago in pagos) {
        if (pagosEnDisputa.contains(pago.id)) {
          pago.estadoCalculado = 'En disputa';
        } else if (pago.cantidadPagada == 0) {
          pago.estadoCalculado = 'Pendiente';
        } else if (pago.cantidadPagada < pago.importeTotal) {
          pago.estadoCalculado = 'Parcial';
        } else {
          pago.estadoCalculado = 'Completado';
        }
      }

      List<dynamic> combinados = [...pagos, ...disputas];

      if (filtroEstado != 'Todos') {
        combinados = combinados.where((r) {
          if (r is ModeloPago) return r.estadoCalculado == filtroEstado;
          if (r is ModeloDisputa) return filtroEstado == 'En disputa';
          return false;
        }).toList();
      }

      return combinados;
    } catch (e) {
      print('❌ Error al cargar registros del mes: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    registrosDelMes = cargarRegistrosDelMes();
  }

  Color _colorPorEstado(dynamic r) {
    if (r is ModeloPago) {
      switch (r.estadoCalculado) {
        case 'Pendiente':
          return const Color.fromARGB(255, 221, 162, 51);
        case 'Parcial':
          return const Color.fromARGB(255, 43, 133, 235);
        case 'Completado':
          return const Color.fromARGB(255, 18, 145, 87);
        case 'En disputa':
          return const Color(0xFF9B2226);
        default:
          return const Color(0xFF1B263B);
      }
    } else if (r is ModeloDisputa) {
      return const Color(0xFF9B2226);
    }
    return const Color(0xFF1B263B);
  }
}
