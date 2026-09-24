import 'package:flutter/material.dart';

import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/month_summary.dart';
import '../../../core/date_formatters.dart';
import '../widgets/attendance_common_widgets.dart';

class SummaryView extends StatelessWidget {
  const SummaryView({
    super.key,
    required this.month,
    required this.summary,
    required this.recordFor,
    required this.onSelectDate,
  });

  final DateTime month;
  final MonthSummary summary;
  final AttendanceRecord? Function(DateTime date) recordFor;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final days = daysInMonth(month);

    return ListView(
      children: [
        Text(
          '${formatMonth(month)} 요약',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        MonthSummaryPanel(summary: summary),
        const SizedBox(height: 16),
        const SectionTitle(
          title: '날짜별 기록',
          subtitle: '자동 결근으로 표시된 날짜도 눌러서 수정할 수 있습니다.',
        ),
        const SizedBox(height: 8),
        ...days.map((date) {
          final record = recordFor(date);
          final label = record?.status.label ?? '미기록';
          final color = record?.status.color ?? const Color(0xFF6B7280);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => onSelectDate(date),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: color.withValues(alpha: 0.35)),
              ),
              tileColor: Colors.white,
              minVerticalPadding: 14,
              leading: CircleAvatar(
                backgroundColor: color,
                child: Icon(
                  record?.status.icon ?? Icons.help_outline,
                  color: Colors.white,
                ),
              ),
              title: Text(
                formatShortDate(date),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                record?.isAutomaticDefault == true ? '$label - 자동 표시' : label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
            ),
          );
        }),
      ],
    );
  }
}
