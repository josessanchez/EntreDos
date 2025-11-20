import 'package:entredos/models/modelo_disputa.dart';
import 'package:entredos/models/modelo_pago.dart';
import 'package:flutter/material.dart';

class ConfigPagos {
  /// Categorías disponibles
  static const List<String> categorias = [
    'Colegio',
    'Actividades',
    'Uniforme',
    'Pensión de alimentos',
    'Visita médica',
    'Excursión',
    'Otro',
  ];

  /// Colores por categoría
  static const Map<String, Color> coloresPorCategoria = {
    'Colegio': Colors.indigo,
    'Actividades': Colors.deepPurple,
    'Uniforme': Colors.teal,
    'Pensión de alimentos': Colors.orange,
    'Visita médica': Colors.redAccent,
    'Excursión': Colors.blueGrey,
    'Otro': Colors.grey,
  };

  /// Etiquetas legibles para estados de pago
  static const Map<EstadoPago, String> etiquetasEstadoPago = {
    EstadoPago.pendiente: 'Pendiente',
    EstadoPago.parcial: 'Parcial',
    EstadoPago.completado: 'Completado',
    EstadoPago.enDisputa: 'En disputa',
    EstadoPago.validacionPendiente: 'Validación pendiente',
  };

  /// Etiquetas legibles para estados de disputa
  static const Map<EstadoDisputa, String> etiquetasEstadoDisputa = {
    EstadoDisputa.pendiente: 'Pendiente',
    EstadoDisputa.aceptada: 'Aceptada',
    EstadoDisputa.rechazada: 'Rechazada',
    EstadoDisputa.resuelta: 'Resuelta',
  };

  /// Devuelve el color asociado a una categoría
  static Color colorCategoria(String categoria) {
    return coloresPorCategoria[categoria] ?? Colors.grey;
  }

  /// Devuelve la etiqueta legible de un estado de disputa
  static String etiquetaEstadoDisputa(EstadoDisputa estado) {
    return etiquetasEstadoDisputa[estado] ?? 'Desconocido';
  }

  /// Devuelve la etiqueta legible de un estado de pago
  static String etiquetaEstadoPago(EstadoPago estado) {
    return etiquetasEstadoPago[estado] ?? 'Desconocido';
  }
}
