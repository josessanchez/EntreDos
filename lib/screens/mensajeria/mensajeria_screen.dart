import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:entredos/screens/visor_pdf_local_screen.dart';

import 'package:entredos/models/mensaje.dart';
import 'package:entredos/utils/app_logger.dart';
import 'package:entredos/services/mensajeria_service.dart';
import 'package:entredos/widgets/mensajeria/message_tile_fixed.dart';
import 'package:entredos/widgets/fallback_body.dart';

class MensajeriaScreen extends StatefulWidget {
  final String hijoId;
  final String hijoNombre;

  const MensajeriaScreen({
    super.key,
    required this.hijoId,
    required this.hijoNombre,
  });

  @override
  _MensajeriaScreenState createState() => _MensajeriaScreenState();
}

class _MensajeriaScreenState extends State<MensajeriaScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isRequest = false;
  bool _sending = false;
  bool _uploading = false;
  bool _searching = false;
  // Debug: force using putData instead of putFile to bypass native streaming channel
  // Set to true temporarily to see if uploads succeed via putData fallback.
  final bool _forcePutData = true;
  String? _attachedFileName;
  String? _attachedFileUrl;

  final MensajeriaService _service = MensajeriaService();
  DateTime? _lastMarked;
  bool _markInProgress = false;
  final Duration _markCooldown = Duration(seconds: 3);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _marcarLeidos();
    _searchController.addListener(() {
      // rebuild to apply live filtering as the user types
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHighlightedTextLocal(
    String text,
    String? query, {
    TextStyle? baseStyle,
  }) {
    final s = (query ?? '').trim();
    final defaultStyle = baseStyle ?? TextStyle(color: Colors.white70);
    if (s.isEmpty) {
      return Text(text, style: defaultStyle, overflow: TextOverflow.ellipsis);
    }

    try {
      final pattern = RegExp(RegExp.escape(s), caseSensitive: false);
      final matches = pattern.allMatches(text);
      if (matches.isEmpty) {
        return Text(text, style: defaultStyle, overflow: TextOverflow.ellipsis);
      }

      final spans = <TextSpan>[];
      int last = 0;
      for (final m in matches) {
        if (m.start > last) {
          spans.add(
            TextSpan(text: text.substring(last, m.start), style: defaultStyle),
          );
        }
        spans.add(
          TextSpan(
            text: text.substring(m.start, m.end),
            style: defaultStyle.copyWith(
              backgroundColor: Colors.yellowAccent.withAlpha(
                (0.35 * 255).round(),
              ),
              color: Colors.black,
            ),
          ),
        );
        last = m.end;
      }
      if (last < text.length) {
        spans.add(TextSpan(text: text.substring(last), style: defaultStyle));
      }

      return RichText(
        text: TextSpan(children: spans),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } catch (_) {
      return Text(text, style: defaultStyle, overflow: TextOverflow.ellipsis);
    }
  }

  Future<void> _marcarLeidos() async {
    final uid = _uid;
    if (uid == null) return;
    final now = DateTime.now();
    if (_markInProgress) return;
    if (_lastMarked != null && now.difference(_lastMarked!) < _markCooldown) {
      return;
    }
    _markInProgress = true;
    appLogger.d(
      '[_MensajeriaScreenState] _marcarLeidos() called for uid=$uid hijoId=${widget.hijoId}',
    );
    try {
      final updated = await _service.markReadForUser(widget.hijoId, uid);
      appLogger.d(
        '[_MensajeriaScreenState] markReadForUser updated=$updated docs',
      );
    } catch (e, st) {
      appLogger.e('[_MensajeriaScreenState] markReadForUser error: $e', e, st);
    } finally {
      _lastMarked = DateTime.now();
      _markInProgress = false;
    }
  }

  Future<void> _sendMessage() async {
    final uid = _uid;
    final text = _controller.text.trim();
    if (uid == null) return;

    final messenger = ScaffoldMessenger.of(context);

    // Enforce that every message contains text. Previously attachments
    // could be sent without text; now every message (plain, with
    // attachment, or request) must include some textual content.
    if (text.isEmpty) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Debes escribir un mensaje')),
        );
      }
      return;
    }

    setState(() => _sending = true);
    try {
      final contentToSend = text.isNotEmpty ? text : (_attachedFileName ?? '');
      await _service.sendMessage(
        hijoId: widget.hijoId,
        senderId: uid,
        content: contentToSend,
        isRequest: _isRequest,
        fileUrl: _attachedFileUrl,
        fileName: _attachedFileName,
        senderName: FirebaseAuth.instance.currentUser?.displayName?.trim(),
      );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _attachedFileName = null;
        _attachedFileUrl = null;
        _isRequest = false;
      });
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Mensaje enviado')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _respondToRequest(
    String mensajeId,
    String action, {
    String? comment,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.respond(
        mensajeId: mensajeId,
        responderId: uid,
        action: action,
        comment: comment,
      );
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Respuesta enviada')));
      }
    } catch (e) {
      appLogger.e('Error en _respondToRequest: $e', e);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Error al responder. Revisa la consola para más detalles.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      String fileName = picked.name;
      File file;

      if (picked.path != null) {
        file = File(picked.path!);
        fileName = path_pkg.basename(picked.path!);
        appLogger.d('[Mensajeria] picked localPath=${picked.path}');
      } else if (picked.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        file = File(tempPath);
        await file.writeAsBytes(picked.bytes!);
        appLogger.d('[Mensajeria] wrote bytes to tempPath=$tempPath');
      } else {
        appLogger.w('[Mensajeria] picked file has no path and no bytes');
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('No se pudo acceder al archivo seleccionado'),
            ),
          );
        }
        return;
      }

      final storagePath =
          'mensajeria/${widget.hijoId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      if (!_forcePutData) {
        try {
          // Try putFile first (native stream). If that fails, fallback to putData.
          appLogger.d('[Mensajeria] attempting putFile upload');
          final uploadTask = ref.putFile(file);
          uploadTask.snapshotEvents.listen((s) {
            final progress =
                (s.bytesTransferred / (s.totalBytes == 0 ? 1 : s.totalBytes)) *
                100;
            appLogger.v(
              '[Mensajeria] upload progress (putFile): ${progress.toStringAsFixed(1)}%',
            );
          });
          await uploadTask.whenComplete(() {});
          final downloadUrl = await ref.getDownloadURL();

          if (mounted) {
            setState(() {
              _attachedFileName = fileName;
              _attachedFileUrl = downloadUrl;
            });
            messenger.showSnackBar(
              SnackBar(content: Text('Archivo adjuntado: $fileName')),
            );
          }
        } catch (e, st) {
          appLogger.e('[Mensajeria] putFile error: $e', e, st);
          // Fallback to putData
          try {
            appLogger.d('[Mensajeria] falling back to putData');
            final bytes = await file.readAsBytes();
            final uploadTask = ref.putData(bytes);
            uploadTask.snapshotEvents.listen((s) {
              final progress =
                  (s.bytesTransferred /
                      (s.totalBytes == 0 ? 1 : s.totalBytes)) *
                  100;
              appLogger.v(
                '[Mensajeria] upload progress (putData): ${progress.toStringAsFixed(1)}%',
              );
            });
            await uploadTask.whenComplete(() {});
            final downloadUrl = await ref.getDownloadURL();

            if (mounted) {
              setState(() {
                _attachedFileName = fileName;
                _attachedFileUrl = downloadUrl;
              });
              messenger.showSnackBar(
                SnackBar(content: Text('Archivo adjuntado: $fileName')),
              );
            }
          } catch (e2, st2) {
            appLogger.e('[Mensajeria] putData error: $e2', e2, st2);
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text('Error al subir archivo: $e2')),
              );
              setState(() {
                _attachedFileName = null;
                _attachedFileUrl = null;
              });
            }
          }
        }
      } else {
        // Force using putData (debug mode)
        try {
          appLogger.d(
            '[Mensajeria] forcePutData enabled: using putData directly',
          );
          final bytes = await file.readAsBytes();
          final uploadTask = ref.putData(bytes);
          uploadTask.snapshotEvents.listen((s) {
            final progress =
                (s.bytesTransferred / (s.totalBytes == 0 ? 1 : s.totalBytes)) *
                100;
            appLogger.v(
              '[Mensajeria] upload progress (putData): ${progress.toStringAsFixed(1)}%',
            );
          });
          await uploadTask.whenComplete(() {});
          final downloadUrl = await ref.getDownloadURL();

          if (mounted) {
            setState(() {
              _attachedFileName = fileName;
              _attachedFileUrl = downloadUrl;
            });
            messenger.showSnackBar(
              SnackBar(content: Text('Archivo adjuntado: $fileName')),
            );
          }
        } catch (e2, st2) {
          appLogger.e('[Mensajeria] putData error (force mode): $e2', e2, st2);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Error al subir archivo: $e2')),
            );
            setState(() {
              _attachedFileName = null;
              _attachedFileUrl = null;
            });
          }
        }
      }
    } catch (e, st) {
      appLogger.e('Error uploading file: $e', e, st);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error al adjuntar archivo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (_) {
                  // listener already triggers setState
                },
              )
            : Text('Mensajería - ${widget.hijoNombre}'),
        backgroundColor: Color(0xFF0D1B2A),
        actions: [
          if (!_searching)
            Builder(
              builder: (iconContext) {
                return IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () async {
                    // compute the position of the button to anchor the menu
                    final RenderBox button =
                        iconContext.findRenderObject() as RenderBox;
                    final RenderBox overlay =
                        Overlay.of(context).context.findRenderObject()
                            as RenderBox;
                    final Offset offset = button.localToGlobal(
                      Offset.zero,
                      ancestor: overlay,
                    );
                    final Size size = button.size;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromLTWH(
                        offset.dx,
                        offset.dy + size.height,
                        size.width,
                        0,
                      ),
                      Offset.zero & overlay.size,
                    );

                    final selected = await showMenu<String>(
                      context: context,
                      position: position,
                      items: [
                        const PopupMenuItem(
                          value: 'buscar',
                          child: Text('Buscador'),
                        ),
                        const PopupMenuItem(
                          value: 'descargar_historial',
                          child: Text('Descargar historial de conversación'),
                        ),
                      ],
                    );

                    if (selected == 'buscar') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _searchController.text = '';
                          _searching = true;
                        });
                      });
                    } else if (selected == 'descargar_historial') {
                      // generate, save and open PDF
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _exportConversationPdf();
                      });
                    }
                  },
                );
              },
            ),
          if (_searching)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searching = false;
                });
              },
            ),
        ],
      ),
      backgroundColor: Color(0xFF0D1B2A),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Mensaje>>(
              stream: _service.streamMensajes(widget.hijoId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  appLogger.e('Mensajeria stream error: $err', err);
                  if (err is FirebaseException &&
                      err.code == 'permission-denied') {
                    return const FallbackHijosWidget();
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, color: Colors.redAccent, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Error al cargar mensajes',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          SelectableText(
                            snapshot.error.toString(),
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: Text('Reintentar'),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Si el error es "PERMISSION_DENIED" revisa tus reglas de Firestore o la colección `mensajes`.',
                            style: TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;
                // Apply client-side search filtering (case-insensitive)
                final query = _searchController.text.trim().toLowerCase();
                List<Mensaje> filtered = items;
                if (query.isNotEmpty) {
                  filtered = items.where((m) {
                    final content = m.content.toLowerCase();
                    final name = (m.nombreArchivo ?? '').toLowerCase();
                    final status = m.status.toLowerCase();
                    final responses = m.responses
                        .map(
                          (r) => (r['comment'] ?? '').toString().toLowerCase(),
                        )
                        .join(' ');
                    return content.contains(query) ||
                        name.contains(query) ||
                        status.contains(query) ||
                        responses.contains(query);
                  }).toList();
                }
                if (mounted) _marcarLeidos();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay mensajes aún',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    try {
                      return MessageTile(
                        key: ValueKey(m.id),
                        mensaje: m,
                        currentUid: _uid ?? '',
                        searchQuery: _searchController.text,
                        onRespond: (action, {comment}) async =>
                            await _respondToRequest(
                              m.id,
                              action,
                              comment: comment,
                            ),
                      );
                    } catch (e, st) {
                      // Guard against a single message crashing the entire list
                      appLogger.e(
                        '[Mensajeria] MessageTile build error for id=${m.id}: $e',
                        e,
                        st,
                      );
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          color: Colors.red.shade900,
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Error al renderizar mensaje ${m.id}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Color(0xFF0D1B2A)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_attachedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF1B263B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _buildHighlightedTextLocal(
                                    _attachedFileName ?? '',
                                    _searchController.text,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white54,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() {
                                    _attachedFileName = null;
                                    _attachedFileUrl = null;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _uploading ? null : _pickAndUploadFile,
                      icon: _uploading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.attach_file, color: Colors.white70),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Color(0xFF1B263B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _isRequest,
                              onChanged: (v) =>
                                  setState(() => _isRequest = v ?? false),
                            ),
                            Text(
                              'Pedir',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _sending ? null : _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: _sending
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportConversationPdf() async {
    final now = DateTime.now();
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    final uid = _uid;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    messenger.showSnackBar(SnackBar(content: Text('Generando PDF...')));

    try {
      // Resolve user display names in batch to show readable names in PDF.
      Future<Map<String, String>> resolveUserNamesForUids(
        Set<String> uids,
      ) async {
        final Map<String, String> names = {};
        if (uids.isEmpty) return names;
        try {
          final col = FirebaseFirestore.instance.collection('users');
          final futures = uids.map((u) => col.doc(u).get());
          final snaps = await Future.wait(futures);
          for (final snap in snaps) {
            final uid = snap.id;
            if (snap.exists) {
              final data = snap.data();
              String name = '';
              if (data != null) {
                if (data.containsKey('displayName')) {
                  name = (data['displayName'] ?? '').toString();
                }
                if (name.isEmpty && data.containsKey('nombre')) {
                  name = (data['nombre'] ?? '').toString();
                }
              }
              if (name.isNotEmpty) names[uid] = name;
            }
          }
        } catch (e) {
          // if anything fails, return whatever we could resolve so far
        }
        return names;
      }

      // Try the indexed query first. If Firestore requires a composite index
      // (FAILED_PRECONDITION), fall back to a non-indexed query and sort
      // client-side to avoid crashing the export flow.
      List<Mensaje> mensajes;
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('mensajes')
            .where('hijoId', isEqualTo: widget.hijoId)
            .orderBy('createdAt', descending: false)
            .get();
        mensajes = querySnap.docs.map((d) => Mensaje.fromDoc(d)).toList();
      } on FirebaseException catch (fe) {
        // Firestore asks for a composite index for this query
        if (fe.code == 'failed-precondition' ||
            (fe.message?.contains('requires an index') ?? false)) {
          // Fallback: get all messages for hijoId without ordering and sort locally
          final qs = await FirebaseFirestore.instance
              .collection('mensajes')
              .where('hijoId', isEqualTo: widget.hijoId)
              .get();
          mensajes = qs.docs.map((d) => Mensaje.fromDoc(d)).toList();
          mensajes.sort((a, b) {
            final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return da.compareTo(db);
          });
        } else {
          rethrow;
        }
      }

      // gather UIDs present in the messages so we can resolve names in one go
      final Set<String> allUids = <String>{};
      for (final m in mensajes) {
        allUids.add(m.senderId);
        // readBy keys
        allUids.addAll(m.readBy.keys);
        // responses' responderId fields
        for (final r in m.responses) {
          final rid = (r['responderId'] ?? '').toString();
          if (rid.isNotEmpty) allUids.add(rid);
        }
      }

      final Map<String, String> resolvedNames = await resolveUserNamesForUids(
        allUids,
      );

      // Ensure the current user's displayName is available as a resolved name
      // so they appear as recipient when other users send messages.
      final String? currentDisplayName = FirebaseAuth
          .instance
          .currentUser
          ?.displayName
          ?.trim();
      if (uid != null &&
          currentDisplayName != null &&
          currentDisplayName.isNotEmpty) {
        resolvedNames[uid] = currentDisplayName;
      }

      // For any UIDs we couldn't resolve from the `users` collection,
      // try to find a `senderName` on existing message documents as a
      // fallback (useful when messages already store senderName).
      final missing = allUids
          .where((u) => !resolvedNames.containsKey(u))
          .toList();
      if (missing.isNotEmpty) {
        try {
          final futures = missing.map((mu) async {
            final qs = await FirebaseFirestore.instance
                .collection('mensajes')
                .where('senderId', isEqualTo: mu)
                .limit(1)
                .get();
            if (qs.docs.isNotEmpty) {
              final data = qs.docs.first.data() as Map<String, dynamic>? ?? {};
              final name = (data['senderName'] as String?)?.trim();
              if (name != null && name.isNotEmpty) return MapEntry(mu, name);
            }
            return null;
          }).toList();

          final results = await Future.wait(futures);
          for (final r in results) {
            if (r != null) resolvedNames[r.key] = r.value;
          }
        } catch (e, st) {
          appLogger.w(
            'Fallback name resolution from mensajes failed: $e',
            e,
            st,
          );
        }
      }

      final pdfDoc = pw.Document();

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (pw.Context ctx) {
            final List<pw.Widget> widgets = [];

            // Large centered brand title
            widgets.add(
              pw.Container(
                alignment: pw.Alignment.center,
                padding: pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  'ENTREDOS',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: pdf.PdfColors.blue,
                  ),
                ),
              ),
            );

            // Subtitle / document title
            widgets.add(
              pw.Header(level: 0, child: pw.Text('Historial de conversación')),
            );

            widgets.add(
              pw.Paragraph(
                text:
                    'Conversación relacionada con: ${widget.hijoNombre}\nGenerado: ${df.format(now)}\n\nEste pdf garantiza que ningún mensaje y/o archivo adjunto ha sido editado ni eliminado',
              ),
            );

            // Prefer the authenticated user's displayName when available
            final String? currentDisplayName = FirebaseAuth
                .instance
                .currentUser
                ?.displayName
                ?.trim();

            for (final m in mensajes) {
              final isMine = (m.senderId == uid);
              final senderResolved =
                  (m.senderName != null && m.senderName!.isNotEmpty)
                  ? m.senderName!
                  : (resolvedNames.containsKey(m.senderId)
                        ? resolvedNames[m.senderId]!
                        : m.senderId);
              final senderName = isMine
                  ? '$senderResolved (Tú)'
                  : senderResolved;

              final receiverName = isMine
                  ? widget.hijoNombre
                  : (uid != null
                        ? (resolvedNames.containsKey(uid)
                              ? resolvedNames[uid]!
                              : uid)
                        : '');

              widgets.add(pw.Divider());
              widgets.add(
                pw.Text(
                  'Mensaje ID: ${m.id}',
                  style: pw.TextStyle(fontSize: 9),
                ),
              );
              widgets.add(
                pw.Text(
                  'Remitente: $senderName',
                  style: pw.TextStyle(fontSize: 12),
                ),
              );
              widgets.add(
                pw.Text(
                  'Destinatario: $receiverName',
                  style: pw.TextStyle(fontSize: 12),
                ),
              );

              widgets.add(pw.SizedBox(height: 6));

              widgets.add(
                pw.Text(
                  'Contenido:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              );
              widgets.add(pw.Text(m.content));

              widgets.add(pw.SizedBox(height: 6));

              // Show the message type in Spanish for readability in the PDF
              final typeRaw = m.type.toString().trim().toLowerCase();
              String typeLabel;
              switch (typeRaw) {
                case 'text':
                case 'mensaje':
                  typeLabel = 'Texto';
                  break;
                case 'request':
                case 'petition':
                case 'peticion':
                  typeLabel = 'Petición';
                  break;
                case 'file':
                case 'attachment':
                  typeLabel = 'Archivo adjunto';
                  break;
                case 'image':
                  typeLabel = 'Imagen';
                  break;
                case 'pdf':
                  typeLabel = 'Documento PDF';
                  break;
                case 'video':
                  typeLabel = 'Vídeo';
                  break;
                case 'audio':
                  typeLabel = 'Audio';
                  break;
                default:
                  typeLabel = typeRaw.isNotEmpty
                      ? '${typeRaw[0].toUpperCase()}${typeRaw.substring(1)}'
                      : '-';
              }
              widgets.add(pw.Text('Tipo: $typeLabel'));

              widgets.add(
                pw.Text(
                  'Fecha creación: ${m.createdAt != null ? df.format(m.createdAt!) : '-'}',
                ),
              );
              widgets.add(
                pw.Text(
                  'Fecha envío: ${m.sentAt != null ? df.format(m.sentAt!) : '-'}',
                ),
              );

              // readBy entries
              if (m.readBy.isNotEmpty) {
                widgets.add(pw.Text('Lecturas:'));
                for (final entry in m.readBy.entries) {
                  final who = entry.key == uid
                      ? (currentDisplayName != null &&
                                currentDisplayName.isNotEmpty
                            ? '$currentDisplayName (Tú)'
                            : 'Tú')
                      : (resolvedNames.containsKey(entry.key)
                            ? resolvedNames[entry.key]!
                            : entry.key);
                  final when = entry.value != null
                      ? df.format(entry.value!)
                      : '-';
                  widgets.add(pw.Text('- $who: $when'));
                }
              }

              // responses
              if (m.responses.isNotEmpty) {
                widgets.add(pw.Text('Respuestas:'));
                for (final r in m.responses) {
                  final responderId = r['responderId']?.toString() ?? '';
                  final action = r['action']?.toString() ?? '';
                  final comment = (r['comment'] ?? '').toString();
                  final ts = r['timestamp'];
                  DateTime? t;
                  if (ts is Timestamp) t = ts.toDate();
                  if (ts is DateTime) t = ts;
                  final when = t != null ? df.format(t) : '-';
                  final responderName = responderId == uid
                      ? (currentDisplayName != null &&
                                currentDisplayName.isNotEmpty
                            ? '$currentDisplayName (Tú)'
                            : 'Tú')
                      : (resolvedNames.containsKey(responderId)
                            ? resolvedNames[responderId]!
                            : responderId);

                  // Map action values to human-friendly Spanish labels.
                  final act = action.trim().toLowerCase();
                  String actionLabel;
                  if (comment.isNotEmpty) {
                    actionLabel = 'Comentario: $comment';
                  } else if (act == 'yes' ||
                      act == 'si' ||
                      act == 'sí' ||
                      act == 'acept' ||
                      act == 'acepto' ||
                      act == 'aceptar') {
                    actionLabel = 'Acepto';
                  } else if (act == 'no' ||
                      act == 'rechazo' ||
                      act == 'rechazar' ||
                      act == 'rechazado') {
                    actionLabel = 'Rechazo';
                  } else if (act.isEmpty) {
                    actionLabel = '-';
                  } else {
                    // fallback: use the raw action value
                    actionLabel = action;
                  }

                  // Format: Nombre (Tú) "Etiqueta" el 2025-11-20 13:39:23
                  widgets.add(
                    pw.Text('- $responderName "$actionLabel" el $when'),
                  );
                }
              }

              if (m.nombreArchivo != null && m.nombreArchivo!.isNotEmpty) {
                widgets.add(pw.Text('Archivo adjunto: ${m.nombreArchivo}'));
                widgets.add(pw.Text('URL: ${m.urlArchivo ?? '-'}'));
              }
            }

            return widgets;
          },
        ),
      );

      final bytes = await pdfDoc.save();

      // write to temp
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'historial_${widget.hijoNombre}_$timestamp.pdf'
          .replaceAll(' ', '_');
      final tempPath = '${tempDir.path}/$fileName';
      final f = File(tempPath);
      await f.writeAsBytes(bytes, flush: true);

      // attempt to copy to Downloads (android path used elsewhere in app)
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final target = File('${downloadsDir.path}/$fileName');
          await target.writeAsBytes(bytes, flush: true);
        }
      } catch (e, st) {
        appLogger.w('No se pudo copiar a Downloads: $e', e, st);
      }

      // For Android 10+ (and robust behavior on Android 11+), attempt to
      // save via the platform MediaStore implementation which uses the
      // Storage Access Framework / MediaStore APIs and doesn't require
      // legacy external storage permissions.
      if (Platform.isAndroid) {
        const channel = MethodChannel('entredos/saveToDownloads');
        try {
          await channel.invokeMethod('saveFileToDownloads', {
            'sourcePath': tempPath,
            'fileName': fileName,
            'mimeType': 'application/pdf',
          });
        } catch (e, st) {
          appLogger.w('saveToDownloads platform call failed: $e', e, st);
        }
      }

      // open in-app using local viewer
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              VisorPdfLocalScreen(localPath: tempPath, nombre: fileName),
        ),
      );

      // also open with external app
      try {
        await OpenFilex.open(tempPath);
      } catch (e, st) {
        appLogger.w('OpenFilex failed: $e', e, st);
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('PDF generado: $fileName')),
        );
      }
    } catch (e, st) {
      appLogger.e('Error generando PDF: $e', e, st);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }
}
