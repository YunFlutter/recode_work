import '../../domain/models/attendance_record.dart';
import '../services/attendance_remote_data_source.dart';
import 'attendance_repository.dart';

typedef SyncErrorHandler = void Function(Object error, StackTrace stackTrace);

class SyncingAttendanceRepository implements AttendanceRepository {
  SyncingAttendanceRepository({
    required AttendanceRepository localRepository,
    required AttendanceRemoteDataSource remoteDataSource,
    required String deviceKey,
    this.onSyncError,
  }) : _localRepository = localRepository,
       _remoteDataSource = remoteDataSource,
       _deviceKey = deviceKey;

  final AttendanceRepository _localRepository;
  final AttendanceRemoteDataSource _remoteDataSource;
  final String _deviceKey;
  final SyncErrorHandler? onSyncError;

  Future<void> synchronize({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final localBeforeSync = _localRepository.getAll();
    final remoteRecords = await _remoteDataSource
        .fetchAll(deviceKey: _deviceKey)
        .timeout(timeout);

    for (final entry in remoteRecords.entries) {
      if (!localBeforeSync.containsKey(_dateOnly(entry.key))) {
        await _localRepository.save(entry.key, entry.value);
      }
    }

    await _remoteDataSource.saveAll(
      deviceKey: _deviceKey,
      records: _localRepository.getAll(),
    );
  }

  @override
  Map<DateTime, AttendanceRecord> getAll() => _localRepository.getAll();

  @override
  AttendanceRecord? getByDate(DateTime date) {
    return _localRepository.getByDate(date);
  }

  @override
  Future<void> save(DateTime date, AttendanceRecord record) async {
    await _localRepository.save(date, record);

    try {
      await _remoteDataSource.save(
        deviceKey: _deviceKey,
        date: date,
        record: record,
      );
    } catch (error, stackTrace) {
      onSyncError?.call(error, stackTrace);
    }
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
