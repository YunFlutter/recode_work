import 'package:flutter/material.dart';

import '../../../core/date_formatters.dart';
import '../view_models/attendance_view_model.dart';
import 'calendar_view.dart';
import 'large_text_attendance_view.dart';
import 'summary_view.dart';
import 'today_view.dart';

class AttendanceHomePage extends StatelessWidget {
  const AttendanceHomePage({super.key, required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        _showLastMessage(context);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final systemPrefersLargeText =
                MediaQuery.textScalerOf(context).scale(1) >= 1.8;
            final useLargeTextMode = viewModel.shouldUseLargeTextMode(
              systemPrefersLargeText,
            );

            return Scaffold(
              appBar: AppBar(
                toolbarHeight: _toolbarHeight(context),
                title: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('출근 기록부'),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatMonth(viewModel.focusedMonth),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(66),
                  child: _ModeSwitchBar(
                    useLargeTextMode: useLargeTextMode,
                    onChanged: viewModel.setLargeTextMode,
                  ),
                ),
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1040 : 560),
                  child:
                      useLargeTextMode
                          ? LargeTextAttendanceView(
                            key: const ValueKey('largeTextModeView'),
                            viewModel: viewModel,
                          )
                          : isWide
                          ? _WideBody(viewModel: viewModel)
                          : _CompactBody(viewModel: viewModel),
                ),
              ),
              bottomNavigationBar:
                  isWide ? null : _BottomNavigation(viewModel: viewModel),
            );
          },
        );
      },
    );
  }

  void _showLastMessage(BuildContext context) {
    final message = viewModel.lastMessage;
    if (message == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontSize: 18)),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      viewModel.clearLastMessage();
    });
  }
}

double _toolbarHeight(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  return (64 * textScale).clamp(64, 96).toDouble();
}

class _ModeSwitchBar extends StatelessWidget {
  const _ModeSwitchBar({
    required this.useLargeTextMode,
    required this.onChanged,
  });

  final bool useLargeTextMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                key: const ValueKey('normalModeButton'),
                icon: Icons.view_agenda,
                label: '일반',
                selected: !useLargeTextMode,
                onPressed: () => onChanged(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeButton(
                key: const ValueKey('largeTextModeButton'),
                icon: Icons.text_increase,
                label: '큰글씨',
                selected: useLargeTextMode,
                onPressed: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style =
        selected
            ? FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            )
            : OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: Colors.white,
            );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label))),
      ],
    );

    if (selected) {
      return FilledButton(onPressed: onPressed, style: style, child: child);
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody({required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 264,
          child: NavigationRail(
            selectedIndex: viewModel.tabIndex,
            minWidth: 96,
            minExtendedWidth: 244,
            extended: true,
            labelType: NavigationRailLabelType.none,
            onDestinationSelected: viewModel.selectTab,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.today),
                selectedIcon: Icon(Icons.today),
                label: Text('오늘'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('달력'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('요약'),
              ),
            ],
          ),
        ),
        Expanded(child: _TabBody(viewModel: viewModel)),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _TabBody(viewModel: viewModel);
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.viewModel});

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
            TodayView(
              today: viewModel.today,
              record: viewModel.recordFor(viewModel.today),
              monthSummary: summary,
              onSaveStatus:
                  (status) =>
                      viewModel.saveStatus(status, date: viewModel.today),
              onEdit: () => viewModel.goToCalendarFor(viewModel.today),
            ),
            CalendarView(
              today: viewModel.today,
              focusedMonth: viewModel.focusedMonth,
              selectedDate: viewModel.selectedDate,
              recordFor: viewModel.recordFor,
              summary: summary,
              onPreviousMonth: viewModel.previousMonth,
              onNextMonth: viewModel.nextMonth,
              onSelectDate: viewModel.selectDate,
              onSaveDetail: viewModel.saveDetail,
            ),
            SummaryView(
              month: viewModel.focusedMonth,
              summary: summary,
              recordFor: viewModel.recordFor,
              onSelectDate: viewModel.goToCalendarFor,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: viewModel.tabIndex,
      onTap: viewModel.selectTab,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.today, size: 30), label: '오늘'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month, size: 30),
          label: '달력',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart, size: 30),
          label: '요약',
        ),
      ],
    );
  }
}
