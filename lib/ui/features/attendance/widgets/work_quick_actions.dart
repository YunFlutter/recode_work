import 'package:flutter/material.dart';

class WorkQuickActions extends StatelessWidget {
  const WorkQuickActions({
    super.key,
    required this.hasAdditionalShift,
    required this.isOvernight,
    required this.onChanged,
    this.largeText = false,
  });

  final bool hasAdditionalShift;
  final bool isOvernight;
  final Future<void> Function({
    required bool hasAdditionalShift,
    required bool isOvernight,
  })
  onChanged;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '빠른 근무 기록',
          style: TextStyle(
            fontSize: largeText ? 25 : 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '해당하는 버튼을 누르면 바로 저장됩니다.',
          style: TextStyle(
            fontSize: largeText ? 20 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final useRow = constraints.maxWidth >= 620 && textScale < 1.4;
            final additionalButton = _QuickRecordButton(
              key: const ValueKey('additionalShiftButton'),
              icon: Icons.wb_sunny_outlined,
              label: '오후 추가 출근',
              selectedLabel: '오후 추가 출근 기록됨',
              description: '오후에 다시 출근했을 때 누르세요.',
              selected: hasAdditionalShift,
              largeText: largeText,
              color: const Color(0xFF2563EB),
              onPressed:
                  () => onChanged(
                    hasAdditionalShift: !hasAdditionalShift,
                    isOvernight: isOvernight,
                  ),
            );
            final overnightButton = _QuickRecordButton(
              key: const ValueKey('overnightButton'),
              icon: Icons.dark_mode_outlined,
              label: '다음날까지 야근',
              selectedLabel: '다음날까지 야근 기록됨',
              description: '자정을 지나 다음날까지 일했을 때 누르세요.',
              selected: isOvernight,
              largeText: largeText,
              color: const Color(0xFF7C3AED),
              onPressed:
                  () => onChanged(
                    hasAdditionalShift: hasAdditionalShift,
                    isOvernight: !isOvernight,
                  ),
            );

            if (useRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: additionalButton),
                  const SizedBox(width: 12),
                  Expanded(child: overnightButton),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                additionalButton,
                const SizedBox(height: 12),
                overnightButton,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickRecordButton extends StatelessWidget {
  const _QuickRecordButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selectedLabel,
    required this.description,
    required this.selected,
    required this.largeText,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String selectedLabel;
  final String description;
  final bool selected;
  final bool largeText;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : color;
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: largeText ? 38 : 32, color: foreground),
          const SizedBox(height: 8),
          Text(
            selected ? selectedLabel : label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: largeText ? 22 : 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selected ? '다시 누르면 취소됩니다.' : description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: largeText ? 18 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size.fromHeight(largeText ? 142 : 124),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return Semantics(
      toggled: selected,
      button: true,
      child:
          selected
              ? FilledButton(
                onPressed: onPressed,
                style: style.copyWith(
                  backgroundColor: WidgetStatePropertyAll(color),
                ),
                child: child,
              )
              : OutlinedButton(
                onPressed: onPressed,
                style: style.copyWith(
                  side: WidgetStatePropertyAll(
                    BorderSide(color: color, width: 2),
                  ),
                ),
                child: child,
              ),
    );
  }
}
