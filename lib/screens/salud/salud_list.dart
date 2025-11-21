import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/helpers/salud/salud_helper.dart';
import 'package:entredos/screens/salud/salud_upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entredos/widgets/fallback_body.dart';

class SaludListScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const SaludListScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _SaludListScreenState createState() => _SaludListScreenState();
}

class _SaludListScreenState extends State<SaludListScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Cargando sesión...')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          'Salud: ${widget.hijoNombre}',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SaludUploadScreen(hijoId: widget.hijoId),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('salud')
                  .where('hijoID', isEqualTo: widget.hijoId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final err = snapshot.error;
                  if (err is FirebaseException &&
                      err.code == 'permission-denied') {
                    return const FallbackHijosWidget();
                  }

                  return const Center(
                    child: Text(
                      "❌ Error cargando datos de salud",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "📭 No hay información médica registrada",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final documentos = docs
                    .where((d) => d['tipoEntrada'] == 'documento')
                    .toList();
                final citas = docs
                    .where((d) => d['tipoEntrada'] == 'cita')
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (documentos.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '📁 Documentos médicos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ...documentos.map(_buildDocumentoCard),
                    if (citas.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '📅 Citas médicas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ...citas.map(_buildCitaCard),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitaCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final tipo = data['tipo'] ?? 'Cita';
    final especialidad = data['especialidad'] ?? 'General';
    final fechaHora = (data['fechaHora'] as Timestamp?)?.toDate();
    final fechaTexto = fechaHora != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(fechaHora)
        : 'Sin fecha';
    final responsable = data['responsableNombre'] ?? 'Sin responsable';
    final ubicacion = data['ubicacion'] ?? '';
    final notas = data['notas'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF34495E),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tipo • $especialidad',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fecha: $fechaTexto',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Responsable: $responsable',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              color: Colors.white70,
            ),
          ),
          if (ubicacion.isNotEmpty) const SizedBox(height: 2),
          if (ubicacion.isNotEmpty)
            Text(
              'Ubicación: $ubicacion',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Montserrat',
                color: Colors.white70,
              ),
            ),
          if (notas.isNotEmpty) const SizedBox(height: 2),
          if (notas.isNotEmpty)
            Text(
              'Notas: $notas',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Montserrat',
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentoCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final tipo = data['tipoDocumento'] ?? 'Documento';
    final titulo = data['tituloUsuario'] ?? tipo;
    final url = data['url'] ?? '';
    final nombre = data['nombre'] ?? '';
    final fecha = (data['fechaSubida'] as Timestamp?)?.toDate();
    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy - HH:mm').format(fecha)
        : 'Sin fecha';
    final usuario = data['usuarioNombre'] ?? 'Sin autor';
    final uidPropietario = data['usuarioID'] ?? '';
    final docId = doc.id;

    final icono = _iconoPorTipo(tipo);

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
          Icon(icono, color: Colors.white70, size: 32),
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
                const SizedBox(height: 4),
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
                onPressed: () => SaludHelper.ver(context, titulo, url),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.amberAccent),
                tooltip: 'Descargar',
                onPressed: () => SaludHelper.descargar(context, titulo, url),
              ),
              if (uidPropietario == FirebaseAuth.instance.currentUser?.uid)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar',
                  onPressed: () => SaludHelper.delete(
                    context,
                    docId,
                    nombre,
                    url,
                    FirebaseAuth.instance.currentUser!.uid,
                    uidPropietario,
                    'salud',
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
      case 'cartilla':
        return Icons.medical_services;
      case 'informe':
        return Icons.description;
      case 'vacuna':
        return Icons.vaccines;
      case 'autorización':
        return Icons.assignment_turned_in;
      default:
        return Icons.folder_shared;
    }
  }
}
