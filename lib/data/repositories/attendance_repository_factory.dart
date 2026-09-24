import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../services/attendance_remote_data_source.dart';
import '../services/device_identifier_service.dart';
import 'attendance_repository.dart';
import 'syncing_attendance_repository.dart';

class AttendanceRepositoryFactory {
  const AttendanceRepositoryFactory._();

  static Future<AttendanceRepository> create() async {
    final localRepository =
        await SharedPreferencesAttendanceRepository.create();

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return localRepository;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }

      final deviceKey = await DeviceIdentifierService().getDeviceKey();
      final repository = SyncingAttendanceRepository(
        localRepository: localRepository,
        remoteDataSource: FirestoreAttendanceRemoteDataSource(
          firestore: FirebaseFirestore.instance,
        ),
        deviceKey: deviceKey,
        onSyncError: _logSyncError,
      );

      try {
        await repository.synchronize();
      } catch (error, stackTrace) {
        _logSyncError(error, stackTrace);
      }
      return repository;
    } catch (error, stackTrace) {
      _logSyncError(error, stackTrace);
      return localRepository;
    }
  }

  static void _logSyncError(Object error, StackTrace stackTrace) {
    debugPrint('Firebase 출근 기록 동기화 실패: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
