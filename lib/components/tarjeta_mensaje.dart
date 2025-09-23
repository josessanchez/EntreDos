import 'package:entredos/helpers/documento_helper.dart';
import 'package:flutter/material.dart';

class TarjetaMensaje extends StatelessWidget {
  final String titulo;
  final String fecha;
  final String contenido;
  final String tipo; // circular, tutor, actividad
  final String docId;
  final String uidActual;
  final String uidPropietario;
  final String coleccion;
  final bool puedeEditar;
  final VoidCallback onEliminado;

  const TarjetaMensaje({
    super.key,
    required this.titulo,
    required this.fecha,
    required this.contenido,
    required this.tipo,
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
                          titulo,
                          null,
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
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '📂 Tipo: $tipo',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '💬 $contenido',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
