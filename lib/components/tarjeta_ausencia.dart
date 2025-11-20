import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/helpers/ausencia_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TarjetaAusencia extends StatefulWidget {
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String tipo; // nuevo campo para el valor del desplegable
  final String motivo; // descripción libre
  final String observaciones;
  final String? nombreArchivo;
  final String? urlArchivo;
  final String docId;
  final String uidActual;
  final String uidPropietario;
  final String coleccion;
  final bool puedeEditar;
  final VoidCallback onEliminado;
  final bool justificada;

  const TarjetaAusencia({
    super.key,
    required this.fechaInicio,
    this.fechaFin,
    required this.tipo,
    required this.motivo,
    required this.observaciones,
    this.nombreArchivo,
    this.urlArchivo,
    required this.docId,
    required this.uidActual,
    required this.uidPropietario,
    required this.coleccion,
    required this.puedeEditar,
    required this.onEliminado,
    required this.justificada,
  });

  @override
  State<TarjetaAusencia> createState() => _TarjetaAusenciaState();
}

class _TarjetaAusenciaState extends State<TarjetaAusencia> {
  bool desplegado = false;

  String get estadoJustificacion =>
      widget.justificada ? 'Justificada' : 'Injustificada';

  String get iconoTipo {
    switch (widget.tipo.toLowerCase()) {
      case 'médica':
        return '🏥';
      case 'viaje':
        return '✈️';
      default:
        return '📌';
    }
  }

  String get nombreProgenitor {
    return widget.uidActual == widget.uidPropietario
        ? (FirebaseAuth.instance.currentUser?.displayName ?? 'Progenitor')
        : 'Otro progenitor';
  }

  String get rangoFechas {
    final formatter = DateFormat('d MMM yyyy • HH:mm');
    final inicio = formatter.format(widget.fechaInicio);
    if (widget.fechaFin == null || widget.fechaFin == widget.fechaInicio) {
      return inicio;
    }
    final fin = formatter.format(widget.fechaFin!);
    return '$inicio – $fin';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text('Ausencia: $rangoFechas'),
            subtitle: Text(
              '$estadoJustificacion • Motivo: $iconoTipo ${widget.tipo}',
            ),
            trailing: widget.nombreArchivo != null
                ? const Icon(Icons.attach_file)
                : null,
            onTap: () => setState(() => desplegado = !desplegado),
          ),
          if (desplegado)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progenitor responsable: $nombreProgenitor'),
                  const SizedBox(height: 6),
                  Text('Descripción del motivo: ${widget.motivo}'),
                  const SizedBox(height: 6),
                  if (widget.observaciones.isNotEmpty)
                    Text('Observaciones: ${widget.observaciones}'),
                  const SizedBox(height: 6),
                  if (widget.nombreArchivo != null && widget.urlArchivo != null)
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(widget.nombreArchivo!),
                      onPressed: () {
                        // Abrir el archivo en navegador externo
                        // Puedes usar url_launcher si lo tienes integrado
                      },
                    ),
                  if (widget.puedeEditar)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          onPressed: () {
                            AusenciaHelper.editar(
                              context: context,
                              ausenciaID: widget.docId,
                              datos: {
                                'motivo': widget.motivo,
                                'observaciones': widget.observaciones,
                                'tipo': widget.tipo,
                                'justificada': widget.justificada,
                                'fechaInicio': widget.fechaInicio,
                                'nombreArchivo': widget.nombreArchivo,
                                'urlArchivo': widget.urlArchivo,
                              },
                              onGuardado: widget.onEliminado,
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                          onPressed: () async {
                            final confirmado = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('¿Eliminar ausencia?'),
                                content: const Text(
                                  'Esta acción no se puede deshacer.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmado == true) {
                              await FirebaseFirestore.instance
                                  .collection(widget.coleccion)
                                  .doc(widget.docId)
                                  .delete();

                              widget.onEliminado();
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
