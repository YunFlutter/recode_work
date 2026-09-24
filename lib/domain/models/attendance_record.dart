import 'package:flutter/material.dart';

import 'attendance_status.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.status,
    this.startTime,
    this.endTime,
    this.memo = '',
    this.isAutoAbsent = false,
    this.isAutomaticDefault = false,
  });

  final AttendanceStatus status;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String memo;
  final bool isAutoAbsent;
  final bool isAutomaticDefault;
}
