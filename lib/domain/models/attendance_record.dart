import 'package:flutter/material.dart';

import 'attendance_status.dart';
import 'work_session.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.status,
    this.workSessions = const <WorkSession>[],
    this.memo = '',
    this.isAutoAbsent = false,
    this.isAutomaticDefault = false,
  });

  final AttendanceStatus status;
  final List<WorkSession> workSessions;
  final String memo;
  final bool isAutoAbsent;
  final bool isAutomaticDefault;

  TimeOfDay? get startTime =>
      workSessions.isEmpty ? null : workSessions.first.startTime;

  TimeOfDay? get endTime =>
      workSessions.isEmpty ? null : workSessions.first.endTime;
}
