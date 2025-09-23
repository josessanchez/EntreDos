import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/models/config_pagos.dart';

class EditarConfigPagos extends StatefulWidget {
  final String hijoID;
  const EditarConfigPagos({required this.hijoID});

  @override
  State<EditarConfigPagos> createState() => _EditarConfigPagosState();
}

class _EditarConfigPagosState extends State<EditarConfigPagos> {
  final notasCtrl = TextEditingController();
  final gastosCompartidosCtrl = TextEditingController();
  final gastosIndividualesCtrl = TextEditingController();
  String tipoCustodia = 'Compartida';
  bool divisionFlexible = true;

  @override
  void initState() {
    super.initState();
    cargarConfig();
  }

  Future<void> cargarConfig() async {
    final doc = await FirebaseFirestore.instance
        .collection('hijos')
        .doc(widget.hijoID)
        .collection('configuracion')
        .doc('pagos')
        .get();

    if (doc.exists) {
      final config = ConfigPagos.fromSnapshot(doc);
      setState(() {
        tipoCustodia = config.tipoCustodia;
        divisionFlexible = config.divisionFlexible;
        notasCtrl.text = config.notasPersonalizadas;
        gastosCompartidosCtrl.text = config.gastosCompartidos.join(', ');
        gastosIndividualesCtrl.text = config.gastosIndividuales.join(', ');
      });
    }
  }

  Future<void> guardarConfig() async {
    final data = ConfigPagos(
      tipoCustodia: tipoCustodia,
      divisionFlexible: divisionFlexible,
      notasPersonalizadas: notasCtrl.text.trim(),
      gastosCompartidos: gastosCompartidosCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      gastosIndividuales: gastosIndividualesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    await FirebaseFirestore.instance
        .collection('hijos')
        .doc(widget.hijoID)
        .collection('configuracion')
        .doc('pagos')
        .set(data.toMap());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Configuración guardada')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configuración de pagos')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(children: [
            DropdownButtonFormField<String>(
              value: tipoCustodia,
              items: ['Compartida', 'No compartida', 'Otro']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => tipoCustodia = val ?? 'Compartida'),
              decoration: InputDecoration(labelText: 'Tipo de custodia'),
            ),
            SwitchListTile(
              title: Text('¿Permitir división flexible de gastos?'),
              value: divisionFlexible,
              onChanged: (val) => setState(() => divisionFlexible = val),
            ),
            SizedBox(height: 12),
            TextField(
              controller: gastosCompartidosCtrl,
              decoration: InputDecoration(
                labelText: 'Gastos compartidos (separados por coma)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: gastosIndividualesCtrl,
              decoration: InputDecoration(
                labelText: 'Gastos individuales (separados por coma)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: notasCtrl,
              decoration: InputDecoration(
                labelText: 'Notas personalizadas',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Guardar configuración'),
              onPressed: guardarConfig,
            )
          ]),
        ),
      ),
    );
  }
}