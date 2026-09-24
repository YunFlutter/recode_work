import 'package:flutter/material.dart';

import '../../../../domain/models/work_session.dart';
import '../../../core/date_formatters.dart';
import 'attendance_common_widgets.dart';

const int maxDailyWorkSessions = 10;

class WorkSessionsEditor extends StatelessWidget {
  const WorkSessionsEditor({
    super.key,
    required this.sessions,
    required this.onChanged,
    this.largeText = false,
  });

  final List<WorkSession> sessions;
  final Future<void> Function(List<WorkSession> sessions) onChanged;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final titleSize = largeText ? 24.0 : 20.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '근무 시간',
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          sessions.isEmpty
              ? '근무한 횟수만큼 시간을 추가하세요.'
              : '근무 ${sessions.length}회가 기록되어 있습니다.',
          style: TextStyle(
            fontSize: largeText ? 20 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < sessions.length; index++) ...[
          _WorkSessionCard(
            index: index,
            session: sessions[index],
            largeText: largeText,
            onPickStart: () => _pickTime(context, index, isStart: true),
            onPickEnd: () => _pickTime(context, index, isStart: false),
            onUseNowStart:
                () => _replaceTime(index, isStart: true, TimeOfDay.now()),
            onUseNowEnd:
                () => _replaceTime(index, isStart: false, TimeOfDay.now()),
            onClearStart: () => _replaceTime(index, isStart: true, null),
            onClearEnd: () => _replaceTime(index, isStart: false, null),
            onDelete: () => _remove(index),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          key: const ValueKey('addWorkSessionButton'),
          onPressed:
              sessions.length >= maxDailyWorkSessions ? null : _addSession,
          icon: const Icon(Icons.add_alarm, size: 28),
          label: Text(
            sessions.length >= maxDailyWorkSessions
                ? '하루 최대 $maxDailyWorkSessions회'
                : '근무 시간 추가',
          ),
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(largeText ? 64 : 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: TextStyle(
              fontSize: largeText ? 22 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addSession() async {
    await onChanged(<WorkSession>[...sessions, const WorkSession()]);
  }

  Future<void> _remove(int index) async {
    final updated = List<WorkSession>.of(sessions)..removeAt(index);
    await onChanged(updated);
  }

  Future<void> _pickTime(
    BuildContext context,
    int index, {
    required bool isStart,
  }) async {
    final session = sessions[index];
    final current = isStart ? session.startTime : session.endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }
    await _replaceTime(index, isStart: isStart, picked);
  }

  Future<void> _replaceTime(
    int index,
    TimeOfDay? time, {
    required bool isStart,
  }) async {
    final current = sessions[index];
    final updated = List<WorkSession>.of(sessions);
    updated[index] = WorkSession(
      startTime: isStart ? time : current.startTime,
      endTime: isStart ? current.endTime : time,
    );
    await onChanged(updated);
  }
}

class _WorkSessionCard extends StatelessWidget {
  const _WorkSessionCard({
    required this.index,
    required this.session,
    required this.largeText,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onUseNowStart,
    required this.onUseNowEnd,
    required this.onClearStart,
    required this.onClearEnd,
    required this.onDelete,
  });

  final int index;
  final WorkSession session;
  final bool largeText;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onUseNowStart;
  final VoidCallback onUseNowEnd;
  final VoidCallback onClearStart;
  final VoidCallback onClearEnd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AttendancePanel(
      color: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFF59E0B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '근무 ${index + 1}',
                  style: TextStyle(
                    fontSize: largeText ? 23 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                key: ValueKey('deleteWorkSessionButton$index'),
                tooltip: '근무 ${index + 1} 삭제',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final useColumns = constraints.maxWidth >= 620 && textScale < 1.4;
              final startControl = _SessionTimeControl(
                label: '출근 시간',
                time: session.startTime,
                largeText: largeText,
                onPick: onPickStart,
                onUseNow: onUseNowStart,
                onClear: onClearStart,
              );
              final endControl = _SessionTimeControl(
                label: '퇴근 시간',
                time: session.endTime,
                largeText: largeText,
                onPick: onPickEnd,
                onUseNow: onUseNowEnd,
                onClear: onClearEnd,
              );

              if (useColumns) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: startControl),
                    const SizedBox(width: 12),
                    Expanded(child: endControl),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  startControl,
                  const SizedBox(height: 14),
                  endControl,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionTimeControl extends StatelessWidget {
  const _SessionTimeControl({
    required this.label,
    required this.time,
    required this.largeText,
    required this.onPick,
    required this.onUseNow,
    required this.onClear,
  });

  final String label;
  final TimeOfDay? time;
  final bool largeText;
  final VoidCallback onPick;
  final VoidCallback onUseNow;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$label: ${time == null ? '없음' : formatTime(time!)}',
          style: TextStyle(
            fontSize: largeText ? 21 : 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SessionActionButton(
              label: '시간 선택',
              icon: Icons.edit_calendar,
              largeText: largeText,
              onPressed: onPick,
            ),
            _SessionActionButton(
              label: '현재 시간',
              icon: Icons.access_time,
              largeText: largeText,
              onPressed: onUseNow,
            ),
            _SessionActionButton(
              label: '비움',
              largeText: largeText,
              onPressed: onClear,
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionActionButton extends StatelessWidget {
  const _SessionActionButton({
    required this.label,
    required this.largeText,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool largeText;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(largeText ? 150 : 120, largeText ? 56 : 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: TextStyle(
          fontSize: largeText ? 19 : 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
