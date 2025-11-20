import 'package:entredos/helpers/rendimiento_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VistaRendimiento extends StatefulWidget {
  final String hijoID;
  const VistaRendimiento({required this.hijoID, super.key});

  @override
  State<VistaRendimiento> createState() => _VistaRendimientoState();
}

class _VistaRendimientoState extends State<VistaRendimiento> {
  List<Map<String, dynamic>> rendimiento = [];
  String uidActual = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const TabBar(
                  labelColor: Colors.white,
                  indicatorColor: Colors.blueAccent,
                  tabs: [
                    Tab(text: 'Calificaciones'),
                    Tab(text: 'Evolución'),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              Expanded(
                child: TabBarView(
                  children: [
                    // Pestaña 1: Calificaciones
                    SafeArea(
                      child: Column(
                        children: [
                          Expanded(
                            child: rendimiento.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No hay registros de rendimiento académico aún.',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      80,
                                    ),
                                    itemCount: rendimiento.length,
                                    itemBuilder: (_, index) {
                                      final doc = rendimiento[index];
                                      final esPropio =
                                          doc['usuarioID'] == uidActual;
                                      final tipo = doc['tipo'] ?? '';

                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tipo,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Fecha: ${formatearFecha(doc['fecha'])}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (doc['asignatura'] != null)
                                                Text(
                                                  'Asignatura: ${doc['asignatura']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              if (doc['nota'] != null)
                                                Text(
                                                  'Nota: ${doc['nota'].toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              if (doc['trimestre'] != null)
                                                Text(
                                                  'Trimestre: ${doc['trimestre']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              if (doc['notasBoletin'] != null &&
                                                  doc['notasBoletin'] is List)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 8),
                                                    const Text(
                                                      'Notas del boletín:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    ...List<
                                                          Map<String, dynamic>
                                                        >.from(
                                                          doc['notasBoletin'],
                                                        )
                                                        .map(
                                                          (nota) => Text(
                                                            '${nota['asignatura']}: ${nota['nota'].toStringAsFixed(2)}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                        ),
                                                  ],
                                                ),
                                              if (doc['observaciones'] !=
                                                      null &&
                                                  doc['observaciones']
                                                      .toString()
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Text(
                                                    'Observaciones: ${doc['observaciones']}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              if (esPropio)
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.blue,
                                                      ),
                                                      onPressed: () async {
                                                        await RendimientoHelper.editar(
                                                          context: context,
                                                          doc: doc,
                                                          onGuardado:
                                                              cargarRendimiento,
                                                        );
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () async {
                                                        final confirmado = await showDialog<bool>(
                                                          context: context,
                                                          builder: (_) => AlertDialog(
                                                            title: const Text(
                                                              '¿Eliminar registro?',
                                                            ),
                                                            content: const Text(
                                                              'Esta acción no se puede deshacer.',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                child:
                                                                    const Text(
                                                                      'Cancelar',
                                                                    ),
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                              ),
                                                              ElevatedButton(
                                                                child:
                                                                    const Text(
                                                                      'Eliminar',
                                                                    ),
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        );

                                                        if (confirmado ==
                                                            true) {
                                                          await RendimientoHelper.eliminar(
                                                            doc['id'],
                                                          );
                                                          cargarRendimiento();
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Añadir registro'),
                              onPressed: () async {
                                await RendimientoHelper.crear(
                                  context: context,
                                  hijoID: widget.hijoID,
                                  onGuardado: cargarRendimiento,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pestaña 3: Resumen
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        Builder(
                          builder: (_) {
                            final boletines = rendimiento
                                .where(
                                  (r) =>
                                      r['tipo']
                                          ?.toString()
                                          .toLowerCase()
                                          .contains('trimestre') ??
                                      false,
                                )
                                .where(
                                  (r) =>
                                      r['notasBoletin'] != null &&
                                      r['notasBoletin'] is List,
                                )
                                .toList();

                            final tiene1 = boletines.any(
                              (r) => r['trimestre'] == '1º Trimestre',
                            );
                            final tiene2 = boletines.any(
                              (r) => r['trimestre'] == '2º Trimestre',
                            );

                            if (!tiene1 || !tiene2) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Para mostrar la evolución académica, debes añadir al menos los boletines del 1º y 2º trimestre.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }

                            final Map<String, Map<String, double>>
                            notasPorTrimestre = {};
                            for (final boletin in boletines) {
                              final trimestre = boletin['trimestre'];
                              final notas = List<Map<String, dynamic>>.from(
                                boletin['notasBoletin'],
                              );
                              for (final nota in notas) {
                                final asignatura = nota['asignatura'];
                                final valor = nota['nota'];
                                if (asignatura != null && valor is num) {
                                  notasPorTrimestre.putIfAbsent(
                                    trimestre,
                                    () => {},
                                  );
                                  notasPorTrimestre[trimestre]![asignatura] =
                                      valor.toDouble();
                                }
                              }
                            }

                            final asignaturas = <String>{};
                            for (var mapa in notasPorTrimestre.values) {
                              asignaturas.addAll(mapa.keys);
                            }

                            final List<Map<String, dynamic>> resumen = [];

                            for (final asignatura in asignaturas) {
                              final nota1 =
                                  notasPorTrimestre['1º Trimestre']?[asignatura];
                              final nota2 =
                                  notasPorTrimestre['2º Trimestre']?[asignatura];
                              final nota3 =
                                  notasPorTrimestre['3º Trimestre']?[asignatura];

                              if (nota1 == null || nota2 == null) continue;

                              final media =
                                  [
                                    nota1,
                                    nota2,
                                    if (nota3 != null) nota3,
                                  ].reduce((a, b) => a + b) /
                                  [1, 1, if (nota3 != null) 1].length;

                              String evolucion;
                              Icon icono;
                              Color color;

                              if (nota3 != null) {
                                if (nota1 < nota2 && nota2 < nota3) {
                                  evolucion = 'Ascendente';
                                  icono = const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.green,
                                  );
                                  color = Colors.green;
                                } else if (nota1 > nota2 && nota2 > nota3) {
                                  evolucion = 'Descendente';
                                  icono = const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.red,
                                  );
                                  color = Colors.red;
                                } else if (nota1 < nota2 && nota2 > nota3) {
                                  evolucion =
                                      'Irregular y descendente al final';
                                  icono = const Icon(
                                    Icons.trending_down,
                                    color: Colors.amber,
                                  );
                                  color = Colors.amber;
                                } else if (nota1 > nota2 && nota2 < nota3) {
                                  evolucion =
                                      'Irregular, aunque ascendente al final';
                                  icono = const Icon(
                                    Icons.trending_up,
                                    color: Colors.amber,
                                  );
                                  color = Colors.amber;
                                } else if (nota1 < nota2 && nota2 == nota3) {
                                  evolucion = 'Ascendente, luego estable';
                                  icono = const Icon(
                                    Icons.trending_flat,
                                    color: Colors.green,
                                  );
                                  color = Colors.green;
                                } else if (nota1 > nota2 && nota2 == nota3) {
                                  evolucion = 'Descendente, luego estable';
                                  icono = const Icon(
                                    Icons.trending_flat,
                                    color: Colors.red,
                                  );
                                  color = Colors.red;
                                } else if (nota1 == nota2 && nota2 == nota3) {
                                  evolucion = 'Constante';
                                  icono = const Icon(
                                    Icons.remove,
                                    color: Colors.grey,
                                  );
                                  color = Colors.grey;
                                } else if (nota1 == nota2 && nota2 < nota3) {
                                  evolucion = 'Constante, luego ascendente';
                                  icono = const Icon(
                                    Icons.trending_up,
                                    color: Colors.green,
                                  );
                                  color = Colors.green;
                                } else if (nota1 == nota2 && nota2 > nota3) {
                                  evolucion = 'Constante, luego descendente';
                                  icono = const Icon(
                                    Icons.trending_down,
                                    color: Colors.red,
                                  );
                                  color = Colors.red;
                                } else {
                                  evolucion = 'Irregular';
                                  icono = const Icon(
                                    Icons.swap_vert,
                                    color: Colors.amber,
                                  );
                                  color = Colors.amber;
                                }
                              } else {
                                if (nota2 > nota1) {
                                  evolucion = 'Ascendente';
                                  icono = const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.green,
                                  );
                                  color = Colors.green;
                                } else if (nota2 < nota1) {
                                  evolucion = 'Descendente';
                                  icono = const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.red,
                                  );
                                  color = Colors.red;
                                } else {
                                  evolucion = 'Constante';
                                  icono = const Icon(
                                    Icons.remove,
                                    color: Colors.grey,
                                  );
                                  color = Colors.grey;
                                }
                              }

                              resumen.add({
                                'asignatura': asignatura,
                                'media': media,
                                'evolucion': evolucion,
                                'icono': icono,
                                'color': color,
                              });
                            }

                            resumen.sort(
                              (a, b) => a['evolucion'].toString().compareTo(
                                b['evolucion'].toString(),
                              ),
                            );
                            final descendentes = resumen
                                .where((r) => r['evolucion'] == 'Descendente')
                                .toList();

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (descendentes.length >= 2)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade900,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '⚠️ Atención: Varias asignaturas muestran evolución descendente. Revisa con tu hijo/a posibles dificultades.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(1),
                                      2: FlexColumnWidth(2),
                                    },
                                    border: TableBorder.symmetric(
                                      inside: BorderSide(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    children: [
                                      const TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Asignatura',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Media',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Evolución',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ...resumen.map(
                                        (r) => TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              child: Center(
                                                child: Text(
                                                  r['asignatura'],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              child: Center(
                                                child: Text(
                                                  r['media'].toStringAsFixed(2),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              child: Center(
                                                // Mostrar sólo el icono en la tabla para evitar overflow.
                                                // Se mantiene un Tooltip (y Semantics) para acceder al texto completo en táctil.
                                                child: Semantics(
                                                  label:
                                                      r['evolucion']
                                                          ?.toString() ??
                                                      '',
                                                  child: Tooltip(
                                                    message:
                                                        r['evolucion']
                                                            ?.toString() ??
                                                        '',
                                                    triggerMode:
                                                        TooltipTriggerMode.tap,
                                                    waitDuration: Duration.zero,
                                                    showDuration:
                                                        const Duration(
                                                          seconds: 3,
                                                        ),
                                                    child: r['icono'],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),
                                  ...[
                                    // 1️⃣ Descendentes
                                    if (resumen.any(
                                      (r) => r['evolucion']
                                          .toString()
                                          .toLowerCase()
                                          .startsWith('descendente'),
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🔴 Asignaturas con evolución descendente:',
                                              style: TextStyle(
                                                color: Colors.red.shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...resumen
                                                .where(
                                                  (r) => r['evolucion']
                                                      .toString()
                                                      .toLowerCase()
                                                      .startsWith(
                                                        'descendente',
                                                      ),
                                                )
                                                .map(
                                                  (r) => Text(
                                                    '• ${r['asignatura']}: Revisa posibles dificultades. Puede ser útil contactar con el tutor o reforzar el estudio en casa.',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),

                                    // 2️⃣ Irregular y descendente al final
                                    if (resumen.any(
                                      (r) =>
                                          r['evolucion'] ==
                                          'Irregular y descendente al final',
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🟡 Asignaturas con evolución irregular y caída final:',
                                              style: TextStyle(
                                                color: Colors.amber.shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...resumen
                                                .where(
                                                  (r) =>
                                                      r['evolucion'] ==
                                                      'Irregular y descendente al final',
                                                )
                                                .map(
                                                  (r) => Text(
                                                    '• ${r['asignatura']}: La evolución ha sido inestable con una caída final. Conviene intervenir pronto para evitar que se consolide.',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),

                                    // 3️⃣ Irregular pero ascendente al final
                                    if (resumen.any(
                                      (r) =>
                                          r['evolucion'] ==
                                          'Irregular, aunque ascendente al final',
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🟡 Asignaturas con evolución irregular pero mejora final:',
                                              style: TextStyle(
                                                color: Colors.amber.shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...resumen
                                                .where(
                                                  (r) =>
                                                      r['evolucion'] ==
                                                      'Irregular, aunque ascendente al final',
                                                )
                                                .map(
                                                  (r) => Text(
                                                    '• ${r['asignatura']}: La evolución ha sido inestable, pero el cierre es positivo. Refuerza lo que ha funcionado para consolidar la mejora.',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),

                                    // 4️⃣ Todas constantes
                                    if (resumen.every(
                                      (r) => r['evolucion'] == 'Constante',
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '⚪ Todas las asignaturas muestran evolución constante:',
                                              style: TextStyle(
                                                color: Colors.grey.shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'ℹ️ El rendimiento se ha mantenido estable. Puedes revisar si hay margen de mejora o si el nivel actual es adecuado.',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // 5️⃣ Constante, luego descendente
                                    if (resumen.any(
                                      (r) =>
                                          r['evolucion'] ==
                                          'Constante, luego descendente',
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🔴 Asignaturas con rendimiento estable y caída final:',
                                              style: TextStyle(
                                                color: Colors.red.shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...resumen
                                                .where(
                                                  (r) =>
                                                      r['evolucion'] ==
                                                      'Constante, luego descendente',
                                                )
                                                .map(
                                                  (r) => Text(
                                                    '• ${r['asignatura']}: Rendimiento estable con caída final. Conviene revisar si ha habido un cambio de contexto o motivación.',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),

                                    // 6️⃣ Descendente, luego estable
                                    if (resumen.any(
                                      (r) =>
                                          r['evolucion'] ==
                                          'Descendente, luego estable',
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🔴 Asignaturas con caída seguida de estabilización:',
                                              style: TextStyle(
                                                color: Colors.red.shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...resumen
                                                .where(
                                                  (r) =>
                                                      r['evolucion'] ==
                                                      'Descendente, luego estable',
                                                )
                                                .map(
                                                  (r) => Text(
                                                    '• ${r['asignatura']}: Caída seguida de estabilización. Puede ser útil reforzar lo aprendido para evitar recaídas.',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),

                                    // 7️⃣ Irregular sin tendencia clara
                                    if (resumen.any(
                                      (r) => r['evolucion'] == 'Irregular',
                                    ))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🟡 Asignaturas con evolución irregular sin patrón claro:',
                                              style: TextStyle(
                                                color: Colors.amber.shade300,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ...resumen
                                                .where(
                                                  (r) =>
                                                      r['evolucion'] ==
                                                      'Irregular',
                                                )
                                                .map(
                                                  (r) => Text(
                                                    '• ${r['asignatura']}: Evolución inestable sin patrón claro. Conviene observar si hay factores externos o falta de constancia.',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, double> calcularMediaPorTrimestre(
    List<Map<String, dynamic>> registros,
  ) {
    final Map<String, List<double>> agrupadas = {};

    for (final registro in registros) {
      final tipo = registro['tipo']?.toString().toLowerCase() ?? '';
      final trimestre = registro['trimestre'];
      final nota = registro['nota'];
      final notasBoletin = registro['notasBoletin'];

      double? media;

      if (nota != null && nota is num) {
        media = nota.toDouble();
      } else if (notasBoletin != null && notasBoletin is List) {
        final notas = notasBoletin
            .map((n) => n['nota'])
            .whereType<num>()
            .map((n) => n.toDouble())
            .toList();
        if (notas.isNotEmpty) {
          media = notas.reduce((a, b) => a + b) / notas.length;
        }
      }

      if (media != null && tipo.contains('trimestre') && trimestre != null) {
        agrupadas.putIfAbsent(trimestre, () => []);
        agrupadas[trimestre]!.add(media);
      }
    }

    final Map<String, double> medias = {};
    agrupadas.forEach((trimestre, notas) {
      final media = notas.reduce((a, b) => a + b) / notas.length;
      medias[trimestre] = media;
    });

    return medias;
  }

  String calcularResumenFinal(List<Map<String, dynamic>> registros) {
    final Map<String, List<double>> agrupadas = {};

    for (final registro in registros) {
      final tipo = registro['tipo']?.toString().toLowerCase() ?? '';
      final trimestre = registro['trimestre'];
      final nota = registro['nota'];
      final notasBoletin = registro['notasBoletin'];

      double? media;

      if (nota != null && nota is num) {
        media = nota.toDouble();
      } else if (notasBoletin != null && notasBoletin is List) {
        final notas = notasBoletin
            .map((n) => n['nota'])
            .whereType<num>()
            .map((n) => n.toDouble())
            .toList();
        if (notas.isNotEmpty) {
          media = notas.reduce((a, b) => a + b) / notas.length;
        }
      }

      if (media != null && tipo.contains('trimestre') && trimestre != null) {
        agrupadas.putIfAbsent(trimestre, () => []);
        agrupadas[trimestre]!.add(media);
      }
    }

    if (agrupadas.isEmpty) {
      return 'No hay datos suficientes para generar un resumen.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Resumen de rendimiento académico:\n');

    agrupadas.forEach((trimestre, notas) {
      final media = notas.reduce((a, b) => a + b) / notas.length;
      buffer.writeln('$trimestre → Media: ${media.toStringAsFixed(2)}');
    });

    return buffer.toString();
  }

  Future<void> cargarRendimiento() async {
    final datos = await RendimientoHelper.obtenerPorHijo(widget.hijoID);
    setState(() {
      rendimiento = datos;
    });
  }

  String formatearFecha(String fechaISO) {
    final fecha = DateTime.tryParse(fechaISO);
    if (fecha == null) return 'Fecha inválida';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  void initState() {
    super.initState();
    uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';
    cargarRendimiento();
  }
}
