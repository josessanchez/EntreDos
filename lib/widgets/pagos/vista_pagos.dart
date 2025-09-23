import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:entredos/models/config_pagos.dart';
import 'package:entredos/models/modelo_pago.dart';
import 'package:entredos/widgets/pagos/formulario_pago.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VistaPagos extends StatefulWidget {
  final String hijoID;
  const VistaPagos({super.key, required this.hijoID});

  @override
  State<VistaPagos> createState() => _VistaPagosState();
}

class _VistaPagosState extends State<VistaPagos> {
  List<Pago> pagos = [];
  ConfigPagos? config;
  bool cargando = false;

  @override
  Widget build(BuildContext context) {
    final uidActual = FirebaseAuth.instance.currentUser!.uid;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        title: Text(
          'Pagos y contribuciones',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : pagos.isEmpty
          ? const Center(
              child: Text(
                'No hay pagos registrados para este alumno 💸',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                bottomPadding,
              ), // margen inferior extra
              itemCount: pagos.length,
              itemBuilder: (context, index) {
                final pago = pagos[index];
                final nombreArchivo =
                    pago.nombreArchivo ?? pago.urlArchivo?.split('/').last;

                final sumaTotal = pago.aportaciones.values.fold(
                  0.0,
                  (a, b) => a + b,
                );
                final diferencia = pago.montoTotal - sumaTotal;
                final estadoCalculado = pago.tipo == 'Común'
                    ? (sumaTotal >= pago.montoTotal ? 'Pagado' : 'Pendiente')
                    : pago.estado;

                final colorEstado = estadoCalculado == 'Pagado'
                    ? Colors.green[100]
                    : estadoCalculado == 'Pendiente'
                    ? Colors.amber[100]
                    : Colors.red[100];

                final resumenAportaciones = pago.aportaciones.entries
                    .map(
                      (e) =>
                          '👤 ${e.key.substring(0, 6)}: €${e.value.toStringAsFixed(2)}',
                    )
                    .join(' · ');

                final esCompartido =
                    config?.gastosCompartidos.any(
                      (g) => pago.titulo.toLowerCase().contains(
                        g.toLowerCase().trim(),
                      ),
                    ) ??
                    false;

                final usoDivisionFlexible = config?.divisionFlexible ?? true;
                final ideal = usoDivisionFlexible || !esCompartido
                    ? null
                    : (pago.montoTotal / pago.aportaciones.length);

                String balanceVisual = '';
                if (ideal != null && pago.aportaciones.length == 2) {
                  final sorted = pago.aportaciones.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final deudor = sorted.last;
                  final acreedor = sorted.first;
                  final diff = (ideal - deudor.value);
                  if (diff > 0) {
                    balanceVisual =
                        '⚖️ Reparto ideal: €${ideal.toStringAsFixed(2)} por persona\n📌 ${deudor.key.substring(0, 6)} le debe €${diff.toStringAsFixed(2)} a ${acreedor.key.substring(0, 6)}';
                  }
                }

                return IntrinsicHeight(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Columna lateral de estado
                        Container(
                          width: 12,
                          decoration: BoxDecoration(
                            color: colorEstado, // ya definido según estado
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                        // Contenido principal
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pago.titulo,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                          if (config
                                                  ?.notasPersonalizadas
                                                  .isNotEmpty ??
                                              false)
                                            Text(
                                              '🗒️ ${config!.notasPersonalizadas}',
                                              style: const TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontFamily: 'Montserrat',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      pago.tipo,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'editar') {
                                          await formularioPago(
                                            context: context,
                                            hijoID: widget.hijoID,
                                            datosIniciales: {
                                              ...{
                                                'id': pago.id,
                                                'fechaRegistro':
                                                    pago.fechaRegistro,
                                                'usuarioRegistroID':
                                                    pago.usuarioRegistroID,
                                              },
                                              'titulo': pago.titulo,
                                              'montoTotal': pago.montoTotal,
                                              'descripcion': pago.descripcion,
                                              'observaciones':
                                                  pago.observaciones,
                                              'estado': pago.estado,
                                              'motivoEstado': pago.motivoEstado,
                                              'tipo': pago.tipo,
                                              'nombreArchivo':
                                                  pago.nombreArchivo,
                                              'urlArchivo': pago.urlArchivo,
                                              'aportaciones': pago.aportaciones,
                                            },
                                            onGuardado: cargarDatos,
                                          );
                                        } else if (val == 'borrar') {
                                          await DocumentoHelper.delete(
                                            context,
                                            pago.id,
                                            nombreArchivo ?? 'documento.pdf',
                                            pago.urlArchivo,
                                            FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                            pago.usuarioRegistroID,
                                            'pagos',
                                          );
                                          await cargarDatos();
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'editar',
                                          child: Text('Editar'),
                                        ),
                                        PopupMenuItem(
                                          value: 'borrar',
                                          child: Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),
                                Text(
                                  '💰 Total: €${pago.montoTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                if (pago.descripcion.isNotEmpty)
                                  Text(
                                    '📝 ${pago.descripcion}',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                if (pago.observaciones.isNotEmpty)
                                  Text(
                                    '💬 ${pago.observaciones}',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  '🗓 Registrado: ${DateFormat.yMMMd('es_ES').format(pago.fechaRegistro)}',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                Text(
                                  '🗓 Último cambio: ${DateFormat.yMMMd('es_ES').format(pago.fechaCambioEstado)}',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '👥 Aportaciones: $resumenAportaciones',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                if (balanceVisual.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      balanceVisual,
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),
                                Text(
                                  estadoCalculado == 'Pagado'
                                      ? '✅ Total abonado'
                                      : '⚠️ Faltan €${diferencia.toStringAsFixed(2)} por abonar',
                                  style: TextStyle(
                                    color: estadoCalculado == 'Pagado'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                if (pago.estado != estadoCalculado)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'ℹ️ Este pago figura como "${pago.estado}", pero según las aportaciones debería estar en "$estadoCalculado".',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),
                                if (nombreArchivo != null &&
                                    pago.urlArchivo != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility),
                                    label: const Text(
                                      'Ver justificante',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    onPressed: () => DocumentoHelper.ver(
                                      context,
                                      nombreArchivo,
                                      pago.urlArchivo!,
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text(
                                      'Descargar justificante',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    onPressed: () => DocumentoHelper.descargar(
                                      context,
                                      nombreArchivo,
                                      pago.urlArchivo!,
                                    ),
                                  ),
                                ],
                                if (pago.estado == 'En disputa' &&
                                    pago.motivoEstado.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '📌 Motivo disputa: ${pago.motivoEstado}',
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: () => formularioPago(
          context: context,
          hijoID: widget.hijoID,
          onGuardado: cargarDatos,
        ),
        tooltip: 'Registrar nuevo pago',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('pagos')
        .where('hijoID', isEqualTo: widget.hijoID)
        .get();

    final configDoc = await FirebaseFirestore.instance
        .collection('hijos')
        .doc(widget.hijoID)
        .collection('configuracion')
        .doc('pagos')
        .get();

    final lista = snapshot.docs.map((doc) => Pago.fromSnapshot(doc)).toList()
      ..sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));

    setState(() {
      pagos = lista;
      config = configDoc.exists ? ConfigPagos.fromSnapshot(configDoc) : null;
      cargando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }
}
