import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SaludHelper {
  static Future<void> delete(
    BuildContext context,
    String docId,
    String nombre,
    String url,
    String uidActual,
    String uidPropietario,
    String coleccion,
  ) async {
    if (uidActual != uidPropietario) {
      _mostrarError(context, 'No tienes permiso para eliminar este documento');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final dialogContext = context;
    final confirmacion = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Seguro que quieres eliminar "$nombre"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Eliminar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    try {
      await FirebaseFirestore.instance
          .collection(coleccion)
          .doc(docId)
          .delete();
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ Documento eliminado')),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('❌ Error al eliminar el documento')),
      );
    }
  }

  static Future<void> descargar(
    BuildContext context,
    String nombre,
    String url,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('❌ No se pudo descargar el documento')),
      );
    }
  }

  static Future<void> ver(
    BuildContext context,
    String nombre,
    String url,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('❌ No se pudo abrir el documento')),
      );
    }
  }

  static void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('❌ $mensaje')));
  }
}
