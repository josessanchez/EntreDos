import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:entredos/screens/identificacion_upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entredos/widgets/fallback_body.dart';

class IdentificacionListScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const IdentificacionListScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _IdentificacionListScreenState createState() =>
      _IdentificacionListScreenState();
}

class _IdentificacionListScreenState extends State<IdentificacionListScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Cargando sesión...')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Identificación',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('identificacion')
            .where('hijoID', isEqualTo: widget.hijoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final err = snapshot.error;
            if (err is FirebaseException && err.code == 'permission-denied') {
              return const FallbackHijosWidget();
            }
            return const Center(
              child: Text(
                "❌ Error cargando documentos",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "📭 No hay documentos de identidad subidos",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _buildDocumentoCard(doc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  IdentificacionUploadScreen(hijoId: widget.hijoId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Subir documento'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDocumentoCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nombre = data['nombre'] ?? 'Documento';
    final url = data['url'] ?? '';
    final docId = doc.id;
    final titulo = data['tipo'] ?? 'Sin tipo';
    final tipo = data['tipo'] ?? 'Sin tipo';
    final fecha = (data['fechaSubida'] as Timestamp?)?.toDate();
    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(fecha)
        : 'Sin fecha';
    final usuario = data['usuarioNombre'] ?? 'Sin autor';
    final uidPropietario = data['usuarioID'] ?? '';

    final iconoTipo = _iconoPorTipo(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconoTipo, color: Colors.white70, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Subido por $usuario • $fechaTexto',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.greenAccent,
                ),
                tooltip: 'Ver documento',
                onPressed: () => DocumentoHelper.ver(context, nombre, url),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.amberAccent),
                tooltip: 'Descargar',
                onPressed: () =>
                    DocumentoHelper.descargar(context, nombre, url),
              ),
              if (uidPropietario == FirebaseAuth.instance.currentUser?.uid)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar',
                  onPressed: () => DocumentoHelper.delete(
                    context,
                    docId,
                    nombre,
                    url,
                    FirebaseAuth.instance.currentUser!.uid,
                    uidPropietario,
                    'identificacion',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'dni':
        return Icons.credit_card;
      case 'pasaporte':
        return Icons.public;
      case 'tarjeta de residente':
        return Icons.home_work;
      case 'nie':
        return Icons.perm_identity;
      default:
        return Icons.badge;
    }
  }
}
