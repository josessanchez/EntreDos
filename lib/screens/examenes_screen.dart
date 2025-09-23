import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widgets/formulario_examen.dart';
import '../models/examen_model.dart';

class ExamenesScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const ExamenesScreen({
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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    cargarExamenes();
  }

  Future<void> cargarExamenes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('examenes')
        .where('hijoId', isEqualTo: widget.hijoId)
        .get();

    Map<DateTime, List<Examen>> mapa = {};

    for (var doc in snapshot.docs) {
      final examen = Examen.fromSnapshot(doc);
      final fechaClave = DateTime(examen.fecha.year, examen.fecha.month, examen.fecha.day);
      mapa.putIfAbsent(fechaClave, () => []);
      mapa[fechaClave]!.add(examen);
    }

    setState(() {
      examenesPorDia = mapa;
    });
  }

  List<Examen> examenesDelDia(DateTime day) {
    final fechaClave = DateTime(day.year, day.month, day.day);
    return examenesPorDia[fechaClave]
            ?.where((e) =>
              (filtroAsignatura == null || e.asignatura == filtroAsignatura) &&
              (filtroTipo == null || e.tipo == filtroTipo))
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    final fechasFiltradas = examenesPorDia.entries
        .where((entry) =>
          entry.value.any((e) =>
            (filtroAsignatura == null || e.asignatura == filtroAsignatura) &&
            (filtroTipo == null || e.tipo == filtroTipo)))
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => a.compareTo(b));

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
                    DropdownMenuItem(value: null, child: Text('Todas las asignaturas')),
                    ...['Matemáticas', 'Lengua', 'Inglés', 'Ciencias']
                        .map((asignatura) => DropdownMenuItem(
                          value: asignatura,
                          child: Text(asignatura),
                        )),
                  ],
                  onChanged: (nuevo) => setState(() => filtroAsignatura = nuevo),
                  decoration: InputDecoration(
                    labelText: 'Filtrar por asignatura',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: filtroTipo,
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todos los tipos')),
                    ...['Oral', 'Escrito'].map((tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo),
                    )),
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
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
              final nuevoExamen = await showDialog<Examen>(
                context: context,
                builder: (_) => FormularioExamen(
                  hijoId: widget.hijoId,
                  hijoNombre: widget.hijoNombre,
                ),
              );
              if (nuevoExamen != null) {
                cargarExamenes();
                ScaffoldMessenger.of(context).showSnackBar(
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
          final fechaTexto = DateFormat('dd/MM/yyyy – HH:mm').format(examen.fecha);
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