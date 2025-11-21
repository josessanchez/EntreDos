import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String id;
  final String hijoId;
  final String senderId;
  final String? senderName;
  final String content;
  final String type; // 'text' | 'request'
  final List<String> options;
  final String status; // pending | accepted | rejected | answered | sent
  final DateTime? createdAt;
  final DateTime? sentAt;
  final Map<String, DateTime?> readBy;
  final List<Map<String, dynamic>> responses;
  final String? urlArchivo;
  final String? nombreArchivo;

  Mensaje({
    required this.id,
    required this.hijoId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.type,
    required this.options,
    required this.status,
    required this.createdAt,
    required this.sentAt,
    required this.readBy,
    required this.responses,
    this.urlArchivo,
    this.nombreArchivo,
  });

  factory Mensaje.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? tsToDate(dynamic ts) {
      if (ts == null) return null;
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      return null;
    }

    final readRaw = data['readBy'] as Map<String, dynamic>? ?? {};
    final readBy = <String, DateTime?>{};
    readRaw.forEach((k, v) => readBy[k] = tsToDate(v));

    final responsesRaw = List.from(data['responses'] ?? []);

    return Mensaje(
      id: doc.id,
      hijoId: data['hijoId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      options: List<String>.from(data['options'] ?? []),
      status: data['status'] ?? 'pending',
      createdAt: tsToDate(data['createdAt']),
      sentAt: tsToDate(data['sentAt']),
      readBy: readBy,
      responses: responsesRaw.cast<Map<String, dynamic>>(),
      senderName: (data['senderName'] as String?)?.toString(),
      urlArchivo: data['urlArchivo'] as String?,
      nombreArchivo: data['nombreArchivo'] as String?,
    );
  }

  Map<String, dynamic> toMapForCreate({required String uid}) {
    return {
      'hijoId': hijoId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'options': options,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': {uid: FieldValue.serverTimestamp()},
      'responses': responses,
      'urlArchivo': urlArchivo,
      'nombreArchivo': nombreArchivo,
    };
  }
}
