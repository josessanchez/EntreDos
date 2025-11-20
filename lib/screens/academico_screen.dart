import 'package:entredos/widgets/academico/vista_ausencias.dart';
import 'package:entredos/widgets/academico/vista_calendario.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          'Académico: $nombreHijo',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DashboardButton(
            icon: Icons.bar_chart,
            label: 'Rendimiento académico',
            description: 'Notas, boletines e informes de evolución',
            color: Colors.indigo,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VistaRendimiento(hijoID: hijoID),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          DashboardButton(
            icon: Icons.event_note,
            label: 'Calendario escolar',
            description: 'Exámenes, entregas y eventos escolares',
            color: Colors.deepPurple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VistaCalendario(hijoID: hijoID),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          DashboardButton(
            icon: Icons.block,
            label: 'Ausencias',
            description: 'Justificantes médicos y registros de faltas',
            color: Colors.redAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VistaAusencias(hijoID: hijoID),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const DashboardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 18),
        ],
      ),
    );
  }
}
