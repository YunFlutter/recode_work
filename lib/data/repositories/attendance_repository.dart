import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/attendance_record.dart';
import '../models/attendance_record_dto.dart';

abstract class AttendanceRepository {
  Map<DateTime, AttendanceRecord> getAll();
  AttendanceRecord? getByDate(DateTime date);
  Future<void> save(DateTime date, AttendanceRecord record);
}

class InMemoryAttendanceRepository implements AttendanceRepository {
  final Map<DateTime, AttendanceRecord> _records =
      <DateTime, AttendanceRecord>{};

  @override
  Map<DateTime, AttendanceRecord> getAll() {
    return Map<DateTime, AttendanceRecord>.unmodifiable(_records);
  }

  @override
  AttendanceRecord? getByDate(DateTime date) {
    return _records[_dateOnly(date)];
  }

  @override
  Future<void> save(DateTime date, AttendanceRecord record) async {
    _records[_dateOnly(date)] = record;
  }
}

class SharedPreferencesAttendanceRepository implements AttendanceRepository {
  SharedPreferencesAttendanceRepository._(this._preferences, this._records);

  static const String _storageKey = 'attendance_records_v1';

  final SharedPreferences _preferences;
  final Map<DateTime, AttendanceRecord> _records;

  static Future<SharedPreferencesAttendanceRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    final records = _decodeRecords(preferences.getString(_storageKey));
    return SharedPreferencesAttendanceRepository._(preferences, records);
  }

  @override
  Map<DateTime, AttendanceRecord> getAll() {
    return Map<DateTime, AttendanceRecord>.unmodifiable(_records);
  }

  @override
  AttendanceRecord? getByDate(DateTime date) {
    return _records[_dateOnly(date)];
  }

  @override
  Future<void> save(DateTime date, AttendanceRecord record) async {
    _records[_dateOnly(date)] = record;
    await _preferences.setString(
      _storageKey,
      jsonEncode(_encodeRecords(_records)),
    );
  }

  static Map<DateTime, AttendanceRecord> _decodeRecords(String? rawJson) {
    if (rawJson == null || rawJson.isEmpty) {
      return <DateTime, AttendanceRecord>{};
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      return <DateTime, AttendanceRecord>{};
    }

    final records = <DateTime, AttendanceRecord>{};
    for (final entry in decoded.entries) {
      if (entry.value is! Map<String, dynamic>) {
        continue;
      }
      try {
        final dto = AttendanceRecordDto.fromJson(
          entry.value as Map<String, dynamic>,
        );
        records[attendanceDateFromKey(entry.key)] = dto.toDomain();
      } on FormatException {
        // Keep loading the remaining valid local records.
      }
    }
    return records;
  }

  static Map<String, Object?> _encodeRecords(
    Map<DateTime, AttendanceRecord> records,
  ) {
    return records.map((date, record) {
      return MapEntry(
        attendanceDateKey(date),
        AttendanceRecordDto.fromDomain(record).toJson(),
      );
    });
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
