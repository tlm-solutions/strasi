import 'dart:async';

import 'package:stasi/db/database_repository.dart';
import 'package:stasi/model/recording.dart';
import 'package:stasi/model/coordinate.dart';


class DatabaseBloc {
  final _databaseRepository = DatabaseRepository();
  final _recordingController = StreamController<List<Recording>>.broadcast();

  DatabaseBloc() {
    getRecordings();
  }

  Stream<List<Recording>> get recordings => _recordingController.stream;

  Future<void> getRecordings() async {
    final recordings = await _databaseRepository.getRecordings();
    _recordingController.sink.add(recordings);
  }

  Future<int> createRecording({int? runNumber, int? lineNumber}) async {
    final recordingId = await _databaseRepository.createRecording(
      runNumber: runNumber,
      lineNumber: lineNumber,
    );
    getRecordings();

    return recordingId;
  }

  Future<int> deleteRecording(int recordingId) async {
    final result = await _databaseRepository.deleteRecording(recordingId);
    getRecordings();

    return result;
  }

  Future<int> setRecordingRunAndLineNumber(int recordingId, {
    required int? runNumber,
    required int? lineNumber,
  }) async {
    final result = await _databaseRepository.setRecordingRunAndLineNumber(
      recordingId,
      runNumber: runNumber,
      lineNumber: lineNumber,
    );
    getRecordings();

    return result;
  }

  Future<int> setRecordingBounds(int recordingId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final result = await _databaseRepository.setRecordingBounds(
      recordingId,
      startTime: startTime,
      endTime: endTime
    );
    getRecordings();

    return result;
  }

  Future<int> cleanRecording(int recordingId) async {
    final result = await _databaseRepository.cleanRecording(recordingId);
    getRecordings();

    return result;
  }

  Future<int> markRecordingUploadDone(int recordingId) async {
    final result = await _databaseRepository.markRecordingUploadDone(recordingId);
    getRecordings();

    return result;
  }

  Future<List<Coordinate>> getCoordinates(int recordingId) => _databaseRepository.getCoordinates(recordingId);

  Future<List<Coordinate>> getCoordinatesWithBounds(int recordingId) => _databaseRepository.getCoordinatesWithBounds(recordingId);

  Future<int> createCoordinate(int recordingId, {
    required double latitude,
    required double longitude,
    required double altitude,
    required double speed,
  }) async {
    final result = await _databaseRepository.createCoordinate(
      recordingId,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speed: speed,
    );
    // required since the recording object contains the amount of coordinates
    getRecordings();

    return result;
  }

  void dispose() {
    _recordingController.close();
  }
}
