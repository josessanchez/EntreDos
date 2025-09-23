import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/evento_model.dart';
import '../widgets/formulario_evento.dart';
import '../utils/documento_utils.dart';
import '../helpers/documento_helper.dart';

class CalendarioScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const CalendarioScreen({
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<DateTime, List<Evento>> eventosPorDia = {};

  final List<String> tiposEvento = ['Actividad', 'Cumpleaños', 'Médico'];
  String? tipoSeleccionado;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    cargarEventos();
  }

  Future<void> cargarEventos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos')
        .where('hijoId', isEqualTo: widget.hijoId)
        .get();

    Map<DateTime, List<Evento>> mapa = {};

    for (var doc in snapshot.docs) {
      final evento = Evento.fromSnapshot(doc);
      final fechaClave = DateTime(
        evento.fecha.year,
        evento.fecha.month,
        evento.fecha.day,
      );
      mapa.putIfAbsent(fechaClave, () => []);
      mapa[fechaClave]!.add(evento);
    }

    setState(() {
      eventosPorDia = mapa;
    });
  }

  List<Evento> eventosDelDia(DateTime day) {
    final fechaClave = DateTime(day.year, day.month, day.day);
    return eventosPorDia[fechaClave] ?? [];
  }

  List<DateTime> fechasPorTipoSeleccionado() {
    if (tipoSeleccionado == null) return [];
    final hoy = DateTime.now();
    final fechas = eventosPorDia.entries
        .where((entry) =>
            entry.key.isAfter(hoy.subtract(Duration(days: 1))) &&
            entry.value.any((e) => e.tipo == tipoSeleccionado))
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => a.compareTo(b));
    return fechas;
  }

  Icon getIconoPorExtension(String nombre) {
    final ext = nombre.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icon(Icons.image);
      case 'pdf':
        return Icon(Icons.picture_as_pdf);
      case 'doc':
      case 'docx':
        return Icon(Icons.description);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.table_chart);
      default:
        return Icon(Icons.insert_drive_file);
    }
  }

    @override
  Widget build(BuildContext context) {
    final fechasFiltradas = fechasPorTipoSeleccionado();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          'Calendario de ${widget.hijoNombre}',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1B263B),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: DropdownButtonFormField<String>(
              value: tipoSeleccionado,
              dropdownColor: Color(0xFF1B263B),
              style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
              items: tiposEvento
                  .map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo,
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (nuevoTipo) {
                setState(() {
                  tipoSeleccionado = nuevoTipo;
                });
              },
              decoration: InputDecoration(
                labelText: 'Filtrar por tipo de evento',
                labelStyle:
                    TextStyle(fontFamily: 'Montserrat', color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (fechasFiltradas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Días con eventos "$tipoSeleccionado":',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: fechasFiltradas.map((fecha) {
                      final texto =
                          '${fecha.day}/${fecha.month}/${fecha.year}';
                      return ActionChip(
                        label: Text(texto,
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.white)),
                        backgroundColor: Colors.blueAccent,
                        onPressed: () {
                          setState(() {
                            selectedDay = fecha;
                            focusedDay = fecha;
                          });
                          mostrarEventosDelDia(eventosDelDia(fecha));
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          TableCalendar<Evento>(
            locale: 'es_ES',
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            eventLoader: eventosDelDia,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mes',
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: Colors.blueAccent, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white70),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70),
              weekendStyle: TextStyle(color: Colors.white70),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
              mostrarEventosDelDia(eventosDelDia(selected));
            },
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Añadir evento al calendario',
                  style: TextStyle(fontFamily: 'Montserrat')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final evento = await showDialog<Evento>(
                  context: context,
                  builder: (_) => FormularioEvento(
                    hijoId: widget.hijoId,
                    hijoNombre: widget.hijoNombre,
                  ),
                );

                if (evento != null) {
                  cargarEventos();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: Text(
                        '✅ Evento creado',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

    void mostrarEventosDelDia(List<Evento> eventos) {
    if (eventos.isEmpty) return;

    final uidActual = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Color(0xFF1B263B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PageView.builder(
        itemCount: eventos.length,
        itemBuilder: (_, index) {
          final evento = eventos[index];
          final nombreFallback = evento.documentoNombre ??
              evento.documentoUrl?.split('/').last.split('?').first;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_ios, size: 16, color: Colors.white54),
                    SizedBox(width: 8),
                    Text(
                      'Desliza para ver más eventos del día',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        evento.titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (evento.creadorUid == uidActual) ...[
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.white70),
                        onPressed: () async {
                          final eventoEditado = await showDialog<Evento>(
                            context: context,
                            builder: (_) => FormularioEvento(
                              hijoId: widget.hijoId,
                              hijoNombre: widget.hijoNombre,
                              eventoExistente: evento,
                            ),
                          );

                          if (eventoEditado != null) {
                            Navigator.pop(context);
                            await cargarEventos();
                            mostrarEventosDelDia(eventosDelDia(evento.fecha));
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Color(0xFF1B263B),
                              title: Text(
                                'Eliminar evento',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              content: Text(
                                '¿Estás seguro de que quieres eliminar este evento?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Cancelar',
                                      style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          color: Colors.white)),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                                ElevatedButton(
                                  child: Text('Eliminar',
                                      style: TextStyle(
                                          fontFamily: 'Montserrat')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('eventos')
                                .doc(evento.id)
                                .delete();

                            Navigator.pop(context);
                            cargarEventos();
                          }
                        },
                      ),
                    ]
                  ],
                ),
                SizedBox(height: 8),
                Text('Tipo: ${evento.tipo}',
                    style: TextStyle(
                        fontFamily: 'Montserrat', color: Colors.white)),
                Text(
                  'Fecha: ${evento.fecha.day}/${evento.fecha.month}/${evento.fecha.year}',
                  style: TextStyle(
                      fontFamily: 'Montserrat', color: Colors.white70),
                ),
                if (evento.documentoUrl != null && nombreFallback != null) ...[
                  SizedBox(height: 12),
                  TextButton.icon(
                    icon: getIconoPorExtension(nombreFallback),
                    label: Text('Ver documento adjunto',
                        style: TextStyle(fontFamily: 'Montserrat')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => DocumentoHelper.ver(
                        context, nombreFallback, evento.documentoUrl!),
                  ),
                  TextButton.icon(
                    icon: getIconoPorExtension(nombreFallback),
                    label: Text('Descargar documento adjunto',
                        style: TextStyle(fontFamily: 'Montserrat')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => DocumentoHelper.descargar(
                        context, nombreFallback, evento.documentoUrl!),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}