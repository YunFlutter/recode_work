import 'package:flutter/material.dart';

import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/attendance_status.dart';
import '../../../../domain/models/month_summary.dart';
import '../../../core/date_formatters.dart';
import '../widgets/attendance_common_widgets.dart';

class TodayView extends StatelessWidget {
  const TodayView({
    super.key,
    required this.today,
    required this.record,
    required this.monthSummary,
    required this.onSaveStatus,
    required this.onEdit,
  });

  final DateTime today;
  final AttendanceRecord? record;
  final MonthSummary monthSummary;
  final Future<void> Function(AttendanceStatus status) onSaveStatus;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final status = record?.status;

    return ListView(
      children: [
        Text(
          formatFullDate(today),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        StatusPanel(record: record),
        const SizedBox(height: 18),
        SectionTitle(
          title: '오늘 기록',
          subtitle:
              status == null
                  ? '아래 큰 버튼 중 하나를 눌러 저장하세요.'
                  : '다시 누르면 오늘 기록을 바꿀 수 있습니다.',
        ),
        const SizedBox(height: 12),
        for (final statusOption in AttendanceStatus.values) ...[
          StatusActionButton(
            status: statusOption,
            filled: status == statusOption,
            onPressed: () => onSaveStatus(statusOption),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_calendar, size: 28),
          label: const Text('시간과 메모 수정'),
        ),
        const SizedBox(height: 20),
        MonthSummaryPanel(summary: monthSummary),
        const SizedBox(height: 10),
        const NoticeBox(
          text:
              '오늘보다 지난 날짜에 기록이 없으면 자동으로 결근으로 표시됩니다. 나중에 달력에서 날짜를 눌러 수정할 수 있습니다.',
        ),
      ],
    );
  }
}
