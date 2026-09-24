import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/attendance_status.dart';
import '../../../../domain/models/month_summary.dart';
import '../../../../domain/models/work_session.dart';
import '../../../core/date_formatters.dart';
import '../widgets/attendance_common_widgets.dart';
import '../widgets/work_sessions_editor.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.today,
    required this.focusedMonth,
    required this.selectedDate,
    required this.recordFor,
    required this.summary,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
    required this.onSaveDetail,
  });

  final DateTime today;
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final AttendanceRecord? Function(DateTime date) recordFor;
  final MonthSummary summary;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;
  final Future<void> Function({
    required DateTime date,
    required AttendanceStatus status,
    required List<WorkSession> workSessions,
    required String memo,
  })
  onSaveDetail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: '이전 달',
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left, size: 34),
            ),
            Expanded(
              child: Text(
                formatMonth(focusedMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: '다음 달',
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right, size: 34),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CalendarGrid(
          month: focusedMonth,
          today: today,
          selectedDate: selectedDate,
          recordFor: recordFor,
          onSelectDate: onSelectDate,
        ),
        const SizedBox(height: 16),
        RecordEditor(
          key: ValueKey<DateTime>(selectedDate),
          date: selectedDate,
          record: recordFor(selectedDate),
          onSave: onSaveDetail,
        ),
        const SizedBox(height: 16),
        MonthSummaryPanel(summary: summary),
      ],
    );
  }
}

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.today,
    required this.selectedDate,
    required this.recordFor,
    required this.onSelectDate,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selectedDate;
  final AttendanceRecord? Function(DateTime date) recordFor;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month);
    final leadingBlanks = firstDay.weekday % 7;
    final days = daysInMonth(month);
    final itemCount = leadingBlanks + days.length;

    return Column(
      children: [
        const Row(
          children: [
            WeekdayLabel('일'),
            WeekdayLabel('월'),
            WeekdayLabel('화'),
            WeekdayLabel('수'),
            WeekdayLabel('목'),
            WeekdayLabel('금'),
            WeekdayLabel('토'),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            mainAxisExtent: _calendarCellHeight(context),
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) {
              return const SizedBox.shrink();
            }

            final date = days[index - leadingBlanks];
            return CalendarDayButton(
              date: date,
              record: recordFor(date),
              isSelected: isSameDate(date, selectedDate),
              isToday: isSameDate(date, today),
              onPressed: () => onSelectDate(date),
            );
          },
        ),
      ],
    );
  }
}

class CalendarDayButton extends StatelessWidget {
  const CalendarDayButton({
    super.key,
    required this.date,
    required this.record,
    required this.isSelected,
    required this.isToday,
    required this.onPressed,
  });

  final DateTime date;
  final AttendanceRecord? record;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final statusColor = record?.status.color ?? const Color(0xFFE5E7EB);
    final foreground = record == null ? const Color(0xFF1F2937) : Colors.white;

    return Semantics(
      button: true,
      label: '${date.day}일 ${record?.status.label ?? '미기록'}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: record == null ? Colors.white : statusColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF111827)
                      : isToday
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFD1D5DB),
              width: isSelected ? 3 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${date.day}',
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    record?.status.label ?? (isToday ? '오늘' : '미기록'),
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordEditor extends StatefulWidget {
  const RecordEditor({
    super.key,
    required this.date,
    required this.record,
    required this.onSave,
  });

  final DateTime date;
  final AttendanceRecord? record;
  final Future<void> Function({
    required DateTime date,
    required AttendanceStatus status,
    required List<WorkSession> workSessions,
    required String memo,
  })
  onSave;

  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  late AttendanceStatus _status =
      widget.record?.status ?? AttendanceStatus.present;
  late List<WorkSession> _workSessions = List<WorkSession>.of(
    widget.record?.workSessions ?? const <WorkSession>[],
  );
  late final TextEditingController _memoController = TextEditingController(
    text: widget.record?.memo ?? '',
  );
  Timer? _memoSaveTimer;

  @override
  void dispose() {
    _memoSaveTimer?.cancel();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveNow() async {
    await widget.onSave(
      date: widget.date,
      status: _status,
      workSessions: _workSessions,
      memo: _memoController.text,
    );
  }

  void _saveMemoSoon() {
    _memoSaveTimer?.cancel();
    _memoSaveTimer = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  Future<void> _updateWorkSessions(List<WorkSession> workSessions) async {
    setState(() => _workSessions = List<WorkSession>.of(workSessions));
    await _saveNow();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return AttendancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatFullDate(widget.date),
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            record == null
                ? '현재 기록: 미기록'
                : record.isAutomaticDefault
                ? '현재 기록: ${record.status.label} (자동 표시, 수정 가능)'
                : '현재 기록: ${record.status.label}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            '기록 변경',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            '누르면 바로 저장됩니다.',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                AttendanceStatus.values.map((status) {
                  final selected = status == _status;
                  return ChoiceChip(
                    selected: selected,
                    avatar: Icon(
                      status.icon,
                      color: selected ? Colors.white : status.color,
                    ),
                    label: Text(status.label),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF1E2A24),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: status.color,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: status.color, width: 1.4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _status = status);
                      _saveNow();
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 18),
          WorkSessionsEditor(
            sessions: _workSessions,
            onChanged: _updateWorkSessions,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _memoController,
            onChanged: (_) => _saveMemoSoon(),
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              labelText: '메모',
              hintText: '예: 병원 다녀옴',
              labelStyle: const TextStyle(fontSize: 19),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const NoticeBox(text: '상태, 시간, 메모를 바꾸면 자동으로 저장됩니다.'),
        ],
      ),
    );
  }
}

double _calendarCellHeight(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  return (70 * textScale).clamp(70, 132).toDouble();
}

class WeekdayLabel extends StatelessWidget {
  const WeekdayLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color:
              label == '일'
                  ? AttendanceStatus.absent.color
                  : const Color(0xFF374151),
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
