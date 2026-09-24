import 'package:flutter/material.dart';

enum AttendanceStatus {
  present('출근함', Color(0xFF2F855A), Icons.check_circle),
  overtime('야근', Color(0xFF7C3AED), Icons.nightlight_round),
  rest('쉬는 날', Color(0xFF6B7280), Icons.weekend),
  halfDay('반차', Color(0xFFD97706), Icons.schedule),
  absent('결근', Color(0xFFB91C1C), Icons.cancel);

  const AttendanceStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}
