import 'package:flutter/material.dart';

import '../../../../domain/models/attendance_record.dart';
import '../../../../domain/models/attendance_status.dart';
import '../../../../domain/models/month_summary.dart';

class AttendancePanel extends StatelessWidget {
  const AttendancePanel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFE5E7EB),
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, required this.record});

  final AttendanceRecord? record;

  @override
  Widget build(BuildContext context) {
    final status = record?.status;
    final color = status?.color ?? const Color(0xFF2563EB);

    return AttendancePanel(
      color:
          status == null
              ? const Color(0xFFEFF6FF)
              : color.withValues(alpha: 0.12),
      borderColor: status == null ? const Color(0xFF93C5FD) : color,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final useVerticalLayout =
              constraints.maxWidth < 430 || textScale >= 1.45;

          final icon = CircleAvatar(
            radius: useVerticalLayout ? 28 : 32,
            backgroundColor: color,
            child: Icon(
              status?.icon ?? Icons.edit_calendar,
              color: Colors.white,
              size: useVerticalLayout ? 32 : 36,
            ),
          );
          final textContent = Column(
            crossAxisAlignment:
                useVerticalLayout
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
            children: [
              Text(
                status == null ? '아직 기록 전' : status.label,
                textAlign:
                    useVerticalLayout ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: status == null ? const Color(0xFF1E3A8A) : color,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record?.isAutomaticDefault == true
                    ? '자동으로 표시되었습니다. 수정할 수 있습니다.'
                    : status == null
                    ? '오늘 기록은 아직 결근 처리되지 않습니다.'
                    : '저장되었습니다.',
                textAlign:
                    useVerticalLayout ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

          if (useVerticalLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: icon),
                const SizedBox(height: 12),
                textContent,
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 16),
              Expanded(child: textContent),
            ],
          );
        },
      ),
    );
  }
}

class StatusActionButton extends StatelessWidget {
  const StatusActionButton({
    super.key,
    required this.status,
    required this.filled,
    required this.onPressed,
  });

  final AttendanceStatus status;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: status.color),
        icon: Icon(status.icon, size: 30),
        label: Text(status.label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: status.color),
      icon: Icon(status.icon, size: 30),
      label: Text(status.label),
    );
  }
}

class MonthSummaryPanel extends StatelessWidget {
  const MonthSummaryPanel({super.key, required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    return AttendancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '이번 달 현황',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SummaryChip(
                label: '출근',
                value: summary.present,
                color: AttendanceStatus.present.color,
              ),
              SummaryChip(
                label: '야근',
                value: summary.overtime,
                color: AttendanceStatus.overtime.color,
              ),
              SummaryChip(
                label: '결근',
                value: summary.absent,
                color: AttendanceStatus.absent.color,
              ),
              SummaryChip(
                label: '쉬는 날',
                value: summary.rest,
                color: AttendanceStatus.rest.color,
              ),
              SummaryChip(
                label: '반차',
                value: summary.halfDay,
                color: AttendanceStatus.halfDay.color,
              ),
              SummaryChip(
                label: '미기록',
                value: summary.unrecorded,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryChip extends StatelessWidget {
  const SummaryChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        '$label $value일',
        maxLines: 2,
        overflow: TextOverflow.visible,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class NoticeBox extends StatelessWidget {
  const NoticeBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    );
  }
}
