import 'package:flutter/material.dart';

import '../../../../data/repositories/attendance_repository.dart';
import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/attendance_status.dart';
import '../../../../domain/models/month_summary.dart';
import '../../../../domain/models/work_session.dart';
import '../../../core/date_formatters.dart';

class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel({
    required AttendanceRepository repository,
    DateTime? today,
  }) : _repository = repository,
       today = dateOnly(today ?? DateTime.now()) {
    focusedMonth = DateTime(this.today.year, this.today.month);
    selectedDate = this.today;
  }

  final AttendanceRepository _repository;
  final DateTime today;

  late DateTime focusedMonth;
  late DateTime selectedDate;
  int tabIndex = 0;
  String? lastMessage;
  bool? largeTextModeOverride;

  bool shouldUseLargeTextMode(bool systemPrefersLargeText) {
    return largeTextModeOverride ?? systemPrefersLargeText;
  }

  void setLargeTextMode(bool enabled) {
    largeTextModeOverride = enabled;
    notifyListeners();
  }

  AttendanceRecord? recordFor(DateTime date) {
    final key = dateOnly(date);
    final stored = _repository.getByDate(key);
    if (stored != null) {
      return stored;
    }
    if (_isWeekend(key)) {
      return const AttendanceRecord(
        status: AttendanceStatus.rest,
        isAutomaticDefault: true,
      );
    }
    if (key.isBefore(today)) {
      return const AttendanceRecord(
        status: AttendanceStatus.absent,
        isAutoAbsent: true,
        isAutomaticDefault: true,
      );
    }
    return null;
  }

  AttendanceRecord? storedRecord(DateTime date) {
    return _repository.getByDate(dateOnly(date));
  }

  MonthSummary summaryForFocusedMonth() {
    var present = 0;
    var overtime = 0;
    var rest = 0;
    var halfDay = 0;
    var absent = 0;
    var unrecorded = 0;

    for (final date in daysInMonth(focusedMonth)) {
      final record = recordFor(date);
      switch (record?.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.overtime:
          overtime++;
          break;
        case AttendanceStatus.rest:
          rest++;
          break;
        case AttendanceStatus.halfDay:
          halfDay++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case null:
          unrecorded++;
          break;
      }
    }

    return MonthSummary(
      present: present,
      overtime: overtime,
      rest: rest,
      halfDay: halfDay,
      absent: absent,
      unrecorded: unrecorded,
    );
  }

  void selectTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    final key = dateOnly(date);
    selectedDate = key;
    focusedMonth = DateTime(key.year, key.month);
    notifyListeners();
  }

  void goToCalendarFor(DateTime date) {
    selectedDate = dateOnly(date);
    focusedMonth = DateTime(date.year, date.month);
    tabIndex = 1;
    notifyListeners();
  }

  void previousMonth() {
    focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1);
    selectedDate = DateTime(focusedMonth.year, focusedMonth.month);
    notifyListeners();
  }

  void nextMonth() {
    focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1);
    selectedDate = DateTime(focusedMonth.year, focusedMonth.month);
    notifyListeners();
  }

  Future<void> saveStatus(AttendanceStatus status, {DateTime? date}) async {
    final key = dateOnly(date ?? selectedDate);
    final previous = storedRecord(key);
    await _repository.save(
      key,
      AttendanceRecord(
        status: status,
        workSessions: previous?.workSessions ?? const <WorkSession>[],
        memo: previous?.memo ?? '',
      ),
    );
    selectedDate = key;
    focusedMonth = DateTime(key.year, key.month);
    lastMessage = '${formatShortDate(key)} ${status.label}으로 저장되었습니다';
    notifyListeners();
  }

  Future<void> saveDetail({
    required DateTime date,
    required AttendanceStatus status,
    required List<WorkSession> workSessions,
    required String memo,
  }) async {
    final key = dateOnly(date);
    await _repository.save(
      key,
      AttendanceRecord(
        status: status,
        workSessions: List<WorkSession>.unmodifiable(workSessions),
        memo: memo.trim(),
      ),
    );
    selectedDate = key;
    focusedMonth = DateTime(key.year, key.month);
    lastMessage = '${formatShortDate(key)} 기록을 수정했습니다';
    notifyListeners();
  }

  void clearLastMessage() {
    lastMessage = null;
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}
