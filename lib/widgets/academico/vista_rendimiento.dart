import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/grafica_evolucion_academica.dart';
import 'package:entredos/helpers/rendimiento_helper.dart';
import 'package:entredos/models/nota_academica.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VistaRendimiento extends StatefulWidget {
  final String hijoID;

  const VistaRendimiento({super.key, required this.hijoID});

  @override
  State<VistaRendimiento> createState() => _VistaRendimientoState();
}

class _VistaRendimientoState extends State<VistaRendimiento>
    with SingleTickerProviderStateMixin {
  String trimestreAsignaturasSeleccionado = 'Todos';
  String trimestreSeleccionado = 'Todos';
  String asignaturaSeleccionada = '';
  List<Map<String, dynamic>> rendimiento = [];
  List<NotaAcademica> notasGraficables = [];
  Map<String, List<NotaAcademica>> notasPorAsignatura = {};
  bool cargando = true;
  late TabController tabController;

  Future<void> anadirRegistroAsync() async {
    await RendimientoHelper.crear(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarRendimiento,
    );
  }

  @override
  Widget build(BuildContext context) {
    final medias = calcularMediaPorAsignatura(trimestreSeleccionado);
    final tendencias = detectarTendenciaPorAsignatura(trimestreSeleccionado);
    final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendimiento académico'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Calificaciones'),
            Tab(text: 'Gráfica rendimiento'),
            Tab(text: 'Evolución asignaturas'),
          ],
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: tabController,
              children: [
                // Pestaña 1: Calificaciones
                Column(
                  children: [
                    Expanded(
                      child: rendimiento.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay registros de rendimiento académico aún.',
                                style: TextStyle(fontFamily: 'Montserrat'),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: rendimiento.length,
                              itemBuilder: (_, index) {
                                final doc = rendimiento[index];
                                final esPropio = doc['usuarioID'] == uidActual;
                                final tipo = doc['tipo'];
                                final color = tipo == 'nota'
                                    ? Colors.blue[50]
                                    : tipo == 'boletín'
                                    ? Colors.green[50]
                                    : Colors.orange[50];

                                return Card(
                                  color: color,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc['titulo'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Fecha: ${doc['fecha']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (doc['observaciones'] != null)
                                          Text(
                                            'Observaciones: ${doc['observaciones']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        if (tipo == 'nota') ...[
                                          if (doc['asignatura'] != null)
                                            Text(
                                              'Asignatura: ${doc['asignatura']}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          if (doc['nota'] != null)
                                            Text(
                                              'Nota: ${doc['nota']}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                        ],
                                        if (tipo == 'boletín' &&
                                            doc['notasBoletin'] != null &&
                                            doc['notasBoletin'] is List) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Notas del boletín:',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Column(
                                            children:
                                                (doc['notasBoletin'] as List).map<
                                                  Widget
                                                >((entrada) {
                                                  final asignatura =
                                                      entrada['asignatura'] ??
                                                      '';
                                                  final nota =
                                                      entrada['nota'] ?? '';
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        asignatura.toString(),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      Text(
                                                        nota.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                          ),
                                        ],
                                        if (doc['urlArchivo'] != null)
                                          TextButton.icon(
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                            ),
                                            label: const Text(
                                              'Ver archivo',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                            onPressed: () {
                                              // Abrir archivo adjunto
                                            },
                                          ),
                                        if (esPropio)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Color.fromARGB(
                                                  255,
                                                  78,
                                                  78,
                                                  78,
                                                ),
                                              ),
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('rendimiento')
                                                    .doc(doc['id'])
                                                    .delete();
                                                cargarRendimiento();
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    BotonAnadir(
                      onPressed: anadirRegistroAsync,
                      tooltip: 'Añadir registro de rendimiento',
                    ),
                  ],
                ),

                // Pestaña 2: Gráfica rendimiento
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        value: trimestreSeleccionado,
                        items:
                            [
                                  'Todos',
                                  '1º Trimestre',
                                  '2º Trimestre',
                                  '3º Trimestre',
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            trimestreSeleccionado = val ?? 'Todos';
                          });
                        },
                      ),
                    ),
                    if (notasGraficables.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GraficaEvolucionAcademica(
                          notas: filtrarPorTrimestre(
                            notasGraficables,
                            trimestreSeleccionado,
                          ),
                        ),
                      ),
                    if (medias.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Media por asignatura',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(1),
                              },
                              children: medias.entries.map((entry) {
                                final color = colorSegunNota(entry.value);
                                final tendencia = tendencias[entry.key] ?? '';
                                final notasAsignatura = filtrarPorTrimestre(
                                  notasPorAsignatura[entry.key]!,
                                  trimestreSeleccionado,
                                );
                                final alerta =
                                    notasAsignatura.length >= 2 &&
                                        (notasAsignatura.last.valor -
                                                notasAsignatura[notasAsignatura
                                                            .length -
                                                        2]
                                                    .valor) <=
                                            -2.0
                                    ? '⚠️'
                                    : '';
                                return TableRow(
                                  decoration: BoxDecoration(color: color),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        entry.value.toStringAsFixed(2),
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        '$tendencia $alerta',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Pestaña 3: Evolución asignaturas
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        value: asignaturaSeleccionada,
                        items: notasPorAsignatura.keys
                            .map(
                              (asignatura) => DropdownMenuItem(
                                value: asignatura,
                                child: Text(asignatura),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            asignaturaSeleccionada =
                                val ?? notasPorAsignatura.keys.first;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        value: trimestreAsignaturasSeleccionado,
                        items:
                            [
                                  'Todos',
                                  '1º Trimestre',
                                  '2º Trimestre',
                                  '3º Trimestre',
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            trimestreAsignaturasSeleccionado = val ?? 'Todos';
                          });
                        },
                      ),
                    ),
                    if (asignaturaSeleccionada.isNotEmpty &&
                        notasPorAsignatura.containsKey(asignaturaSeleccionada))
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GraficaEvolucionAcademica(
                          notas: filtrarPorTrimestre(
                            notasPorAsignatura[asignaturaSeleccionada]!,
                            trimestreAsignaturasSeleccionado,
                          ),
                        ),
                      ),
                    if (asignaturaSeleccionada.isNotEmpty &&
                        notasPorAsignatura.containsKey(asignaturaSeleccionada))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen de la asignatura',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (_) {
                                final notasFiltradas = filtrarPorTrimestre(
                                  notasPorAsignatura[asignaturaSeleccionada]!,
                                  trimestreAsignaturasSeleccionado,
                                );
                                if (notasFiltradas.isEmpty) {
                                  return const Text(
                                    'No hay registros para esta asignatura en el trimestre seleccionado.',
                                    style: TextStyle(color: Colors.white),
                                  );
                                }
                                final media =
                                    notasFiltradas
                                        .map((n) => n.valor)
                                        .reduce((a, b) => a + b) /
                                    notasFiltradas.length;
                                final color = colorSegunNota(media);
                                final tendencia =
                                    detectarTendenciaPorAsignatura(
                                      trimestreAsignaturasSeleccionado,
                                    )[asignaturaSeleccionada] ??
                                    '';
                                final alerta =
                                    notasFiltradas.length >= 2 &&
                                        (notasFiltradas.last.valor -
                                                notasFiltradas[notasFiltradas
                                                            .length -
                                                        2]
                                                    .valor) <=
                                            -2.0
                                    ? '⚠️'
                                    : '';
                                return Container(
                                  color: color,
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Media: ${media.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Tendencia: $tendencia $alerta',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: anadirRegistroAsync,
        tooltip: 'Añadir registro de rendimiento',
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, double> calcularMediaPorAsignatura(String trimestre) {
    final medias = <String, double>{};
    notasPorAsignatura.forEach((asignatura, listaNotas) {
      final filtradas = filtrarPorTrimestre(listaNotas, trimestre);
      if (filtradas.isNotEmpty) {
        final suma = filtradas.map((n) => n.valor).reduce((a, b) => a + b);
        medias[asignatura] = suma / filtradas.length;
      }
    });
    return medias;
  }

  Future<void> cargarRendimiento() async {
    final resultado = await RendimientoHelper.obtenerPorHijo(widget.hijoID);

    final notas = <NotaAcademica>[];
    final asignaturas = <String, List<NotaAcademica>>{};

    for (var doc in resultado) {
      final fecha = DateTime.tryParse(doc['fecha'] ?? '') ?? DateTime.now();

      if ((doc['tipo'] == 'Nota examen' || doc['tipo'] == 'Nota trabajo') &&
          doc['nota'] != null &&
          double.tryParse(doc['nota'].toString()) != null) {
        final valor = double.parse(doc['nota'].toString());
        final nota = NotaAcademica(
          fecha: fecha,
          valor: valor,
          trimestre: doc['trimestre'],
        );
        notas.add(nota);

        final asignatura = doc['asignatura']?.toString() ?? 'Sin asignatura';
        asignaturas.putIfAbsent(asignatura, () => []).add(nota);
      }

      if ((doc['tipo'] == 'Boletín de notas (trimestre)' ||
              doc['tipo'] == 'Boletín de notas (anual)') &&
          doc['notasBoletin'] != null &&
          doc['notasBoletin'] is List) {
        for (var entrada in doc['notasBoletin']) {
          if (entrada['nota'] != null &&
              double.tryParse(entrada['nota'].toString()) != null) {
            final valor = double.parse(entrada['nota'].toString());
            final nota = NotaAcademica(
              fecha: fecha,
              valor: valor,
              trimestre: doc['trimestre'],
            );
            notas.add(nota);

            final asignatura =
                entrada['asignatura']?.toString() ?? 'Sin asignatura';
            asignaturas.putIfAbsent(asignatura, () => []).add(nota);
          }
        }
      }
    }

    notas.sort((a, b) => a.fecha.compareTo(b.fecha));

    setState(() {
      rendimiento = resultado;
      notasGraficables = notas;
      notasPorAsignatura = asignaturas;
      cargando = false;

      // ✅ Inicializar asignaturaSeleccionada si hay asignaturas disponibles
      if (asignaturas.isNotEmpty) {
        asignaturaSeleccionada = asignaturas.keys.first;
      }
    });
  }

  Color colorSegunNota(double nota) {
    if (nota >= 7.0) return Colors.green[100]!;
    if (nota >= 5.0) return Colors.orange[100]!;
    return Colors.red[100]!;
  }

  Map<String, String> detectarTendenciaPorAsignatura(String trimestre) {
    final tendencias = <String, String>{};
    notasPorAsignatura.forEach((asignatura, listaNotas) {
      final filtradas = filtrarPorTrimestre(listaNotas, trimestre);
      if (filtradas.length >= 2) {
        final ultima = filtradas.last.valor;
        final penultima = filtradas[filtradas.length - 2].valor;
        if (ultima > penultima) {
          tendencias[asignatura] = '⬆️';
        } else if (ultima < penultima) {
          tendencias[asignatura] = '⬇️';
        } else {
          tendencias[asignatura] = '➡️';
        }
      }
    });
    return tendencias;
  }

  List<NotaAcademica> filtrarPorTrimestre(
    List<NotaAcademica> notas,
    String trimestre,
  ) {
    if (trimestre == 'Todos') return notas;
    return notas.where((nota) => nota.trimestre == trimestre).toList();
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    cargarRendimiento();
  }
}
