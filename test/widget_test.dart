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

    expect(find.text('현재 기록: 쉬는 날 (자동 표시, 수정 가능)'), findsOneWidget);
  });

  testWidgets('record editor status choices save immediately', (tester) async {
    AttendanceStatus? savedStatus;

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
                required memo,
              }) async {
                savedStatus = status;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('출근함'));
    await tester.pump();

    expect(savedStatus, AttendanceStatus.present);
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
                    required memo,
                  }) async {},
            ),
          ),
        ),
      ),
    );

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
                  required memo,
                }) async {
                  savedWorkSessions = List<WorkSession>.of(workSessions);
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('addWorkSessionButton')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('addWorkSessionButton')));
      await tester.pump();

      expect(savedWorkSessions, hasLength(2));
      expect(find.text('근무 1'), findsOneWidget);
      expect(find.text('근무 2'), findsOneWidget);
    },
  );

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
                      required memo,
                    }) async {},
              ),
            ),
          ),
        ),
      ),
    );

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
                    required memo,
                  }) async {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('2026년 5월'), findsWidgets);
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
        memo: '수정 저장',
      ),
    );

    final reloadedRepository =
        await SharedPreferencesAttendanceRepository.create();
    final saved = reloadedRepository.getByDate(DateTime(2026, 5, 1));

    expect(saved?.status, AttendanceStatus.present);
    expect(saved?.workSessions, hasLength(2));
    expect(saved?.memo, '수정 저장');
  });
}
