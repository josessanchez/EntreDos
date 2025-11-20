import 'package:entredos/models/modelo_pago.dart';
import 'package:intl/intl.dart';

class PagoHelper {
  /// Calcula el porcentaje cubierto del pago
  static double calcularPorcentajeCubierto(ModeloPago pago) {
    if (pago.importeTotal == 0) return 0;
    final porcentaje = (pago.cantidadPagada / pago.importeTotal) * 100;
    return porcentaje.clamp(0, 100);
  }

  /// Devuelve un color asociado al estado del pago
  static int colorEstado(EstadoPago estado) {
    switch (estado) {
      case EstadoPago.pendiente:
        return 0xFFB71C1C; // rojo oscuro
      case EstadoPago.parcial:
        return 0xFFF57F17; // naranja
      case EstadoPago.completado:
        return 0xFF2E7D32; // verde
      case EstadoPago.enDisputa:
        return 0xFF6A1B9A; // púrpura
      case EstadoPago.validacionPendiente:
        return 0xFF0288D1; // azul
    }
  }

  /// Determina el estado del pago según el importe y validación
  static EstadoPago determinarEstado(
    ModeloPago pago, {
    bool validadoPorAmbos = true,
  }) {
    final porcentaje = calcularPorcentajeCubierto(pago);

    if (!validadoPorAmbos && pago.esCompartido) {
      return EstadoPago.validacionPendiente;
    }

    if (porcentaje == 0) return EstadoPago.pendiente;
    if (porcentaje < 100) return EstadoPago.parcial;
    return EstadoPago.completado;
  }

  /// Verifica si el pago compartido está completo según el porcentaje acordado
  static bool estaCompleto(ModeloPago pago) {
    final requerido = pago.importeTotal * (pago.porcentajeResponsable / 100);
    return pago.cantidadPagada >= requerido;
  }

  /// Devuelve una etiqueta visual para el estado del pago
  static String etiquetaEstado(EstadoPago estado) {
    switch (estado) {
      case EstadoPago.pendiente:
        return 'Pendiente';
      case EstadoPago.parcial:
        return 'Parcial';
      case EstadoPago.completado:
        return 'Completado';
      case EstadoPago.enDisputa:
        return 'En disputa';
      case EstadoPago.validacionPendiente:
        return 'Validación pendiente';
    }
  }

  /// Formatea la fecha límite en formato legible
  static String? formatearFechaLimite(DateTime? fecha) {
    if (fecha == null) return null;
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
}
