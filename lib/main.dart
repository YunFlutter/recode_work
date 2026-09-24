import 'package:flutter/material.dart';

import 'data/repositories/attendance_repository.dart';
import 'data/repositories/attendance_repository_factory.dart';
import 'ui/core/app_theme.dart';
import 'ui/features/attendance/view_models/attendance_view_model.dart';
import 'ui/features/attendance/views/attendance_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await AttendanceRepositoryFactory.create();
  runApp(AttendanceBookApp(repository: repository));
}

class AttendanceBookApp extends StatelessWidget {
  const AttendanceBookApp({super.key, this.today, this.repository});

  final DateTime? today;
  final AttendanceRepository? repository;

  @override
  Widget build(BuildContext context) {
    final viewModel = AttendanceViewModel(
      repository: repository ?? InMemoryAttendanceRepository(),
      today: today,
    );

    return MaterialApp(
      title: '출근 기록부',
      debugShowCheckedModeBanner: false,
      theme: buildAttendanceTheme(),
      home: AttendanceHomePage(viewModel: viewModel),
    );
  }
}
