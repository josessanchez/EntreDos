import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// removed unused imports: flutter_downloader, open_filex, visor_pdf_screen
import 'package:diacritic/diacritic.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:entredos/widgets/fallback_body.dart';
import 'package:entredos/utils/app_logger.dart';

class DocumentListScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const DocumentListScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _DocumentListScreenState createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  String busquedaTexto = '';
  String? filtroProgenitor;
  DateTime? fechaDesde;
  DateTime? fechaHasta;
  Timer? debounce;
  Map<String, String> mapaProgenitores = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      obtenerProgenitores();
    });
  }

  Future<void> obtenerProgenitores() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('documentos')
        .get();
    final mapa = <String, String>{};

    for (var doc in snapshot.docs) {
      final uid = doc['usuarioID'] as String?;
      final nombre = doc['usuarioNombre'] as String?;
      if (uid != null && nombre != null) {
        mapa[uid] = nombre;
      }
    }

    if (mounted) {
      setState(() {
        mapaProgenitores = mapa;
      });
    }
  }

  String normalizarTexto(String texto) {
    return removeDiacritics(texto.toLowerCase());
  }

  bool coincideFiltro(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return false;

    try {
      final titulo = data['tituloUsuario']?.toString().toLowerCase() ?? '';
      final nombreNormalizado = normalizarTexto(titulo);
      final busquedaNormalizada = normalizarTexto(busquedaTexto);

      final coincideTexto =
          busquedaTexto.length < 3 ||
          nombreNormalizado.contains(busquedaNormalizada);

      final fechaRaw = data['fechaSubida'];
      DateTime? fecha = (fechaRaw is Timestamp) ? fechaRaw.toDate() : null;

      final dentroDeFechas =
          fecha != null &&
          (fechaDesde == null ||
              fecha.isAtSameMomentAs(fechaDesde!) ||
              fecha.isAfter(fechaDesde!)) &&
          (fechaHasta == null ||
              fecha.isBefore(fechaHasta!.add(Duration(days: 1))));

      final usuario = data['usuarioID']?.toString() ?? '';
      final coincideProgenitor =
          filtroProgenitor == null || usuario == filtroProgenitor;

      return coincideTexto && dentroDeFechas && coincideProgenitor;
    } catch (e, st) {
      appLogger.w(
        '⚠️ Error aplicando filtro a documento: ${doc.id} → $e',
        e,
        st,
      );
      return false;
    }
  }

  Widget construirFiltros() {
    return Container(
      color: Color(0xFF1B263B), // Azul menos oscuro
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              labelText: 'Buscar por nombre (min. 3 letras)',
              labelStyle: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.search, color: Colors.white),
            ),
            onChanged: (valor) {
              if (debounce?.isActive ?? false) debounce!.cancel();
              debounce = Timer(Duration(milliseconds: 400), () {
                setState(() => busquedaTexto = valor);
              });
            },
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final dialogContext = context;
                    final seleccion = await showDatePicker(
                      context: dialogContext,
                      initialDate: fechaDesde ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (!mounted) return;
                    if (seleccion != null) {
                      setState(() => fechaDesde = seleccion);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fechaDesde != null
                              ? 'Desde: \n${DateFormat('dd/MM/yyyy').format(fechaDesde!)}'
                              : 'Desde',
                          style: TextStyle(fontFamily: 'Montserrat'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final dialogContext = context;
                    final seleccion = await showDatePicker(
                      context: dialogContext,
                      initialDate: fechaHasta ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (!mounted) return;
                    if (seleccion != null) {
                      setState(() => fechaHasta = seleccion);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          fechaHasta != null
                              ? 'Hasta: \n${DateFormat('dd/MM/yyyy').format(fechaHasta!)}'
                              : 'Hasta',
                          style: TextStyle(fontFamily: 'Montserrat'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.clear),
                  label: Text(
                    'Limpiar fechas',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      fechaDesde = null;
                      fechaHasta = null;
                    });
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: filtroProgenitor,
            dropdownColor: Color(0xFF1B263B),
            style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  'Todos los progenitores',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                  ),
                ),
              ),
              if (mapaProgenitores.isNotEmpty)
                ...mapaProgenitores.entries.map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
            onChanged: (nuevo) => setState(() => filtroProgenitor = nuevo),
            decoration: InputDecoration(
              labelText: 'Filtrar por usuario que lo subió',
              labelStyle: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> mostrarNombreDocumento() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Nombre del documento'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Ejemplo: DNI, Justificante médico, etc.',
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(null),
            ),
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            ),
          ],
        );
      },
    );
    return result;
  }

  void eliminarDocumento(String docId, String nombre, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      await FirebaseFirestore.instance
          .collection('documentos')
          .doc(docId)
          .delete();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '🗑️ "$nombre" eliminado de Firestore y Storage',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '❌ Error al eliminar: $e',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) obtenerProgenitores();
    });
  }

  void mostrarImagenPantallaCompleta(File imagen, String nombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(title: Text(nombre), backgroundColor: Colors.black),
          body: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 4,
            child: Center(child: Image.file(imagen, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  void abrirEnNavegador(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.hasAbsolutePath) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '❌ URL inválida',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
          ),
        ),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ No se pudo abrir el archivo')),
      );
    }
  }

  Widget buildDocumento(DocumentSnapshot doc) {
    final nombre = doc['nombre'] ?? 'Archivo';
    final url = doc['url'] ?? '';
    final docId = doc.id;

    final titulo = doc['tituloUsuario'] ?? doc['nombre'];
    final fecha = (doc['fechaSubida'] as Timestamp?)?.toDate();
    final fechaTexto = fecha != null
        ? DateFormat('dd/MM/yyyy – HH:mm').format(fecha)
        : 'Sin fecha';
    final usuario = doc['usuarioNombre'] ?? 'Sin autor';

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2C3E50), // azul más claro que el fondo base
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 📄 Información del documento
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

          // 🧭 Botones de acción
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.greenAccent,
                ),
                tooltip: 'Abrir documento',
                onPressed: () => DocumentoHelper.ver(context, nombre, url),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.amberAccent),
                tooltip: 'Descargar documento',
                onPressed: () =>
                    DocumentoHelper.descargar(context, nombre, url),
              ),
              if (doc['usuarioID'] == FirebaseAuth.instance.currentUser?.uid)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Eliminar documento',
                  onPressed: () => eliminarDocumento(docId, nombre, url),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> subirDocumento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);

    final resultado = await FilePicker.platform.pickFiles();
    if (resultado == null || resultado.files.single.path == null) return;

    final titulo = await mostrarNombreDocumento();
    if (titulo == null || titulo.trim().isEmpty) return;

    final xfile = resultado.files.single;
    var archivo = File(xfile.path!);
    String nombreOriginal = xfile.name;
    int tamano = archivo.lengthSync();

    if (tamano > 5 * 1024 * 1024) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '❌ El archivo supera 5MB',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontSize: 14,
            ),
          ),
        ),
      );
      return;
    }

    String extension = nombreOriginal.split('.').last.toLowerCase();
    String baseNombre = nombreOriginal.split('.').first;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String nombreFinal;
    if (['jpg', 'jpeg'].contains(extension)) {
      final tempDir = await getTemporaryDirectory();
      final xComprimido = await FlutterImageCompress.compressAndGetFile(
        archivo.path,
        '${tempDir.path}/${baseNombre}_compressed_$timestamp.jpg',
        quality: 60,
      );
      final comprimido = xComprimido != null ? File(xComprimido.path) : null;
      archivo = comprimido ?? archivo;
      extension = 'jpg';
      nombreFinal = comprimido != null
          ? '${baseNombre}_compressed_$timestamp.jpg'
          : '${baseNombre}_$timestamp.$extension';
    } else {
      nombreFinal = '${baseNombre}_$timestamp.$extension';
    }

    String contentType;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'pdf':
        contentType = 'application/pdf';
        break;
      case 'doc':
        contentType = 'application/msword';
        break;
      case 'docx':
        contentType =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        break;
      case 'xls':
        contentType = 'application/vnd.ms-excel';
        break;
      case 'xlsx':
        contentType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        break;
      default:
        contentType = 'application/octet-stream';
    }

    final refStorage = FirebaseStorage.instance.ref().child(
      'documentos/${user.uid}/$nombreFinal',
    );
    final metadata = SettableMetadata(contentType: contentType);

    await refStorage.putFile(archivo, metadata);
    final url = await refStorage.getDownloadURL();

    await FirebaseFirestore.instance.collection('documentos').add({
      'nombre': nombreFinal,
      'tituloUsuario': titulo.trim(),
      'nombreArchivo': nombreFinal,
      'url': url,
      'contentType': contentType,
      'fechaSubida': Timestamp.now(),
      'usuarioID': user.uid,
      'hijoID': widget.hijoId,
      'usuarioNombre': user.displayName ?? user.email ?? 'Usuario desconocido',
    });
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '✅ Documento "$titulo" subido correctamente',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontSize: 14,
          ),
        ),
      ),
    );
    if (!mounted) return;
    await obtenerProgenitores();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Scaffold(body: Center(child: Text('Cargando sesión...')));
    }

    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A), // Fondo azul oscuro
      appBar: AppBar(
        title: Text(
          'Tus documentos',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1B263B), // Azul más claro para el AppBar
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
        ), // ← Aquí cambias el color de la flecha
      ),
      body: Column(
        children: [
          construirFiltros(),
          Expanded(
            child: Container(
              color: Color(0xFF1B263B), // Fondo azul menos oscuro
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('documentos')
                    .where('hijoID', isEqualTo: widget.hijoId)
                    .orderBy('fechaSubida', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final err = snapshot.error;
                    if (err is FirebaseException &&
                        err.code == 'permission-denied') {
                      return const FallbackHijosWidget();
                    }
                    return Center(
                      child: Text(
                        "❌ Error cargando documentos",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "📭 No hay documentos disponibles",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final docsFiltrados = snapshot.data!.docs
                      .where(coincideFiltro)
                      .toList();

                  for (var doc in docsFiltrados) {
                    final data = doc.data() as Map<String, dynamic>?;
                    appLogger.d(
                      '📄 ${data?['tituloUsuario']} - hijoID: ${data?['hijoID']} - usuarioID: ${data?['usuarioID']}',
                    );
                  }

                  if (docsFiltrados.isEmpty) {
                    return Center(
                      child: Text(
                        "🔍 No hay resultados que coincidan con los filtros aplicados",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  for (var doc in docsFiltrados) {
                    final data = doc.data() as Map<String, dynamic>?;
                    appLogger.d(
                      '📄 ${data?['tituloUsuario']} - hijoID: ${data?['hijoID']} - usuarioID: ${data?['usuarioID']}',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: docsFiltrados.length,
                    itemBuilder: (context, index) {
                      final doc = docsFiltrados[index];

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                          left: 12,
                          right: 12,
                        ),
                        child: buildDocumento(
                          doc,
                        ), // sin borde ni fondo adicional
                      );
                    },
                  );
                }, // cierre de builder
              ), // cierre de StreamBuilder
            ), // cierre de Container
          ), // cierre de Expanded
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Añadir documento/s'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: subirDocumento,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
