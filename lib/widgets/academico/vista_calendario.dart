// Replaced with clean implementation
import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/tarjeta_evento.dart';
import 'package:entredos/helpers/calendario_academico_helper.dart';
import 'package:entredos/helpers/evento_helper.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/evento_model.dart';
import '../formulario_evento.dart';

class VistaCalendario extends StatefulWidget {
  final String hijoID;

  const VistaCalendario({super.key, required this.hijoID});

  @override
  State<VistaCalendario> createState() => _VistaCalendarioState();
}

class _VistaCalendarioState extends State<VistaCalendario> {
  Map<DateTime, List<Map<String, dynamic>>> eventosPorFecha = {};
  List<Map<String, dynamic>> eventosDelMes = [];
  DateTime hoy = DateTime.now();
  DateTime? selectedDay;
  bool cargando = true;

  Future<void> anadirEventoAsync() async {
    await EventoHelper.crear(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarEventos,
      coleccionDestino: 'eventosAcademico',
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario escolar')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: hoy,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  eventLoader: (day) =>
                      eventosPorFecha[DateTime(day.year, day.month, day.day)] ??
                      [],
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      hoy = focused;
                    });
                    final items = eventosDelDia(selected);
                    if (items.isNotEmpty) mostrarEventosDelDia(items);
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Próximos eventos del mes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: eventosDelMes.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay eventos programados para este mes.',
                            style: TextStyle(fontFamily: 'Montserrat'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: eventosDelMes.length,
                          itemBuilder: (_, index) {
                            final evento = eventosDelMes[index];
                            final esPropio = evento['usuarioID'] == uidActual;

                            return TarjetaEvento(
                              titulo: evento['titulo'],
                              fecha: DateFormat.yMMMd(
                                'es_ES',
                              ).format(DateTime.parse(evento['fecha'])),
                              descripcion: evento['descripcion'] ?? '',
                              tipo: evento['tipo'] ?? 'evento',
                              nombreArchivo: evento['nombreArchivo'],
                              urlArchivo: evento['urlArchivo'],
                              docId: evento['id'],
                              uidActual: uidActual,
                              uidPropietario: evento['usuarioID'],
                              coleccion: evento['coleccion'] ?? 'eventos',
                              puedeEditar: esPropio,
                              onEliminado: cargarEventos,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: BotonAnadir(
        onPressed: anadirEventoAsync,
        tooltip: 'Añadir evento escolar',
      ),
    );
  }

  List<Map<String, dynamic>> eventosDelDia(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return eventosPorFecha[key] ?? [];
  }

  void mostrarEventosDelDia(List<Map<String, dynamic>> eventos) {
    if (eventos.isEmpty) return;

    final uidActual = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF1B263B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PageView.builder(
        itemCount: eventos.length,
        itemBuilder: (_, index) {
          final evento = eventos[index];
          final nombreFallback =
              evento['nombreArchivo'] ??
              (evento['urlArchivo'] != null
                  ? evento['urlArchivo']
                        .toString()
                        .split('/')
                        .last
                        .split('?')
                        .first
                  : null);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        evento['titulo'] ?? 'Sin título',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (evento['usuarioID'] == uidActual) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () async {
                          final eventoModelo = Evento(
                            id: evento['id'] ?? '',
                            titulo: evento['titulo'] ?? '',
                            tipo: evento['tipo'] ?? '',
                            fecha:
                                DateTime.tryParse(evento['fecha']) ??
                                DateTime.now(),
                            hijoId: widget.hijoID,
                            hijoNombre: evento['hijoNombre'] ?? '',
                            creadorUid: evento['usuarioID'] ?? '',
                            documentoUrl:
                                evento['urlArchivo'] ?? evento['documentoUrl'],
                            documentoNombre:
                                evento['nombreArchivo'] ??
                                evento['documentoNombre'],
                            notas: evento['descripcion'] ?? evento['notas'],
                          );

                          final eventoEditado = await showDialog<Evento>(
                            context: context,
                            builder: (_) => FormularioEvento(
                              hijoId: widget.hijoID,
                              hijoNombre: evento['hijoNombre'] ?? '',
                              eventoExistente: eventoModelo,
                              coleccion: 'eventosAcademico',
                            ),
                          );

                          if (eventoEditado != null) {
                            Navigator.pop(context);
                            await cargarEventos();
                            mostrarEventosDelDia(
                              eventosDelDia(eventoModelo.fecha),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1B263B),
                              title: const Text(
                                'Eliminar evento',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                '¿Estás seguro de que quieres eliminar este evento?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  child: const Text('Eliminar'),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await DocumentoHelper.delete(
                              context,
                              evento['id'],
                              nombreFallback ?? evento['titulo'] ?? 'documento',
                              evento['urlArchivo'],
                              uidActual ?? '',
                              evento['usuarioID'] ?? '',
                              evento['coleccion'] ?? 'eventos',
                            );
                            Navigator.pop(context);
                            await cargarEventos();
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tipo: ${evento['tipo'] ?? ''}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Fecha: ${DateTime.parse(evento['fecha']).day}/${DateTime.parse(evento['fecha']).month}/${DateTime.parse(evento['fecha']).year}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white70,
                  ),
                ),
                if (evento['documentoUrl'] != null ||
                    evento['urlArchivo'] != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text(
                      'Ver documento adjunto',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => DocumentoHelper.ver(
                      context,
                      nombreFallback ?? '',
                      evento['urlArchivo'] ?? evento['documentoUrl'],
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'Descargar documento adjunto',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => DocumentoHelper.descargar(
                      context,
                      nombreFallback ?? '',
                      evento['urlArchivo'] ?? evento['documentoUrl'],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (evento['descripcion'] != null &&
                    evento['descripcion'].toString().isNotEmpty)
                  Text(
                    'Descripción: ${evento['descripcion']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> cargarEventos() async {
    final entradas = await CalendarioAcademicoHelper.obtenerEventosYActividades(
      widget.hijoID,
      coleccionEventos: 'eventosAcademico',
    );
    final Map<DateTime, List<Map<String, dynamic>>> agrupados = {};
    final List<Map<String, dynamic>> proximos = [];

    for (var entrada in entradas) {
      final fecha = DateTime.parse(entrada['fecha']);
      final fechaClave = DateTime(fecha.year, fecha.month, fecha.day);

      agrupados.putIfAbsent(fechaClave, () => []).add(entrada);

      if (fecha.isAfter(hoy) &&
          fecha.month == hoy.month &&
          fecha.year == hoy.year) {
        proximos.add(entrada);
      }

      // Diagnóstico: imprime cada entrada para verificar campos
      // ignore: avoid_print
      print(
        '📅 ${entrada['titulo']} - ${entrada['fecha']} - ${entrada['coleccion']}',
      );
    }

    setState(() {
      eventosPorFecha = agrupados;
      eventosDelMes = proximos;
      cargando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarEventos();
  }
}
