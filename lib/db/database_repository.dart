import 'package:strasi/db/database_dao.dart';
import 'package:strasi/model/recording.dart';
import 'package:strasi/model/coordinate.dart';


class DatabaseRepository {
  final databaseDao = DatabaseDao();

  Future<List<Recording>> getRecordings() => databaseDao.getRecordings();

  Future<int> createRecording({int? runNumber, int? lineNumber, int? regionId}) => databaseDao.createRecording(
    runNumber: runNumber,
    lineNumber: lineNumber,
    regionId: regionId,
  );

  Future<int> deleteRecording(int recordingId) => databaseDao.deleteRecording(recordingId);

  Future<int> setRecordingRunAndLineNumber(int recordingId, {
    required int? runNumber,
    required int? lineNumber,
  }) => databaseDao.setRecordingRunAndLineNumber(recordingId,
    runNumber: runNumber,
    lineNumber: lineNumber,
  );

  Future<int> setRecordingRegionId(int recordingId, int? regionId) =>
      databaseDao.setRecordingRegionId(recordingId, regionId);

  Future<int> setRecordingBounds(int recordingId, {
    required DateTime startTime,
    required DateTime endTime,
  }) => databaseDao.setRecordingBounds(recordingId,
      startTime: startTime,
      endTime: endTime
  );

  Future<int> cleanRecording(int recordingId) => databaseDao.cleanRecording(recordingId);

  Future<int> markRecordingUploadDone(int recordingId) => databaseDao.markRecordingUploadDone(recordingId);

  Future<List<Coordinate>> getCoordinates(int recordingId) => databaseDao.getCoordinates(recordingId);

  Future<List<Coordinate>> getCoordinatesWithBounds(int recordingId) => databaseDao.getCoordinatesWithBounds(recordingId);

  Future<int> createCoordinate(int recordingId, {
    required double latitude,
    required double longitude,
    required double altitude,
    required double speed,
  }) => databaseDao.createCoordinate(
      recordingId,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speed: speed
  );
}
