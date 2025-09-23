import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestScreen extends StatefulWidget {
  @override
  _FirestoreTestScreenState createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  String resultado = '⏳ Probar conexión a Firestore...';

  Future<void> escribirYLeerFirestore() async {
    try {
      await FirebaseFirestore.instance.collection("prueba").add({
        'mensaje': 'Hola desde EntreDos',
        'fecha': Timestamp.now(),
      });

      final snapshot =
          await FirebaseFirestore.instance.collection("prueba").get();

      print("📦 Documentos encontrados: ${snapshot.docs.length}");

      setState(() {
        resultado =
            '✅ Conexión correcta.\nTotal documentos: ${snapshot.docs.length}\nÚltimo: ${snapshot.docs.last['mensaje']}';
      });
    } catch (e) {
      print("❌ Error al acceder a Firestore: $e");
      setState(() {
        resultado = '❌ Error al acceder a Firestore: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    escribirYLeerFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prueba Firestore')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            resultado,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}