import 'package:entredos/helpers/documento_helper.dart';
import 'package:flutter/material.dart';

class TarjetaEvento extends StatelessWidget {
  final String titulo;
  final String fecha;
  final String descripcion;
  final String? tipo; // cultural, refuerzo, etc.
  final String? nombreArchivo;
  final String? urlArchivo;
  final String docId;
  final String uidActual;
  final String uidPropietario;
  final String coleccion;
  final bool puedeEditar;
  final VoidCallback onEliminado;

  const TarjetaEvento({
    super.key,
    required this.titulo,
    required this.fecha,
    required this.descripcion,
    this.tipo,
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
            if (tipo != null && tipo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🗂 Tipo: $tipo',
                  style: const TextStyle(fontFamily: 'Montserrat'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '📝 $descripcion',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
            if (urlArchivo != null && nombreArchivo != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text(
                  'Ver archivo adjunto',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                onPressed: () =>
                    DocumentoHelper.ver(context, nombreArchivo!, urlArchivo!),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text(
                  'Descargar archivo',
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
