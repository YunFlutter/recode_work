import 'package:flutter_test/flutter_test.dart';
import 'package:recode_works/data/repositories/attendance_repository.dart';
import 'package:recode_works/data/repositories/syncing_attendance_repository.dart';
import 'package:recode_works/data/services/attendance_remote_data_source.dart';
import 'package:recode_works/domain/models/attendance_record.dart';
import 'package:recode_works/domain/models/attendance_status.dart';

void main() {
  test('동기화할 때 로컬 기록을 우선하고 원격 전용 기록은 복원한다', () async {
    final local = InMemoryAttendanceRepository();
    await local.save(
      DateTime(2026, 5, 1),
      const AttendanceRecord(status: AttendanceStatus.present),
    );
    final remote = _FakeAttendanceRemoteDataSource(
      records: <DateTime, AttendanceRecord>{
        DateTime(2026, 5, 1): const AttendanceRecord(
          status: AttendanceStatus.absent,
        ),
        DateTime(2026, 5, 2): const AttendanceRecord(
          status: AttendanceStatus.rest,
        ),
      },
    );
    final repository = SyncingAttendanceRepository(
      localRepository: local,
      remoteDataSource: remote,
      deviceKey: 'android_test',
    );

    await repository.synchronize();

    expect(
      repository.getByDate(DateTime(2026, 5, 1))?.status,
      AttendanceStatus.present,
    );
    expect(
      repository.getByDate(DateTime(2026, 5, 2))?.status,
      AttendanceStatus.rest,
    );
    expect(
      remote.uploadedRecords[DateTime(2026, 5, 1)]?.status,
      AttendanceStatus.present,
    );
    expect(remote.lastDeviceKey, 'android_test');
  });

  test('원격 저장 실패에도 로컬 기록은 유지한다', () async {
    final local = InMemoryAttendanceRepository();
    final remote = _FakeAttendanceRemoteDataSource(throwOnSave: true);
    Object? syncError;
    final repository = SyncingAttendanceRepository(
      localRepository: local,
      remoteDataSource: remote,
      deviceKey: 'android_test',
      onSyncError: (error, _) => syncError = error,
    );

    await repository.save(
      DateTime(2026, 5, 3),
      const AttendanceRecord(status: AttendanceStatus.halfDay),
    );

    expect(
      repository.getByDate(DateTime(2026, 5, 3))?.status,
      AttendanceStatus.halfDay,
    );
    expect(syncError, isA<StateError>());
  });
}

class _FakeAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  _FakeAttendanceRemoteDataSource({
    Map<DateTime, AttendanceRecord>? records,
    this.throwOnSave = false,
  }) : records = records ?? <DateTime, AttendanceRecord>{};

  final Map<DateTime, AttendanceRecord> records;
  final bool throwOnSave;
  Map<DateTime, AttendanceRecord> uploadedRecords =
      <DateTime, AttendanceRecord>{};
  String? lastDeviceKey;

  @override
  Future<Map<DateTime, AttendanceRecord>> fetchAll({
    required String deviceKey,
  }) async {
    lastDeviceKey = deviceKey;
    return Map<DateTime, AttendanceRecord>.from(records);
  }

  @override
  Future<void> save({
    required String deviceKey,
    required DateTime date,
    required AttendanceRecord record,
  }) async {
    lastDeviceKey = deviceKey;
    if (throwOnSave) {
      throw StateError('원격 저장 실패');
    }
    records[DateTime(date.year, date.month, date.day)] = record;
  }

  @override
  Future<void> saveAll({
    required String deviceKey,
    required Map<DateTime, AttendanceRecord> records,
  }) async {
    lastDeviceKey = deviceKey;
    uploadedRecords = Map<DateTime, AttendanceRecord>.from(records);
    this.records.addAll(records);
  }
}
