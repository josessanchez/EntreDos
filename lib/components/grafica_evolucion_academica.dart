import 'dart:math';

import 'package:entredos/models/nota_academica.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficaEvolucionAcademica extends StatelessWidget {
  final List<NotaAcademica> notas;

  const GraficaEvolucionAcademica({super.key, required this.notas});

  @override
  Widget build(BuildContext context) {
    if (notas.length < 2) {
      return const SizedBox.shrink();
    }

    final ordenadas = List<NotaAcademica>.from(notas)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    final spots = ordenadas
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.valor))
        .toList();

    final valoresY = spots.map((s) => s.y).toList();
    final minY = valoresY.reduce(min).floorToDouble();
    final maxY = valoresY.reduce(max).ceilToDouble();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 1, // pasos de 1 en el eje Y
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(), // solo enteros
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Evolución académica',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
