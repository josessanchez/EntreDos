import 'package:entredos/components/grafica_evolucion_academica_por_asignatura.dart';
import 'package:entredos/models/nota_academica.dart';
import 'package:flutter/material.dart';

class EvolucionAsignaturasTab extends StatelessWidget {
  final Map<String, List<NotaAcademica>> notasPorAsignatura;
  final String trimestreSeleccionado;

  const EvolucionAsignaturasTab({
    super.key,
    required this.notasPorAsignatura,
    required this.trimestreSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    final asignaturasValidas = notasPorAsignatura.entries.where((entry) {
      final filtradas = filtrarPorTrimestre(entry.value);
      return filtradas.length >= 2;
    }).toList();

    if (asignaturasValidas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no hay suficientes notas por asignatura para mostrar evolución.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: asignaturasValidas.length,
      itemBuilder: (_, index) {
        final entry = asignaturasValidas[index];
        final notasFiltradas = filtrarPorTrimestre(entry.value);
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GraficaEvolucionAcademicaPorAsignatura(
            asignatura: entry.key,
            notas: notasFiltradas,
          ),
        );
      },
    );
  }

  List<NotaAcademica> filtrarPorTrimestre(List<NotaAcademica> notas) {
    if (trimestreSeleccionado == 'Todos') return notas;
    return notas.where((nota) {
      final mes = nota.fecha.month;
      switch (trimestreSeleccionado) {
        case '1º Trimestre':
          return mes >= 9 && mes <= 11;
        case '2º Trimestre':
          return mes == 12 || mes == 1 || mes == 2;
        case '3º Trimestre':
          return mes >= 3 && mes <= 6;
        default:
          return true;
      }
    }).toList();
  }
}
