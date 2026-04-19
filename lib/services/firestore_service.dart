import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> saveLog({
    required String stationName,
    required String statusLabel,
    required String parameterName,
    required double? rawValue,
    required String unit,
    required String lastUpdated,
    required String trendSummary,
  }) async {
    await _db.collection('saved_logs').add({
      'stationName': stationName,
      'statusLabel': statusLabel,
      'parameterName': parameterName,
      'rawValue': rawValue,
      'unit': unit,
      'lastUpdated': lastUpdated,
      'trendSummary': trendSummary,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamLogs() {
    return _db
        .collection('saved_logs')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }
}
