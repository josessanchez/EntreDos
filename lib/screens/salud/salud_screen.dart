import 'package:entredos/screens/salud/salud_calendario.dart';
import 'package:entredos/screens/salud/salud_documentos.dart';
import 'package:entredos/widgets/dashboard_button.dart';
import 'package:flutter/material.dart';

class SaludScreen extends StatelessWidget {
  final String hijoId;
  final String hijoNombre;

  const SaludScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          'Salud: $hijoNombre',
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
            icon: Icons.folder_shared,
            label: 'Documentos de salud',
            description: 'Cartilla, informes, vacunas y autorizaciones',
            color: Colors.teal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SaludDocumentosScreen(
                    hijoId: hijoId,
                    hijoNombre: hijoNombre,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          DashboardButton(
            icon: Icons.calendar_month,
            label: 'Calendario sanitario',
            description: 'Citas médicas y revisiones por especialidad',
            color: Colors.orange,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SaludCalendarioScreen(
                    hijoId: hijoId,
                    hijoNombre: hijoNombre,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
