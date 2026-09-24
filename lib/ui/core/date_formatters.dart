import 'package:flutter/material.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<DateTime> daysInMonth(DateTime month) {
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  return List<DateTime>.generate(
    lastDay,
    (index) => DateTime(month.year, month.month, index + 1),
  );
}

String formatMonth(DateTime date) => '${date.year}년 ${date.month}월';

String formatFullDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}

String formatShortDate(DateTime date) => '${date.month}월 ${date.day}일';

String formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
