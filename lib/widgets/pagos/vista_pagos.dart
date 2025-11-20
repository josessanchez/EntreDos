import 'package:entredos/widgets/pagos/vista_disputas.dart';
import 'package:entredos/widgets/pagos/vista_historial.dart';
import 'package:entredos/widgets/pagos/vista_mis_pagos.dart';
import 'package:entredos/widgets/pagos/vista_pagos_activos.dart';
import 'package:flutter/material.dart';

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

class VistaPagos extends StatelessWidget {
  final String hijoID;

  const VistaPagos({super.key, required this.hijoID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Pagos',
          style: TextStyle(
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
            icon: Icons.receipt_long,
            label: 'Pagos activos',
            description: 'Pagos pendientes, completados y en disputa',
            color: Colors.teal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VistaPagosActivos(hijoID: hijoID),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          DashboardButton(
            icon: Icons.calendar_view_month,
            label: 'Historial mensual',
            description: 'Resumen por mes y totales por categoría',
            color: Colors.orange,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VistaHistorial(hijoID: hijoID),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          DashboardButton(
            icon: Icons.gavel,
            label: 'Pagos en disputa',
            description: 'Pagos que requieren acuerdo entre progenitores',
            color: Colors.redAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VistaDisputas(hijoID: hijoID),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          DashboardButton(
            icon: Icons.person,
            label: 'Mis pagos',
            description: 'Pagos realizados por ti y justificantes subidos',
            color: Colors.indigo,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VistaMisPagos(hijoID: hijoID),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
