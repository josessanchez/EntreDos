import 'package:cloud_functions/cloud_functions.dart';

/// Helper that calls the `listHijosForUid` callable and returns a list of maps.
///
/// The callable may return different shapes depending on the backend. We
/// normalize to a list of maps where each map contains the child's fields
/// and an `id` key with the document id.
Future<List<Map<String, dynamic>>> fetchHijosFallback({String? uid}) async {
  final functions = FirebaseFunctions.instance;
  final HttpsCallable callable = functions.httpsCallable('listHijosForUid');
  final resp = await callable.call(<String, dynamic>{
    if (uid != null) 'uid': uid,
  });

  final data = resp.data;

  // Case 1: callable returned { items: [ { id, data }, ... ] }
  if (data is Map && data['items'] is List) {
    final items = data['items'] as List;
    return items
        .map<Map<String, dynamic>>((e) {
          try {
            final m = Map<String, dynamic>.from(e as Map);
            final id = m['id']?.toString() ?? '';
            final raw = m['data'] is Map
                ? Map<String, dynamic>.from(m['data'] as Map)
                : <String, dynamic>{};
            // Merge id + raw fields into one map
            return <String, dynamic>{'id': id, ...raw};
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  // Case 2: callable returned { hijos: [ map, ... ] } or a plain List
  if (data is Map && data['hijos'] is List) {
    return (data['hijos'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  if (data is List) {
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Unknown shape: return empty list
  return <Map<String, dynamic>>[];
}
