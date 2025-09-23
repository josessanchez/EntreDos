import 'package:entredos/helpers/documento_helper.dart';
import 'package:flutter/material.dart';

class TarjetaDocumento extends StatelessWidget {
  final String titulo;
  final String fecha;
  final String? urlArchivo;
  final String? nombreArchivo;
  final String? observaciones;
  final String docId;
  final String uidActual;
  final String uidPropietario;
  final String coleccion;
  final bool puedeEditar;
  final VoidCallback onEliminado;

  const TarjetaDocumento({
    super.key,
    required this.titulo,
    required this.fecha,
    this.urlArchivo,
    this.nombreArchivo,
    this.observaciones,
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
                    titulo,
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
                  'Ver documento',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                onPressed: () =>
                    DocumentoHelper.ver(context, nombreArchivo!, urlArchivo!),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text(
                  'Descargar documento',
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
