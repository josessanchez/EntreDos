import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/tarjeta_evento.dart';
import 'package:entredos/helpers/calendario_academico_helper.dart';
import 'package:entredos/helpers/evento_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  bool cargando = true;

  Future<void> anadirEventoAsync() async {
    await EventoHelper.crear(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarEventos,
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
                  eventLoader: (day) =>
                      eventosPorFecha[DateTime(day.year, day.month, day.day)] ??
                      [],
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
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
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

  Future<void> cargarEventos() async {
    final entradas = await CalendarioAcademicoHelper.obtenerEventosYActividades(
      widget.hijoID,
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
