import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_status.dart';

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

    return decoded.map((dateKey, value) {
      final recordJson = value as Map<String, dynamic>;
      return MapEntry(_dateFromKey(dateKey), _recordFromJson(recordJson));
    });
  }

  static Map<String, Object?> _encodeRecords(
    Map<DateTime, AttendanceRecord> records,
  ) {
    return records.map((date, record) {
      return MapEntry(_dateKey(date), _recordToJson(record));
    });
  }

  static Map<String, Object?> _recordToJson(AttendanceRecord record) {
    return <String, Object?>{
      'status': record.status.name,
      'startTime': _timeToJson(record.startTime),
      'endTime': _timeToJson(record.endTime),
      'memo': record.memo,
    };
  }

  static AttendanceRecord _recordFromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      status: AttendanceStatus.values.byName(json['status'] as String),
      startTime: _timeFromJson(json['startTime']),
      endTime: _timeFromJson(json['endTime']),
      memo: json['memo'] as String? ?? '',
    );
  }

  static Map<String, int>? _timeToJson(TimeOfDay? time) {
    if (time == null) {
      return null;
    }
    return <String, int>{'hour': time.hour, 'minute': time.minute};
  }

  static TimeOfDay? _timeFromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    return TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int);
  }

  static DateTime _dateFromKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static String _dateKey(DateTime date) {
    final normalized = _dateOnly(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
