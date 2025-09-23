import 'package:entredos/helpers/documento_helper.dart';
import 'package:flutter/material.dart';

class TarjetaAusencia extends StatelessWidget {
  final String fecha;
  final String motivo;
  final String tipo;
  final String? observaciones;
  final String? nombreArchivo;
  final String? urlArchivo;
  final String docId;
  final String uidActual;
  final String uidPropietario;
  final String coleccion;
  final bool puedeEditar;
  final VoidCallback onEliminado;

  const TarjetaAusencia({
    super.key,
    required this.fecha,
    required this.motivo,
    required this.tipo,
    this.observaciones,
    this.nombreArchivo,
    this.urlArchivo,
    required this.docId,
    required this.uidActual,
    required this.uidPropietario,
    required this.coleccion,
    required this.puedeEditar,
    required this.onEliminado,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    motivo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                Text(
                  fecha,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                  ),
                ),
                if (puedeEditar)
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'borrar') {
                        await DocumentoHelper.delete(
                          context,
                          docId,
                          nombreArchivo ?? 'documento.pdf',
                          urlArchivo,
                          uidActual,
                          uidPropietario,
                          coleccion,
                        );
                        onEliminado();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'borrar', child: Text('Eliminar')),
                    ],
                  ),
              ],
            ),
            Text(
              '📂 Tipo: $tipo',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            if (observaciones != null && observaciones!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '💬 $observaciones',
                  style: const TextStyle(fontFamily: 'Montserrat'),
                ),
              ),
            if (urlArchivo != null && nombreArchivo != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text(
                  'Ver justificante',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                onPressed: () =>
                    DocumentoHelper.ver(context, nombreArchivo!, urlArchivo!),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text(
                  'Descargar justificante',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                onPressed: () => DocumentoHelper.descargar(
                  context,
                  nombreArchivo!,
                  urlArchivo!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
