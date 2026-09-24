import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/attendance_record.dart';
import '../models/attendance_record_dto.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<DateTime, AttendanceRecord>> fetchAll({required String deviceKey});

  Future<void> save({
    required String deviceKey,
    required DateTime date,
    required AttendanceRecord record,
  });

  Future<void> saveAll({
    required String deviceKey,
    required Map<DateTime, AttendanceRecord> records,
  });
}

class FirestoreAttendanceRemoteDataSource
    implements AttendanceRemoteDataSource {
  FirestoreAttendanceRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _devicesCollection = 'attendance_devices';
  static const String _recordsCollection = 'records';
  static const int _batchSize = 400;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<DateTime, AttendanceRecord>> fetchAll({
    required String deviceKey,
  }) async {
    final snapshot = await _records(
      deviceKey,
    ).get(const GetOptions(source: Source.server));
    final records = <DateTime, AttendanceRecord>{};

    for (final document in snapshot.docs) {
      try {
        final date = attendanceDateFromKey(document.id);
        final dto = AttendanceRecordDto.fromJson(document.data());
        records[date] = dto.toDomain();
      } on FormatException {
        // A malformed cloud document must not prevent valid local data loading.
      }
    }
    return Map<DateTime, AttendanceRecord>.unmodifiable(records);
  }

  @override
  Future<void> save({
    required String deviceKey,
    required DateTime date,
    required AttendanceRecord record,
  }) async {
    await _records(
      deviceKey,
    ).doc(attendanceDateKey(date)).set(_documentData(record));
  }

  @override
  Future<void> saveAll({
    required String deviceKey,
    required Map<DateTime, AttendanceRecord> records,
  }) async {
    final entries = records.entries.toList(growable: false);
    for (var offset = 0; offset < entries.length; offset += _batchSize) {
      final end = (offset + _batchSize).clamp(0, entries.length);
      final batch = _firestore.batch();
      for (final entry in entries.sublist(offset, end)) {
        batch.set(
          _records(deviceKey).doc(attendanceDateKey(entry.key)),
          _documentData(entry.value),
        );
      }
      await batch.commit();
    }
  }

  CollectionReference<Map<String, dynamic>> _records(String deviceKey) {
    return _firestore
        .collection(_devicesCollection)
        .doc(deviceKey)
        .collection(_recordsCollection);
  }

  Map<String, Object?> _documentData(AttendanceRecord record) {
    return <String, Object?>{
      ...AttendanceRecordDto.fromDomain(record).toJson(),
      'schemaVersion': 3,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
