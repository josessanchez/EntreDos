import 'package:entredos/widgets/academico/vista_actividades.dart';
import 'package:entredos/widgets/academico/vista_ausencias.dart';
import 'package:entredos/widgets/academico/vista_calendario.dart';
import 'package:entredos/widgets/academico/vista_comunicaciones.dart';
import 'package:entredos/widgets/academico/vista_documentacion.dart';
import 'package:entredos/widgets/academico/vista_excursiones.dart';
import 'package:entredos/widgets/academico/vista_rendimiento.dart';
import 'package:flutter/material.dart';

class AcademicoScreen extends StatelessWidget {
  final String hijoID;
  final String nombreHijo;

  const AcademicoScreen({
    super.key,
    required this.hijoID,
    required this.nombreHijo,
  });

  @override
  Widget build(BuildContext context) {
    final secciones = [
      _SeccionAcademica(
        titulo: '📊 Rendimiento académico',
        descripcion: 'Notas, boletines e informes de evolución',
        destino: VistaRendimiento(hijoID: hijoID),
      ),
      _SeccionAcademica(
        titulo: '📅 Calendario escolar',
        descripcion: 'Exámenes, entregas y eventos escolares',
        destino: VistaCalendario(hijoID: hijoID),
      ),
      _SeccionAcademica(
        titulo: '📁 Documentación',
        descripcion: 'Matrícula, certificados y autorizaciones',
        destino: VistaDocumentacion(hijoID: hijoID),
      ),
      _SeccionAcademica(
        titulo: '📬 Comunicaciones del centro',
        descripcion: 'Circulares, mensajes y actividades extraescolares',
        destino: VistaComunicaciones(hijoID: hijoID),
      ),
      _SeccionAcademica(
        titulo: '🚫 Ausencias',
        descripcion: 'Justificantes médicos y registros de faltas',
        destino: VistaAusencias(hijoID: hijoID),
      ),
      _SeccionAcademica(
        titulo: '🏫 Actividades escolares',
        descripcion: 'Actividades dentro del horario lectivo',
        destino: VistaActividades(hijoID: hijoID),
      ),
      _SeccionAcademica(
        titulo: '🚌 Excursiones',
        descripcion: 'Autorizaciones y seguimiento de salidas escolares',
        destino: VistaExcursiones(hijoID: hijoID),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Académico de $nombreHijo')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: secciones.length,
        itemBuilder: (_, index) => secciones[index],
      ),
    );
  }
}

class _SeccionAcademica extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final Widget destino;

  const _SeccionAcademica({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        subtitle: Text(
          descripcion,
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => destino)),
      ),
    );
  }
}
