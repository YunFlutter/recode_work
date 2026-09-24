import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recode_works/data/models/attendance_record_dto.dart';
import 'package:recode_works/domain/models/attendance_record.dart';
import 'package:recode_works/domain/models/attendance_status.dart';
import 'package:recode_works/domain/models/work_session.dart';

void main() {
  test('기존 로컬 JSON 구조를 그대로 왕복 변환한다', () {
    const record = AttendanceRecord(
      status: AttendanceStatus.overtime,
      workSessions: <WorkSession>[
        WorkSession(
          startTime: TimeOfDay(hour: 8, minute: 30),
          endTime: TimeOfDay(hour: 12, minute: 0),
        ),
        WorkSession(
          startTime: TimeOfDay(hour: 14, minute: 0),
          endTime: TimeOfDay(hour: 21, minute: 5),
        ),
      ],
      memo: '야간 작업',
    );

    final dto = AttendanceRecordDto.fromDomain(record);

    expect(dto.toJson(), <String, Object?>{
      'status': 'overtime',
      'startTime': <String, int>{'hour': 8, 'minute': 30},
      'endTime': <String, int>{'hour': 12, 'minute': 0},
      'workSessions': <Map<String, Object?>>[
        <String, Object?>{
          'startTime': <String, int>{'hour': 8, 'minute': 30},
          'endTime': <String, int>{'hour': 12, 'minute': 0},
        },
        <String, Object?>{
          'startTime': <String, int>{'hour': 14, 'minute': 0},
          'endTime': <String, int>{'hour': 21, 'minute': 5},
        },
      ],
      'memo': '야간 작업',
    });

    final restored = AttendanceRecordDto.fromJson(dto.toJson()).toDomain();
    expect(restored.status, AttendanceStatus.overtime);
    expect(restored.startTime, const TimeOfDay(hour: 8, minute: 30));
    expect(restored.endTime, const TimeOfDay(hour: 12, minute: 0));
    expect(restored.workSessions, hasLength(2));
    expect(
      restored.workSessions.last.endTime,
      const TimeOfDay(hour: 21, minute: 5),
    );
    expect(restored.memo, '야간 작업');
  });

  test('예전 단일 시간 JSON을 첫 번째 근무 시간으로 변환한다', () {
    final restored =
        AttendanceRecordDto.fromJson(<String, dynamic>{
          'status': 'present',
          'startTime': <String, int>{'hour': 9, 'minute': 0},
          'endTime': <String, int>{'hour': 12, 'minute': 30},
          'memo': '',
        }).toDomain();

    expect(restored.workSessions, hasLength(1));
    expect(
      restored.workSessions.single.startTime,
      const TimeOfDay(hour: 9, minute: 0),
    );
    expect(
      restored.workSessions.single.endTime,
      const TimeOfDay(hour: 12, minute: 30),
    );
  });

  test('날짜 키는 기존 YYYY-MM-DD 형식을 유지한다', () {
    final date = DateTime(2026, 5, 1, 23, 59);
    final key = attendanceDateKey(date);

    expect(key, '2026-05-01');
    expect(attendanceDateFromKey(key), DateTime(2026, 5, 1));
    expect(() => attendanceDateFromKey('2026-02-31'), throwsFormatException);
  });
}
