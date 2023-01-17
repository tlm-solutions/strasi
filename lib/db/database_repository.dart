import 'package:stasi/db/database_dao.dart';
import 'package:stasi/model/recording.dart';
import 'package:stasi/model/coordinate.dart';


class DatabaseRepository {
  final databaseDao = DatabaseDao();

  Future<List<Recording>> getRecordings() => databaseDao.getRecordings();

  Future<int> createRecording({int? runNumber, int? lineNumber}) => databaseDao.createRecording(
    runNumber: runNumber,
    lineNumber: lineNumber,
  );

  Future<int> deleteRecording(int recordingId) => databaseDao.deleteRecording(recordingId);

  Future<int> setRecordingRunAndLineNumber(int recordingId, {
    required int? runNumber,
    required int? lineNumber,
  }) => databaseDao.setRecordingRunAndLineNumber(recordingId,
      runNumber: runNumber,
      lineNumber: lineNumber
  );

  Future<int> setRecordingBounds(int recordingId, {
    required DateTime startTime,
    required DateTime endTime,
  }) => databaseDao.setRecordingBounds(recordingId,
      startTime: startTime,
      endTime: endTime
  );

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
