import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/formulario_hijo.dart';

class HijosScreen extends StatefulWidget {
  @override
  _HijosScreenState createState() => _HijosScreenState();
}

class _HijosScreenState extends State<HijosScreen> {
  late final User user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
  }

  void mostrarDialogoCodigo(String codigo) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1B263B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '👶 ¡Tu hijo/a ha sido creado!',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparte este código con el otro progenitor:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  codigo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Este código les permitirá conectarse al mismo hijo/a en la app.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Copiar código',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontFamily: 'Montserrat',
                  ),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: codigo));
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('📋 Código copiado al portapapeles'),
                      backgroundColor: Color(0xFF0D1B2A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              TextButton(
                child: const Text(
                  'Compartir código',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontFamily: 'Montserrat',
                  ),
                ),
                onPressed: () {
                  Share.share('👶 Código para conectarte a tu hijo/a: $codigo');
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          );
        },
      );
    });
  }

  void mostrarDialogoUnirmeAHijo() {
    String codigo = '';
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '🔗 Conectarme a hijo/a',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
            decoration: InputDecoration(
              hintText: 'Introduce el código de invitación',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0D1B2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.pinkAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.pinkAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
            onChanged: (v) => codigo = v.trim(),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontFamily: 'Montserrat',
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                final query = await FirebaseFirestore.instance
                    .collection('hijos')
                    .where('codigoInvitacion', isEqualTo: codigo)
                    .get();

                if (query.docs.isEmpty) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Código no encontrado'),
                      backgroundColor: Color(0xFF0D1B2A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                final doc = query.docs.first;
                final datos = doc.data();
                final progenitores = List<String>.from(datos['progenitores'] ?? []);

                if (!progenitores.contains(user.uid)) {
                  progenitores.add(user.uid);
                  await doc.reference.update({'progenitores': progenitores});
                }

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('✅ Conectado a ${datos['nombre']}'),
                    backgroundColor: Color(0xFF0D1B2A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

    void mostrarBottomSheetDetalle(DocumentSnapshot hijoDoc) {
    final data = hijoDoc.data() as Map<String, dynamic>;
    final fecha = (data['fechaNacimiento'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B263B),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['fotoUrl'] != '')
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(data['fotoUrl']),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                '👶 ${data['nombre']} ${data['apellidos']}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🗓️ Fecha de nacimiento: ${fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : 'Sin especificar'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🆔 DNI: ${data['dni']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🏫 Colegio: ${data['colegio']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '📝 Observaciones: ${data['observaciones']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                '🔐 Código de invitación: ${data['codigoInvitacion']}',
                style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Row(
                children: [
                  TextButton(
                    child: const Text(
                      'Copiar',
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: data['codigoInvitacion']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📋 Código copiado'),
                          backgroundColor: Color(0xFF0D1B2A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  TextButton(
                    child: const Text(
                      'Compartir',
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    onPressed: () {
                      Share.share('👶 Código: ${data['codigoInvitacion']}');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void editarHijo(DocumentSnapshot hijoDoc) async {
    final codigo = await showDialog<String>(
      context: context,
      builder: (_) => FormularioHijo(hijoExistente: hijoDoc),
    );

    if (codigo != null && mounted) setState(() {});
  }

  void eliminarHijo(DocumentSnapshot hijoDoc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🗑️ Eliminar hijo/a',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar a este hijo/a? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white70,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.pinkAccent,
                fontFamily: 'Montserrat',
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              await hijoDoc.reference.delete();
              if (mounted) setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Hijo/a eliminado correctamente'),
                  backgroundColor: Color(0xFF0D1B2A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0D1B2A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1B263B),
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'Tus hijos',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text(
              'Añadir hijo/a',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final codigo = await showDialog<String>(
                context: context,
                builder: (_) => FormularioHijo(),
              );

              if (codigo != null) {
                mostrarDialogoCodigo(codigo);
                if (mounted) setState(() {});
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.link),
            label: const Text(
              'Conectarme a hijo/a con código',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: mostrarDialogoUnirmeAHijo,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('hijos')
                  .orderBy('fechaCreacion', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final progenitores = List<String>.from(data['progenitores'] ?? []);
                  return progenitores.contains(user.uid);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '🚸 No tienes hijos vinculados aún',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final nacimiento = (data['fechaNacimiento'] as Timestamp?)?.toDate();
                    final edad = nacimiento != null
                        ? DateTime.now().year - nacimiento.year -
                            (DateTime.now().month < nacimiento.month ||
                                    (DateTime.now().month == nacimiento.month &&
                                        DateTime.now().day < nacimiento.day)
                                ? 1
                                : 0)
                        : null;
                    final edadTexto = edad != null ? '$edad años' : 'Edad desconocida';

                    return Card(
                      color: const Color(0xFF1B263B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        onTap: () => mostrarBottomSheetDetalle(doc),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: data['fotoUrl'] != ''
                              ? NetworkImage(data['fotoUrl'])
                              : null,
                          backgroundColor: Colors.grey[800],
                          child: data['fotoUrl'] == ''
                              ? const Icon(Icons.child_care, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          '${data['nombre']} ${data['apellidos']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          edadTexto,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.greenAccent),
                              tooltip: 'Ver detalles',
                              onPressed: () => mostrarBottomSheetDetalle(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                              tooltip: 'Editar hijo/a',
                              onPressed: () => editarHijo(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              tooltip: 'Eliminar hijo/a',
                              onPressed: () => eliminarHijo(doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}