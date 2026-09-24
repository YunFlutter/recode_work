import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recode_works/data/repositories/attendance_repository.dart';
import 'package:recode_works/domain/models/attendance_record.dart';
import 'package:recode_works/domain/models/attendance_status.dart';
import 'package:recode_works/domain/models/month_summary.dart';
import 'package:recode_works/domain/models/work_session.dart';
import 'package:recode_works/main.dart';
import 'package:recode_works/ui/features/attendance/views/calendar_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(430, 900);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('shows the attendance app home screen', (tester) async {
    await tester.pumpWidget(AttendanceBookApp(today: DateTime(2026, 5, 5)));

    expect(find.text('출근 기록부'), findsOneWidget);
    expect(find.text('일반'), findsOneWidget);
    expect(find.text('큰글씨'), findsOneWidget);
    expect(find.text('2026년 5월 5일 화요일'), findsOneWidget);
    expect(find.text('아직 기록 전'), findsOneWidget);
    expect(find.text('출근함'), findsWidgets);
    expect(find.text('쉬는 날'), findsWidgets);
  });

  testWidgets('switches between normal and large text modes', (tester) async {
    await tester.pumpWidget(AttendanceBookApp(today: DateTime(2026, 5, 5)));

    expect(find.byKey(const ValueKey('largeTextModeView')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('largeTextModeButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('largeTextModeView')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('normalModeButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('largeTextModeView')), findsNothing);
  });

  testWidgets('saves today status and allows calendar editing', (tester) async {
    await tester.pumpWidget(AttendanceBookApp(today: DateTime(2026, 5, 5)));

    await tester.tap(find.text('출근함').first);
    await tester.pump();

    expect(find.text('저장되었습니다.'), findsOneWidget);

    await tester.tap(find.text('달력'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('calendarScrollView')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(find.text('현재 기록: 출근함'), findsOneWidget);
    expect(find.text('누르면 바로 저장됩니다.'), findsOneWidget);
  });

  testWidgets('past unrecorded dates are shown as automatic absences', (
    tester,
  ) async {
    await tester.pumpWidget(AttendanceBookApp(today: DateTime(2026, 5, 5)));

    await tester.tap(find.text('달력'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is CalendarDayButton && widget.date.day == 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('calendarScrollView')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(find.text('현재 기록: 결근 (자동 표시, 수정 가능)'), findsOneWidget);
  });

  testWidgets('weekend dates are shown as automatic rest days', (tester) async {
    await tester.pumpWidget(AttendanceBookApp(today: DateTime(2026, 5, 5)));

    await tester.tap(find.text('달력'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is CalendarDayButton && widget.date.day == 2,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('calendarScrollView')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(find.text('현재 기록: 쉬는 날 (자동 표시, 수정 가능)'), findsOneWidget);
  });

  testWidgets('record editor status choices save immediately', (tester) async {
    AttendanceStatus? savedStatus;
    bool? savedOvernight;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecordEditor(
              date: DateTime(2026, 5, 1),
              record: const AttendanceRecord(
                status: AttendanceStatus.overtime,
                isOvernight: true,
              ),
              onSave: ({
                required date,
                required status,
                required workSessions,
                required hasAdditionalShift,
                required isOvernight,
                required memo,
              }) async {
                savedStatus = status;
                savedOvernight = isOvernight;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('출근함'));
    await tester.pump();

    expect(savedStatus, AttendanceStatus.present);
    expect(savedOvernight, isFalse);
  });

  testWidgets('record editor exposes overtime and manual time selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecordEditor(
              date: DateTime(2026, 5, 1),
              record: const AttendanceRecord(
                status: AttendanceStatus.present,
                workSessions: <WorkSession>[WorkSession()],
              ),
              onSave:
                  ({
                    required date,
                    required status,
                    required workSessions,
                    required hasAdditionalShift,
                    required isOvernight,
                    required memo,
                  }) async {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('오후 추가 출근'), findsOneWidget);
    expect(find.text('다음날까지 야근'), findsOneWidget);

    final optionalTimeEditor = find.byKey(const ValueKey('optionalTimeEditor'));
    await tester.ensureVisible(optionalTimeEditor);
    await tester.tap(optionalTimeEditor);
    await tester.pumpAndSettle();

    expect(find.text('야근'), findsOneWidget);
    expect(find.text('시간 선택'), findsNWidgets(2));
  });

  testWidgets(
    'record editor adds multiple work sessions and saves each change',
    (tester) async {
      List<WorkSession>? savedWorkSessions;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecordEditor(
                date: DateTime(2026, 5, 1),
                record: const AttendanceRecord(
                  status: AttendanceStatus.present,
                ),
                onSave: ({
                  required date,
                  required status,
                  required workSessions,
                  required hasAdditionalShift,
                  required isOvernight,
                  required memo,
                }) async {
                  savedWorkSessions = List<WorkSession>.of(workSessions);
                },
              ),
            ),
          ),
        ),
      );

      final optionalTimeEditor = find.byKey(
        const ValueKey('optionalTimeEditor'),
      );
      await tester.ensureVisible(optionalTimeEditor);
      await tester.tap(optionalTimeEditor);
      await tester.pumpAndSettle();
      final addButton = find.byKey(const ValueKey('addWorkSessionButton'));
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pump();
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pump();

      expect(savedWorkSessions, hasLength(2));
      expect(find.text('근무 1'), findsOneWidget);
      expect(find.text('근무 2'), findsOneWidget);
    },
  );

  testWidgets('quick buttons save afternoon work and overnight work', (
    tester,
  ) async {
    AttendanceStatus? savedStatus;
    bool? savedAdditionalShift;
    bool? savedOvernight;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecordEditor(
              date: DateTime(2026, 5, 1),
              record: const AttendanceRecord(status: AttendanceStatus.absent),
              onSave: ({
                required date,
                required status,
                required workSessions,
                required hasAdditionalShift,
                required isOvernight,
                required memo,
              }) async {
                savedStatus = status;
                savedAdditionalShift = hasAdditionalShift;
                savedOvernight = isOvernight;
              },
            ),
          ),
        ),
      ),
    );

    final additionalButton = find.byKey(
      const ValueKey('additionalShiftButton'),
    );
    await tester.ensureVisible(additionalButton);
    await tester.tap(additionalButton);
    await tester.pump();

    expect(savedStatus, AttendanceStatus.present);
    expect(savedAdditionalShift, isTrue);
    expect(savedOvernight, isFalse);

    final overnightButton = find.byKey(const ValueKey('overnightButton'));
    await tester.ensureVisible(overnightButton);
    await tester.tap(overnightButton);
    await tester.pump();

    expect(savedStatus, AttendanceStatus.overtime);
    expect(savedAdditionalShift, isTrue);
    expect(savedOvernight, isTrue);
    expect(find.text('다음날까지 야근 기록됨'), findsOneWidget);
  });

  testWidgets('multiple work sessions tolerate narrow large-text layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1000),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: RecordEditor(
                date: DateTime(2026, 5, 1),
                record: const AttendanceRecord(
                  status: AttendanceStatus.present,
                  workSessions: <WorkSession>[
                    WorkSession(
                      startTime: TimeOfDay(hour: 8, minute: 0),
                      endTime: TimeOfDay(hour: 12, minute: 0),
                    ),
                    WorkSession(
                      startTime: TimeOfDay(hour: 13, minute: 0),
                      endTime: TimeOfDay(hour: 17, minute: 0),
                    ),
                  ],
                ),
                onSave:
                    ({
                      required date,
                      required status,
                      required workSessions,
                      required hasAdditionalShift,
                      required isOvernight,
                      required memo,
                    }) async {},
              ),
            ),
          ),
        ),
      ),
    );

    final optionalTimeEditor = find.byKey(const ValueKey('optionalTimeEditor'));
    await tester.ensureVisible(optionalTimeEditor);
    await tester.tap(optionalTimeEditor);
    await tester.pumpAndSettle();

    expect(find.text('근무 1'), findsOneWidget);
    expect(find.text('근무 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar layout tolerates large system text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(430, 900),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: CalendarView(
              today: DateTime(2026, 5, 5),
              focusedMonth: DateTime(2026, 5),
              selectedDate: DateTime(2026, 5, 5),
              recordFor: (date) {
                if (date.day == 5) {
                  return const AttendanceRecord(
                    status: AttendanceStatus.overtime,
                    hasAdditionalShift: true,
                    isOvernight: true,
                  );
                }
                if (date.weekday == DateTime.saturday ||
                    date.weekday == DateTime.sunday) {
                  return const AttendanceRecord(status: AttendanceStatus.rest);
                }
                if (date.isBefore(DateTime(2026, 5, 5))) {
                  return const AttendanceRecord(
                    status: AttendanceStatus.absent,
                  );
                }
                return null;
              },
              summary: const MonthSummary(
                present: 0,
                overtime: 0,
                rest: 10,
                halfDay: 0,
                absent: 2,
                unrecorded: 19,
              ),
              onPreviousMonth: () {},
              onNextMonth: () {},
              onSelectDate: (_) {},
              onSaveDetail:
                  ({
                    required date,
                    required status,
                    required workSessions,
                    required hasAdditionalShift,
                    required isOvernight,
                    required memo,
                  }) async {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('2026년 5월'), findsWidgets);
    expect(
      find.byKey(const ValueKey('calendarAdditional-2026-5-5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendarOvernight-2026-5-5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendarOvernightContinuation-2026-5-6')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendarAdditionalSummary-2026-5-5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendarOvernightSummary-2026-5-5')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('overnight work stays linked across a month boundary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            today: DateTime(2026, 6, 1),
            focusedMonth: DateTime(2026, 6),
            selectedDate: DateTime(2026, 6, 1),
            recordFor:
                (date) =>
                    date.year == 2026 && date.month == 5 && date.day == 31
                        ? const AttendanceRecord(
                          status: AttendanceStatus.overtime,
                          isOvernight: true,
                        )
                        : null,
            summary: const MonthSummary(
              present: 0,
              overtime: 0,
              rest: 0,
              halfDay: 0,
              absent: 0,
              unrecorded: 30,
            ),
            onPreviousMonth: () {},
            onNextMonth: () {},
            onSelectDate: (_) {},
            onSaveDetail:
                ({
                  required date,
                  required status,
                  required workSessions,
                  required hasAdditionalShift,
                  required isOvernight,
                  required memo,
                }) async {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('calendarOvernightContinuation-2026-6-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('persists saved records in local preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = await SharedPreferencesAttendanceRepository.create();

    await repository.save(
      DateTime(2026, 5, 1),
      const AttendanceRecord(
        status: AttendanceStatus.present,
        workSessions: <WorkSession>[
          WorkSession(
            startTime: TimeOfDay(hour: 8, minute: 0),
            endTime: TimeOfDay(hour: 12, minute: 0),
          ),
          WorkSession(
            startTime: TimeOfDay(hour: 13, minute: 0),
            endTime: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        hasAdditionalShift: true,
        isOvernight: true,
        memo: '수정 저장',
      ),
    );

    final reloadedRepository =
        await SharedPreferencesAttendanceRepository.create();
    final saved = reloadedRepository.getByDate(DateTime(2026, 5, 1));

    expect(saved?.status, AttendanceStatus.present);
    expect(saved?.workSessions, hasLength(2));
    expect(saved?.hasAdditionalShift, isTrue);
    expect(saved?.isOvernight, isTrue);
    expect(saved?.memo, '수정 저장');
  });
}
