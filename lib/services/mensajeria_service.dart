import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:entredos/models/mensaje.dart';
import 'package:entredos/utils/app_logger.dart';

/// Clean implementation of MensajeriaService.
class MensajeriaService {
  final CollectionReference _mensajes = FirebaseFirestore.instance.collection(
    'mensajes',
  );

  Stream<List<Mensaje>> streamMensajes(String hijoId) {
    return _mensajes
        .where('hijoId', isEqualTo: hijoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Mensaje.fromDoc(d)).toList());
  }

  Future<void> sendMessage({
    required String hijoId,
    required String senderId,
    required String content,
    bool isRequest = false,
    String? fileUrl,
    String? fileName,
    String? senderName,
  }) async {
    final doc = {
      'hijoId': hijoId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': isRequest ? 'request' : 'text',
      'options': isRequest ? ['yes', 'no', 'comment'] : [],
      'status': isRequest ? 'pending' : 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': {senderId: FieldValue.serverTimestamp()},
      'responses': [],
      'urlArchivo': fileUrl,
      'nombreArchivo': fileName,
    };

    final ref = await _mensajes.add(doc);
    appLogger.d(
      '[MensajeriaService] sendMessage created doc=${ref.id} hijoId=$hijoId senderId=$senderId file=${fileName ?? 'none'}',
    );
  }

  Future<void> respond({
    required String mensajeId,
    required String responderId,
    required String action,
    String? comment,
  }) async {
    final now = Timestamp.now();
    final response = {
      'responderId': responderId,
      'action': action,
      'comment': comment ?? '',
      'timestamp': now,
    };

    final docRef = _mensajes.doc(mensajeId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) throw Exception('Mensaje no encontrado');

        tx.update(docRef, {
          'status': action == 'yes'
              ? 'Aceptado'
              : (action == 'no' ? 'Rechazado' : 'Respondido'),
          'responses': FieldValue.arrayUnion([response]),
          'readBy.$responderId': now,
        });
      });
    } on FirebaseException catch (fe) {
      appLogger.w(
        'MensajeriaService.respond FirebaseException: code=${fe.code} message=${fe.message}',
      );
      rethrow;
    } catch (e, st) {
      appLogger.e('MensajeriaService.respond error: $e', e, st);
      rethrow;
    }
  }

  /// Marks messages for [hijoId] as read by [uid]. Returns number of documents updated.
  Future<int> markReadForUser(String hijoId, String uid) async {
    // Debug: announce invocation
    appLogger.d(
      '[MensajeriaService] markReadForUser called for hijoId=$hijoId uid=$uid',
    );
    try {
      final recent = await _mensajes
          .where('hijoId', isEqualTo: hijoId)
          .orderBy('createdAt', descending: true)
          .limit(500)
          .get();

      appLogger.d(
        '[MensajeriaService] fetched ${recent.docs.length} recent docs',
      );

      var updated = 0;
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in recent.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final senderId = data['senderId'] as String?;
        final readRaw = data['readBy'] as Map<String, dynamic>? ?? {};

        // Only mark as read if the message was sent by someone else
        // and this uid has not already been recorded.
        if (senderId != null && senderId != uid && !readRaw.containsKey(uid)) {
          batch.update(doc.reference, {
            'readBy.$uid': FieldValue.serverTimestamp(),
          });
          updated++;
        }
      }

      if (updated > 0) {
        await batch.commit();
        appLogger.d('[MensajeriaService] commit: updated $updated docs');
      } else {
        appLogger.d('[MensajeriaService] no docs needed update');
      }

      return updated;
    } catch (e, st) {
      appLogger.e('[MensajeriaService] markReadForUser error: $e', e, st);
      return 0;
    }
  }
}
