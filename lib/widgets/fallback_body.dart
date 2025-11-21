import 'package:flutter/material.dart';
import '../helpers/hijos_fallback.dart';

typedef HijoItemBuilder =
    Widget Function(BuildContext context, Map<String, dynamic> hijo);

class FallbackHijosWidget extends StatefulWidget {
  final HijoItemBuilder? itemBuilder;

  const FallbackHijosWidget({super.key, this.itemBuilder});

  @override
  _FallbackHijosWidgetState createState() => _FallbackHijosWidgetState();
}

class _FallbackHijosWidgetState extends State<FallbackHijosWidget> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchHijosFallback();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error cargando hijos: ${snap.error}'));
        }
        final hijos = snap.data ?? [];
        if (hijos.isEmpty) {
          return const Center(child: Text('No hay hijos (fallback)'));
        }

        return ListView.builder(
          itemCount: hijos.length,
          itemBuilder: (context, index) {
            final h = hijos[index];
            if (widget.itemBuilder != null) {
              return widget.itemBuilder!(context, h);
            }
            final nombre = h['nombre'] ?? h['name'] ?? 'Hijo';
            final id = h['id'] ?? h['uid'] ?? h['documentId'] ?? '';
            return ListTile(
              title: Text(nombre.toString()),
              subtitle: id != '' ? Text(id.toString()) : null,
            );
          },
        );
      },
    );
  }
}
