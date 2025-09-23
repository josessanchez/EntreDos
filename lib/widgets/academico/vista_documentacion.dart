import 'package:entredos/components/boton_anadir.dart';
import 'package:entredos/components/tarjeta_documento.dart';
import 'package:entredos/helpers/documento_academico_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VistaDocumentacion extends StatefulWidget {
  final String hijoID;

  const VistaDocumentacion({super.key, required this.hijoID});

  @override
  State<VistaDocumentacion> createState() => _VistaDocumentacionState();
}

class _VistaDocumentacionState extends State<VistaDocumentacion> {
  List<Map<String, dynamic>> documentos = [];
  bool cargando = true;

  Future<void> anadirDocumentoAsync() async {
    await DocumentoAcademicoHelper.subir(
      context: context,
      hijoID: widget.hijoID,
      onGuardado: cargarDocumentos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Documentación escolar')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : documentos.isEmpty
          ? const Center(
              child: Text(
                'No hay documentos escolares aún.',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documentos.length,
              itemBuilder: (_, index) {
                final doc = documentos[index];
                final esPropio = doc['usuarioID'] == uidActual;

                return TarjetaDocumento(
                  titulo: doc['titulo'],
                  fecha: doc['fecha'],
                  urlArchivo: doc['urlArchivo'],
                  nombreArchivo: doc['nombreArchivo'],
                  observaciones: doc['observaciones'],
                  docId: doc['id'],
                  uidActual: uidActual,
                  uidPropietario: doc['usuarioID'],
                  coleccion: 'documentacion',
                  puedeEditar: esPropio,
                  onEliminado: cargarDocumentos,
                );
              },
            ),
      floatingActionButton: BotonAnadir(
        onPressed: anadirDocumentoAsync,
        tooltip: 'Añadir documento escolar',
      ),
    );
  }

  Future<void> cargarDocumentos() async {
    final resultado = await DocumentoAcademicoHelper.obtenerPorHijo(
      widget.hijoID,
    );

    // Diagnóstico: imprime cada documento para verificar campos
    for (var doc in resultado) {
      print('📄 ${doc['titulo']} - ${doc['hijoID']} - ${doc['usuarioID']}');
    }

    setState(() {
      documentos = resultado;
      cargando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    cargarDocumentos();
  }
}
