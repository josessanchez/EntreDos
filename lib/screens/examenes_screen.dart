import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../widgets/formulario_examen.dart';
import '../models/examen_model.dart';
import 'package:entredos/widgets/fallback_body.dart';

class ExamenesScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const ExamenesScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _ExamenesScreenState createState() => _ExamenesScreenState();
}

class _ExamenesScreenState extends State<ExamenesScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<DateTime, List<Examen>> examenesPorDia = {};
  String? filtroAsignatura;
  String? filtroTipo;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    cargarExamenes();
  }

  Future<void> cargarExamenes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('examenes')
          .where('hijoId', isEqualTo: widget.hijoId)
          .get();

      Map<DateTime, List<Examen>> mapa = {};

      for (var doc in snapshot.docs) {
        final examen = Examen.fromSnapshot(doc);
        final fechaClave = DateTime(
          examen.fecha.year,
          examen.fecha.month,
          examen.fecha.day,
        );
        mapa.putIfAbsent(fechaClave, () => []);
        mapa[fechaClave]!.add(examen);
      }

      if (!mounted) return;
      setState(() {
        examenesPorDia = mapa;
        _showFallback = false;
      });
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        if (!mounted) return;
        setState(() {
          _showFallback = true;
        });
        return;
      }
      rethrow;
    }
  }

  List<Examen> examenesDelDia(DateTime day) {
    final fechaClave = DateTime(day.year, day.month, day.day);
    return examenesPorDia[fechaClave]
            ?.where(
              (e) =>
                  (filtroAsignatura == null ||
                      e.asignatura == filtroAsignatura) &&
                  (filtroTipo == null || e.tipo == filtroTipo),
            )
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    if (_showFallback) {
      return Scaffold(
        appBar: AppBar(title: Text('Exámenes de ${widget.hijoNombre}')),
        body: const FallbackHijosWidget(),
      );
    }
    // fechasFiltradas not used in UI — skip computing it to avoid unused_local_variable

    return Scaffold(
      appBar: AppBar(title: Text('Exámenes de ${widget.hijoNombre}')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: filtroAsignatura,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todas las asignaturas'),
                    ),
                    ...['Matemáticas', 'Lengua', 'Inglés', 'Ciencias'].map(
                      (asignatura) => DropdownMenuItem(
                        value: asignatura,
                        child: Text(asignatura),
                      ),
                    ),
                  ],
                  onChanged: (nuevo) =>
                      setState(() => filtroAsignatura = nuevo),
                  decoration: InputDecoration(
                    labelText: 'Filtrar por asignatura',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: filtroTipo,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todos los tipos'),
                    ),
                    ...['Oral', 'Escrito'].map(
                      (tipo) =>
                          DropdownMenuItem(value: tipo, child: Text(tipo)),
                    ),
                  ],
                  onChanged: (nuevo) => setState(() => filtroTipo = nuevo),
                  decoration: InputDecoration(
                    labelText: 'Filtrar por tipo de examen',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          TableCalendar<Examen>(
            locale: 'es_ES',
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            eventLoader: examenesDelDia,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
              mostrarExamenesDelDia(examenesDelDia(selected));
            },
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Añadir examen'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final localContext = context;

              final nuevoExamen = await showDialog<Examen>(
                context: localContext,
                builder: (_) => FormularioExamen(
                  hijoId: widget.hijoId,
                  hijoNombre: widget.hijoNombre,
                ),
              );
              if (nuevoExamen != null) {
                cargarExamenes();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('✅ Examen añadido')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void mostrarExamenesDelDia(List<Examen> examenes) {
    if (examenes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: EdgeInsets.all(16),
        children: examenes.map((examen) {
          final fechaTexto = DateFormat(
            'dd/MM/yyyy – HH:mm',
          ).format(examen.fecha);
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(examen.asignatura),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo: ${examen.tipo}'),
                  Text('Fecha: $fechaTexto'),
                  if (examen.observaciones.isNotEmpty)
                    Text('🗒️ ${examen.observaciones}'),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
