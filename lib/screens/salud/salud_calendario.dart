import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:entredos/screens/salud/salud_cita_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:entredos/widgets/fallback_body.dart';

class SaludCalendarioScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const SaludCalendarioScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  SaludCalendarioScreenState createState() => SaludCalendarioScreenState();
}

class SaludCalendarioScreenState extends State<SaludCalendarioScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Cargando sesión...')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          'Calendario sanitario: ${widget.hijoNombre}',
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
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
                      builder: (context) => SaludCitaFormScreen(
                        hijoId: widget.hijoId,
                        hijoNombre: widget.hijoNombre,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('salud')
                    .where('hijoID', isEqualTo: widget.hijoId)
                    .where('tipoEntrada', isEqualTo: 'cita')
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
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '❌ Error cargando citas',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final citas = snapshot.data!.docs;
                  if (citas.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '📭 No hay citas registradas',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: citas.map(_buildCitaCard).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Form actions were moved to `SaludCitaFormScreen`.

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
    final docId = doc.id;
    final uidPropietario = data['responsableID'] ?? '';
    final urlDocumento = data['urlDocumento'] ?? '';
    final tituloDocumento = data['tituloDocumento'] ?? '$tipo • $especialidad';
    final user = FirebaseAuth.instance.currentUser;

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
          const SizedBox(height: 8),
          Row(
            children: [
              if (urlDocumento.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.greenAccent,
                  ),
                  tooltip: 'Ver justificante',
                  onPressed: () => DocumentoHelper.ver(
                    context,
                    tituloDocumento,
                    urlDocumento,
                  ),
                ),
              if (urlDocumento.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.amberAccent),
                  tooltip: 'Descargar justificante',
                  onPressed: () => DocumentoHelper.descargar(
                    context,
                    tituloDocumento,
                    urlDocumento,
                  ),
                ),
              if (user?.uid == uidPropietario)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar cita',
                  onPressed: () => DocumentoHelper.delete(
                    context,
                    docId,
                    '$tipo • $especialidad',
                    urlDocumento,
                    user!.uid,
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

  // No local form helpers here — form was moved to `salud_cita_form.dart`.
}
