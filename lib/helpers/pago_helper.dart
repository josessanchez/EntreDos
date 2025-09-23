import 'package:entredos/models/config_pagos.dart';

String sugerenciasParaPago({
  required String concepto,
  required ConfigPagos config,
}) {
  final conceptoNormalizado = concepto.toLowerCase().trim();

  final esCompartido = config.gastosCompartidos
      .map((e) => e.toLowerCase().trim())
      .any((g) => conceptoNormalizado.contains(g));

  final esIndividual = config.gastosIndividuales
      .map((e) => e.toLowerCase().trim())
      .any((g) => conceptoNormalizado.contains(g));

  String sugerencia = '';

  if (esCompartido) {
    sugerencia += '🔔 Este gasto está marcado como compartido.\n';
    if (!config.divisionFlexible) {
      sugerencia += '💡 Reparto equitativo sugerido entre progenitores.\n';
    } else {
      sugerencia += '📌 Puedes registrar aportaciones personalizadas.\n';
    }
  } else if (esIndividual) {
    sugerencia += '📍 Este gasto figura como individual en la configuración.\n';
  } else {
    sugerencia += '🔍 Este concepto no está clasificado.\n';
    sugerencia += 'Puedes ajustar su categoría en la configuración de pagos.\n';
  }

  if (config.notasPersonalizadas.isNotEmpty) {
    sugerencia += '📝 Nota personalizada: ${config.notasPersonalizadas}';
  }

  return sugerencia.trim();
}