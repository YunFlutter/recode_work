import 'package:flutter/material.dart';

import '../../domain/models/attendance_record.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/work_session.dart';

class AttendanceRecordDto {
  const AttendanceRecordDto({
    required this.status,
    required this.workSessions,
    required this.hasAdditionalShift,
    required this.isOvernight,
    required this.memo,
  });

  factory AttendanceRecordDto.fromDomain(AttendanceRecord record) {
    return AttendanceRecordDto(
      status: record.status.name,
      workSessions: record.workSessions
          .map(
            (session) => WorkSessionDto(
              startTime: _timeToJson(session.startTime),
              endTime: _timeToJson(session.endTime),
            ),
          )
          .toList(growable: false),
      hasAdditionalShift: record.hasAdditionalShift,
      isOvernight: record.isOvernight,
      memo: record.memo,
    );
  }

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'];
    if (statusName is! String) {
      throw const FormatException('출근 상태가 올바르지 않습니다.');
    }

    final status = AttendanceStatus.values.where(
      (candidate) => candidate.name == statusName,
    );
    if (status.isEmpty) {
      throw FormatException('알 수 없는 출근 상태입니다: $statusName');
    }

    final memo = json['memo'];
    if (memo != null && memo is! String) {
      throw const FormatException('메모가 올바르지 않습니다.');
    }

    final workSessions = _workSessionsFromJson(json);
    final hasAdditionalShift = _optionalBool(
      json,
      'hasAdditionalShift',
      '오후 추가 출근 값이 올바르지 않습니다.',
    );
    final isOvernight = _optionalBool(
      json,
      'isOvernight',
      '다음날까지 야근 값이 올바르지 않습니다.',
    );

    return AttendanceRecordDto(
      status: statusName,
      workSessions: workSessions,
      hasAdditionalShift: hasAdditionalShift,
      isOvernight: isOvernight,
      memo: memo as String? ?? '',
    );
  }

  final String status;
  final List<WorkSessionDto> workSessions;
  final bool hasAdditionalShift;
  final bool isOvernight;
  final String memo;

  Map<String, Object?> toJson() {
    final firstSession = workSessions.isEmpty ? null : workSessions.first;
    return <String, Object?>{
      'status': status,
      // Keep these legacy fields so older app versions can still read the
      // first work session after a downgrade.
      'startTime': firstSession?.startTime,
      'endTime': firstSession?.endTime,
      'workSessions': workSessions
          .map((session) => session.toJson())
          .toList(growable: false),
      'hasAdditionalShift': hasAdditionalShift,
      'isOvernight': isOvernight,
      'memo': memo,
    };
  }

  AttendanceRecord toDomain() {
    return AttendanceRecord(
      status: AttendanceStatus.values.byName(status),
      workSessions: workSessions
          .map(
            (session) => WorkSession(
              startTime: _timeFromMap(session.startTime),
              endTime: _timeFromMap(session.endTime),
            ),
          )
          .toList(growable: false),
      hasAdditionalShift: hasAdditionalShift,
      isOvernight: isOvernight,
      memo: memo,
    );
  }

  static Map<String, int>? _timeToJson(TimeOfDay? time) {
    if (time == null) {
      return null;
    }
    return <String, int>{'hour': time.hour, 'minute': time.minute};
  }

  static Map<String, int>? _timeFromJson(Object? json) {
    if (json == null) {
      return null;
    }
    if (json is! Map) {
      throw const FormatException('시간 형식이 올바르지 않습니다.');
    }

    final hour = json['hour'];
    final minute = json['minute'];
    if (hour is! int ||
        minute is! int ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('시간 값이 올바르지 않습니다.');
    }
    return <String, int>{'hour': hour, 'minute': minute};
  }

  static List<WorkSessionDto> _workSessionsFromJson(Map<String, dynamic> json) {
    if (json.containsKey('workSessions')) {
      final sessionsJson = json['workSessions'];
      if (sessionsJson is! List) {
        throw const FormatException('근무 시간 목록이 올바르지 않습니다.');
      }
      if (sessionsJson.length > 10) {
        throw const FormatException('하루 근무 시간은 10개까지 저장할 수 있습니다.');
      }
      return sessionsJson
          .map((sessionJson) {
            if (sessionJson is! Map) {
              throw const FormatException('근무 시간 형식이 올바르지 않습니다.');
            }
            return WorkSessionDto(
              startTime: _timeFromJson(sessionJson['startTime']),
              endTime: _timeFromJson(sessionJson['endTime']),
            );
          })
          .toList(growable: false);
    }

    final legacyStartTime = _timeFromJson(json['startTime']);
    final legacyEndTime = _timeFromJson(json['endTime']);
    if (legacyStartTime == null && legacyEndTime == null) {
      return const <WorkSessionDto>[];
    }
    return <WorkSessionDto>[
      WorkSessionDto(startTime: legacyStartTime, endTime: legacyEndTime),
    ];
  }

  static bool _optionalBool(
    Map<String, dynamic> json,
    String key,
    String errorMessage,
  ) {
    final value = json[key];
    if (value == null) {
      return false;
    }
    if (value is! bool) {
      throw FormatException(errorMessage);
    }
    return value;
  }

  static TimeOfDay? _timeFromMap(Map<String, int>? time) {
    if (time == null) {
      return null;
    }
    return TimeOfDay(hour: time['hour']!, minute: time['minute']!);
  }
}

class WorkSessionDto {
  const WorkSessionDto({required this.startTime, required this.endTime});

  final Map<String, int>? startTime;
  final Map<String, int>? endTime;

  Map<String, Object?> toJson() {
    return <String, Object?>{'startTime': startTime, 'endTime': endTime};
  }
}

DateTime attendanceDateFromKey(String key) {
  final parts = key.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((part) => part == null)) {
    throw FormatException('날짜 키가 올바르지 않습니다: $key');
  }

  final date = DateTime(parts[0]!, parts[1]!, parts[2]!);
  if (attendanceDateKey(date) != key) {
    throw FormatException('날짜 값이 올바르지 않습니다: $key');
  }
  return date;
}

String attendanceDateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
