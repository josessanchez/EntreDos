import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Examen {
  final String id;
  final String asignatura;
  final String tipo;
  final DateTime fecha;
  final String observaciones;
  final String? nombreArchivo;
  final String? urlArchivo;
  final String usuarioID;

  Examen({
    required this.id,
    required this.asignatura,
    required this.tipo,
    required this.fecha,
    required this.observaciones,
    required this.usuarioID,
    this.nombreArchivo,
    this.urlArchivo,
  });

  factory Examen.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Examen(
      id: doc.id,
      asignatura: data['asignatura'] ?? '',
      tipo: data['tipo'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      observaciones: data['observaciones'] ?? '',
      nombreArchivo: data['nombreArchivo'],
      urlArchivo: data['urlArchivo'],
      usuarioID: data['usuarioID'],
    );
  }
}

class VistaExamenes extends StatefulWidget {
  final String hijoID;
  const VistaExamenes({required this.hijoID});

  @override
  State<VistaExamenes> createState() => _VistaExamenesState();
}

class _VistaExamenesState extends State<VistaExamenes> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  Map<DateTime, List<Examen>> examenesPorDia = {};
  String? tipoSeleccionado;
  String? asignaturaSeleccionada;
  List<String> asignaturasDisponibles = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    cargarExamenes();
  }

  Future<void> cargarExamenes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('examenes')
        .where('hijoID', isEqualTo: widget.hijoID)
        .get();

    Map<DateTime, List<Examen>> mapa = {};
    List<String> asignaturas = [];

    for (var doc in snapshot.docs) {
      final examen = Examen.fromSnapshot(doc);
      final fechaClave = DateTime(examen.fecha.year, examen.fecha.month, examen.fecha.day);

      mapa.putIfAbsent(fechaClave, () => []);
      mapa[fechaClave]!.add(examen);

      if (examen.asignatura.isNotEmpty) {
        asignaturas.add(examen.asignatura);
      }
    }

    setState(() {
      examenesPorDia = mapa;
      asignaturasDisponibles = asignaturas.toSet().toList();
    });
  }

  void mostrarExamenesDelDia(List<Examen> examenes) {
  if (examenes.isEmpty) return;
  final uidActual = FirebaseAuth.instance.currentUser?.uid;

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1B263B),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return PageView.builder(
          itemCount: examenes.length,
          itemBuilder: (_, index) {
            final examen = examenes[index];
            final nombreFallback = examen.nombreArchivo ?? examen.urlArchivo?.split('/').last.split('?').first;

            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (examenes.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.arrow_back_ios, size: 16, color: Colors.white70),
                              SizedBox(width: 8),
                              Text(
                                'Desliza para ver más exámenes del día',
                                style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              examen.asignatura,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (examen.usuarioID == uidActual) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () async {
                                Navigator.pop(context);
                                await subirExamen(examenExistente: examen);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                await DocumentoHelper.delete(
                                  context,
                                  examen.id,
                                  examen.nombreArchivo ?? nombreFallback ?? 'documento.pdf',
                                  examen.urlArchivo,
                                  uidActual!,
                                  examen.usuarioID,
                                  'examenes',
                                );
                                Navigator.pop(context);
                                await cargarExamenes();
                                mostrarExamenesDelDia(examenesDelDia(examen.fecha));
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Tipo: ${examen.tipo}',
                          style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
                      Text(
                        'Fecha: ${examen.fecha.day}/${examen.fecha.month}/${examen.fecha.year}',
                        style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                      ),
                      if ((examen.observaciones).trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Observaciones: ${examen.observaciones}',
                            style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                          ),
                        ),
                      if (examen.urlArchivo != null && nombreFallback != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          icon: getIconoPorExtension(nombreFallback),
                          label: const Text('Ver documento adjunto',
                              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                          onPressed: () => DocumentoHelper.ver(context, nombreFallback, examen.urlArchivo!),
                        ),
                        TextButton.icon(
                          icon: getIconoPorExtension(nombreFallback),
                          label: const Text('Descargar documento adjunto',
                              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                          onPressed: () => DocumentoHelper.descargar(context, nombreFallback, examen.urlArchivo!),
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
  );
}

    Future<void> subirExamen({Examen? examenExistente}) async {
    final asignaturaCtrl = TextEditingController(text: examenExistente?.asignatura ?? '');
    final tipoCtrl = TextEditingController(text: examenExistente?.tipo ?? '');
    final fecha = DateTime.now();
    DateTime? fechaSeleccionada = examenExistente?.fecha;
    final observacionesCtrl = TextEditingController(text: examenExistente?.observaciones ?? '');
    PlatformFile? archivo;
    bool errorAsignatura = false;
    bool errorFecha = false;
    String advertencia = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            examenExistente == null ? 'Añadir examen' : 'Editar examen',
            style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                if (advertencia.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(advertencia, style: TextStyle(color: Colors.red[800], fontFamily: 'Montserrat')),
                  ),
                TextField(
                  controller: asignaturaCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  decoration: InputDecoration(
                    labelText: 'Asignatura *',
                    labelStyle: TextStyle(
                      color: errorAsignatura ? Colors.redAccent : Colors.white70,
                      fontFamily: 'Montserrat',
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0D1B2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => setDialogState(() {
                    errorAsignatura = asignaturaCtrl.text.trim().isEmpty;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoCtrl.text.isEmpty ? null : tipoCtrl.text,
                  items: ['Oral', 'Escrito'].map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (valor) => setDialogState(() => tipoCtrl.text = valor ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Tipo (oral/escrito)',
                    labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                    filled: true,
                    fillColor: const Color(0xFF0D1B2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  dropdownColor: const Color(0xFF1B263B),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    fechaSeleccionada == null
                        ? '📅 Seleccionar fecha *'
                        : '📅 ${DateFormat.yMMMMd('es_ES').format(fechaSeleccionada!)}',
                    style: TextStyle(
                      color: fechaSeleccionada == null ? Colors.redAccent : Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.white),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada ?? fecha,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          dialogBackgroundColor: const Color(0xFF1B263B),
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.blueAccent,
                            onPrimary: Colors.white,
                            surface: Color(0xFF0D1B2A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        fechaSeleccionada = picked;
                        errorFecha = false;
                        advertencia = '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacionesCtrl,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D1B2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Adjuntar documento', style: TextStyle(fontFamily: 'Montserrat')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final resultado = await FilePicker.platform.pickFiles(withData: true);
                    if (resultado != null && resultado.files.isNotEmpty) {
                      setDialogState(() => archivo = resultado.files.first);
                    }
                  },
                ),
                if (archivo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '📎 Archivo: ${archivo?.name ?? 'Sin nombre'}',
                      style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: asignaturaCtrl.text.trim().isEmpty || fechaSeleccionada == null
                  ? null
                  : () async {
                      final fechaFinal = fechaSeleccionada;
                      String? url;
                      final nombreArchivo = archivo?.name ?? examenExistente?.nombreArchivo ?? '';

                      if (archivo?.bytes != null) {
  final ref = FirebaseStorage.instance.ref(
    'examenes/${widget.hijoID}/${DateTime.now().millisecondsSinceEpoch}_${archivo!.name}',
  );
  await ref.putData(archivo!.bytes!);
  url = await ref.getDownloadURL();
}


                      final datosExamen = {
                        'hijoID': widget.hijoID,
                        'usuarioID': FirebaseAuth.instance.currentUser!.uid,
                        'asignatura': asignaturaCtrl.text.trim(),
                        'tipo': tipoCtrl.text.trim(),
                        'fecha': fechaFinal,
                        'observaciones': observacionesCtrl.text.trim(),
                        'nombreArchivo': nombreArchivo,
                        'urlArchivo': url ?? examenExistente?.urlArchivo,
                      };

                      if (examenExistente == null) {
                        await FirebaseFirestore.instance.collection('examenes').add(datosExamen);
                      } else {
                        await FirebaseFirestore.instance
                            .collection('examenes')
                            .doc(examenExistente.id)
                            .update(datosExamen);
                      }

                      Navigator.pop(context);
                      await cargarExamenes();
                      if (fechaFinal != null) {
                        mostrarExamenesDelDia(examenesDelDia(fechaFinal));
                      }
                    },
              child: const Text('Guardar', style: TextStyle(fontFamily: 'Montserrat')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

    List<Examen> examenesDelDia(DateTime day) {
    final clave = DateTime(day.year, day.month, day.day);
    return examenesPorDia[clave] ?? [];
  }

  List<DateTime> fechasFiltradas() {
    if (tipoSeleccionado == null && asignaturaSeleccionada == null) return [];

    final hoy = DateTime.now();
    return examenesPorDia.entries
        .where((entry) {
          final hayFiltroTipo = tipoSeleccionado != null && tipoSeleccionado!.isNotEmpty;
          final hayFiltroAsig = asignaturaSeleccionada != null && asignaturaSeleccionada!.isNotEmpty;

          final cumpleAlMenosUno = entry.value.any((e) =>
              (!hayFiltroTipo || e.tipo == tipoSeleccionado) &&
              (!hayFiltroAsig || e.asignatura == asignaturaSeleccionada));

          return entry.key.isAfter(hoy.subtract(const Duration(days: 1))) && cumpleAlMenosUno;
        })
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  Icon getIconoPorExtension(String nombre) {
    final ext = nombre.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Icon(Icons.image, color: Colors.white);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.white);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.white);
      case 'xls':
      case 'xlsx':
        return const Icon(Icons.table_chart, color: Colors.white);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechasConFiltro = fechasFiltradas();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: asignaturaSeleccionada?.isEmpty ?? true ? null : asignaturaSeleccionada,
                items: [''].followedBy(asignaturasDisponibles).map((asig) {
                  return DropdownMenuItem(
                    value: asig,
                    child: Text(
                      asig.isEmpty ? 'Todas las asignaturas' : asig,
                      style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (valor) => setState(() => asignaturaSeleccionada = valor ?? ''),
                decoration: InputDecoration(
                  labelText: 'Filtrar por asignatura',
                  labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                  filled: true,
                  fillColor: const Color(0xFF1B263B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: const Color(0xFF1B263B),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipoSeleccionado?.isEmpty ?? true ? null : tipoSeleccionado,
                items: [''].followedBy(['Oral', 'Escrito']).map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(
                      tipo.isEmpty ? 'Todos los tipos' : tipo,
                      style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (valor) => setState(() => tipoSeleccionado = valor ?? ''),
                decoration: InputDecoration(
                  labelText: 'Filtrar por tipo',
                  labelStyle: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                  filled: true,
                  fillColor: const Color(0xFF1B263B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: const Color(0xFF1B263B),
              ),
              if (fechasConFiltro.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: fechasConFiltro.map((fecha) {
                      final texto = '${fecha.day}/${fecha.month}/${fecha.year}';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(texto, style: const TextStyle(fontFamily: 'Montserrat')),
                          backgroundColor: Colors.blueAccent,
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: () {
                            setState(() {
                              selectedDay = fecha;
                              focusedDay = fecha;
                            });
                            mostrarExamenesDelDia(examenesDelDia(fecha));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TableCalendar<Examen>(
                locale: 'es_ES',
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                eventLoader: examenesDelDia,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mes',
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  markerDecoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  defaultTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                  weekendTextStyle: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                  weekendStyle: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                ),
                headerStyle: const HeaderStyle(
                  titleTextStyle: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontSize: 16),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                ),
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                  mostrarExamenesDelDia(examenesDelDia(selected));
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir examen', style: TextStyle(fontFamily: 'Montserrat')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => subirExamen(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}