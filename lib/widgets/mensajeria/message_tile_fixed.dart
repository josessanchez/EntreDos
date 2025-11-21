import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:entredos/models/mensaje.dart';
import 'package:entredos/helpers/documento_helper.dart';
import 'package:entredos/utils/app_logger.dart';

typedef OnRespond = Future<void> Function(String action, {String? comment});

class MessageTile extends StatelessWidget {
  final Mensaje mensaje;
  final String currentUid;
  final OnRespond onRespond;
  final String? searchQuery;

  const MessageTile({
    super.key,
    required this.mensaje,
    required this.currentUid,
    required this.onRespond,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = mensaje.senderId == currentUid;
    final createdAt = mensaje.createdAt;
    final statusLower = mensaje.status.toLowerCase();

    String mapStatusLabel(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return 'PENDIENTE';
        case 'answered':
          return 'respondido';
        default:
          return status;
      }
    }

    String mapResponseAction(String rawAction) {
      final a = rawAction.toLowerCase();
      if (a == 'yes') return 'Aceptado';
      if (a == 'no') return 'Rechazado';
      if (a == 'comment') return 'Comentario';
      return rawAction;
    }

    Widget statusWidget() {
      final status = statusLower;
      if (isMine) {
        final readers = mensaje.readBy.keys
            .where((k) => k != mensaje.senderId)
            .toList();
        final bool anyOtherRead = readers.isNotEmpty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              anyOtherRead ? Icons.done_all : Icons.done,
              size: 16,
              color: anyOtherRead ? Colors.blueAccent : Colors.white54,
            ),
            if (status != 'sent') ...[
              SizedBox(width: 6),
              Text(
                mapStatusLabel(mensaje.status.toUpperCase()),
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ],
        );
      } else {
        if (status == 'sent') return SizedBox.shrink();
        return Text(
          mapStatusLabel(mensaje.status.toUpperCase()),
          style: TextStyle(color: Colors.white70, fontSize: 11),
        );
      }
    }

    return Card(
      color: Color(0xFF1B263B),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final double reservedForStatus = math.min(160, maxW * 0.35);
          final double textWidth = math.max(60, maxW - reservedForStatus - 12);
          final query = searchQuery?.trim() ?? '';

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Flexible main text so right side can shrink without overflow
                      Expanded(
                        child: query.isEmpty
                            ? Text(
                                mensaje.content,
                                style: TextStyle(color: Colors.white),
                                softWrap: true,
                              )
                            : _buildHighlightedText(
                                mensaje.content,
                                query,
                                baseStyle: const TextStyle(color: Colors.white),
                              ),
                      ),
                      SizedBox(width: 8),
                      // Right side constrained to reservedForStatus to avoid overflow
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: reservedForStatus,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (createdAt != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: math.max(
                                        60,
                                        reservedForStatus - 8,
                                      ),
                                    ),
                                    child: statusWidget(),
                                  ),
                                ],
                              ),
                            SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (mensaje.urlArchivo != null &&
                      mensaje.urlArchivo!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: textWidth),
                      child: InkWell(
                        onTap: () {
                          final name = mensaje.nombreArchivo ?? 'archivo';
                          final url = mensaje.urlArchivo ?? '';
                          if (url.isNotEmpty) {
                            try {
                              DocumentoHelper.ver(context, name, url);
                            } catch (e, st) {
                              appLogger.e(
                                '[MessageTile] DocumentoHelper.ver error: $e',
                                e,
                                st,
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF0F1720),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Archivo adjunto',
                                  style: TextStyle(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.download,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  final name =
                                      mensaje.nombreArchivo ?? 'archivo';
                                  final url = mensaje.urlArchivo ?? '';
                                  if (url.isNotEmpty) {
                                    try {
                                      DocumentoHelper.descargar(
                                        context,
                                        name,
                                        url,
                                      );
                                    } catch (e, st) {
                                      appLogger.e(
                                        '[MessageTile] DocumentoHelper.descargar error: $e',
                                        e,
                                        st,
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // If search query matches the attachment filename, show a hint line
                    if (query.isNotEmpty &&
                        mensaje.nombreArchivo != null &&
                        mensaje.nombreArchivo!.toLowerCase().contains(
                          query.toLowerCase(),
                        )) ...[
                      SizedBox(height: 6),
                      Text(
                        'Coincidencia de búsqueda en el archivo adjunto',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],

                  if (mensaje.type == 'request') ...[
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (!isMine && mensaje.status == 'pending')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () => onRespond('yes'),
                            child: Text('Aceptar'),
                          ),
                        if (!isMine && mensaje.status == 'pending')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => onRespond('no'),
                            child: Text('Rechazar'),
                          ),
                        if (!isMine && mensaje.status == 'pending')
                          ElevatedButton(
                            onPressed: () async {
                              final comment = await showDialog<String>(
                                context: context,
                                builder: (dialogContext) {
                                  final c = TextEditingController();
                                  return AlertDialog(
                                    title: Text('Añadir comentario'),
                                    content: TextField(
                                      controller: c,
                                      autofocus: true,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                          dialogContext,
                                          c.text.trim(),
                                        ),
                                        child: Text('Enviar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (comment != null && comment.isNotEmpty) {
                                try {
                                  await onRespond('comment', comment: comment);
                                } catch (e, st) {
                                  appLogger.e(
                                    '[MessageTile] onRespond error: $e',
                                    e,
                                    st,
                                  );
                                }
                              }
                            },
                            child: Text('Comentar'),
                          ),
                      ],
                    ),
                  ],

                  if (mensaje.responses.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Respuestas:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    ...mensaje.responses.map((r) {
                      final rawAction = (r['action'] ?? '').toString();
                      final comment = (r['comment'] ?? '').toString();
                      final actionLabel = mapResponseAction(rawAction);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: query.isEmpty
                            ? Text(
                                '- $actionLabel${comment.isNotEmpty ? ': $comment' : ''}',
                                style: TextStyle(color: Colors.white60),
                              )
                            : _buildHighlightedText(
                                '- $actionLabel${comment.isNotEmpty ? ': $comment' : ''}',
                                query,
                                baseStyle: TextStyle(color: Colors.white60),
                              ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String? query, {
    TextStyle? baseStyle,
  }) {
    final s = (query ?? '').trim();
    final defaultStyle = baseStyle ?? const TextStyle(color: Colors.white);
    if (s.isEmpty) return Text(text, style: defaultStyle, softWrap: true);

    try {
      final pattern = RegExp(RegExp.escape(s), caseSensitive: false);
      final matches = pattern.allMatches(text);
      if (matches.isEmpty) {
        return Text(text, style: defaultStyle, softWrap: true);
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
        maxLines: 10,
      );
    } catch (_) {
      return Text(text, style: defaultStyle, softWrap: true);
    }
  }
}
