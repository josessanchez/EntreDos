import 'package:entredos/helpers/pago_helper.dart';
import 'package:entredos/models/modelo_pago.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TarjetaPago extends StatelessWidget {
  final ModeloPago pago;

  const TarjetaPago({super.key, required this.pago});

  @override
  Widget build(BuildContext context) {
    final porcentaje = PagoHelper.calcularPorcentajeCubierto(pago);
    final estado = PagoHelper.etiquetaEstado(pago.estado);
    final color = Color(PagoHelper.colorEstado(pago.estado));
    final fecha = DateFormat('dd/MM/yyyy').format(pago.fechaRegistro);
    final fechaLimite = PagoHelper.formatearFechaLimite(pago.fechaLimite);

    return Card(
      color: color.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pago.tipoGasto,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estado: $estado • ${porcentaje.toStringAsFixed(0)}% cubierto',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            Text(
              'Importe total: ${pago.importeTotal.toStringAsFixed(2)} €',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            Text(
              'Pagado por ti: ${pago.cantidadPagada.toStringAsFixed(2)} €',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            if (pago.esCompartido)
              Text(
                'Porcentaje que te corresponde: ${pago.porcentajeResponsable.toInt()}%',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            const SizedBox(height: 8),
            Text(
              'Responsable: ${pago.responsableNombre}',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            Text(
              'Registrado el: $fecha',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            if (fechaLimite != null)
              Text(
                'Fecha límite: $fechaLimite',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            if (pago.comentario != null && pago.comentario!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Comentario: ${pago.comentario}',
                  style: const TextStyle(fontFamily: 'Montserrat'),
                ),
              ),
            if (pago.urlJustificante != null &&
                pago.urlJustificante!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pago.nombreJustificante ?? 'Justificante adjunto',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          decoration: TextDecoration.underline,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () {
                        // Abrir justificante en navegador
                        // Puedes usar url_launcher aquí
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
