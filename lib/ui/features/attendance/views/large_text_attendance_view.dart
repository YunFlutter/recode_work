import 'package:flutter/material.dart';

import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/attendance_status.dart';
import '../../../../domain/models/work_session.dart';
import '../../../core/date_formatters.dart';
import '../view_models/attendance_view_model.dart';
import '../widgets/attendance_common_widgets.dart';
import '../widgets/work_sessions_editor.dart';

class LargeTextAttendanceView extends StatelessWidget {
  const LargeTextAttendanceView({super.key, required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final summary = viewModel.summaryForFocusedMonth();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: IndexedStack(
          index: viewModel.tabIndex,
          children: [
            _LargeTodayPage(viewModel: viewModel),
            _LargeDateListPage(viewModel: viewModel),
            ListView(
              children: [
                Text(
                  '${formatMonth(viewModel.focusedMonth)} 요약',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                MonthSummaryPanel(summary: summary),
                const SizedBox(height: 20),
                const NoticeBox(text: '큰 글씨 모드에서는 핵심 정보만 크게 보여줍니다.'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeTodayPage extends StatelessWidget {
  const _LargeTodayPage({required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final record = viewModel.recordFor(viewModel.today);

    return ListView(
      children: [
        Text(
          formatFullDate(viewModel.today),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        StatusPanel(record: record),
        const SizedBox(height: 18),
        const Text(
          '오늘 기록',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (final status in AttendanceStatus.values) ...[
          StatusActionButton(
            status: status,
            filled: record?.status == status,
            onPressed:
                () => viewModel.saveStatus(status, date: viewModel.today),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        _LargeWorkSessionsEditor(
          viewModel: viewModel,
          date: viewModel.today,
          record: record,
        ),
      ],
    );
  }
}

class _LargeDateListPage extends StatelessWidget {
  const _LargeDateListPage({required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selectedRecord = viewModel.recordFor(viewModel.selectedDate);

    return ListView(
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: '이전 달',
              onPressed: viewModel.previousMonth,
              icon: const Icon(Icons.chevron_left, size: 34),
            ),
            Expanded(
              child: Text(
                formatMonth(viewModel.focusedMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: '다음 달',
              onPressed: viewModel.nextMonth,
              icon: const Icon(Icons.chevron_right, size: 34),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AttendancePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatFullDate(viewModel.selectedDate),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _recordLabel(selectedRecord),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final status in AttendanceStatus.values) ...[
                StatusActionButton(
                  status: status,
                  filled: selectedRecord?.status == status,
                  onPressed: () => viewModel.saveStatus(status),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              _LargeWorkSessionsEditor(
                viewModel: viewModel,
                date: viewModel.selectedDate,
                record: selectedRecord,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '날짜 선택',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (final date in daysInMonth(viewModel.focusedMonth))
          _LargeDateTile(
            date: date,
            record: viewModel.recordFor(date),
            selected: isSameDate(date, viewModel.selectedDate),
            onTap: () => viewModel.selectDate(date),
          ),
      ],
    );
  }

  String _recordLabel(AttendanceRecord? record) {
    if (record == null) {
      return '현재 기록: 미기록';
    }
    if (record.isAutomaticDefault) {
      return '현재 기록: ${record.status.label} (자동 표시)';
    }
    return '현재 기록: ${record.status.label}';
  }
}

class _LargeWorkSessionsEditor extends StatelessWidget {
  const _LargeWorkSessionsEditor({
    required this.viewModel,
    required this.date,
    required this.record,
  });

  final AttendanceViewModel viewModel;
  final DateTime date;
  final AttendanceRecord? record;

  @override
  Widget build(BuildContext context) {
    return AttendancePanel(
      child: WorkSessionsEditor(
        sessions: record?.workSessions ?? const <WorkSession>[],
        largeText: true,
        onChanged:
            (workSessions) => viewModel.saveDetail(
              date: date,
              status: record?.status ?? AttendanceStatus.present,
              workSessions: workSessions,
              memo: record?.memo ?? '',
            ),
      ),
    );
  }
}

class _LargeDateTile extends StatelessWidget {
  const _LargeDateTile({
    required this.date,
    required this.record,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final AttendanceRecord? record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = record?.status;
    final color = status?.color ?? const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 18,
        tileColor: selected ? color.withValues(alpha: 0.12) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? color : const Color(0xFFD1D5DB),
            width: selected ? 2.5 : 1.2,
          ),
        ),
        title: Text(
          formatFullDate(date),
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          record?.isAutomaticDefault == true
              ? '${status!.label} - 자동 표시'
              : status?.label ?? '미기록',
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
