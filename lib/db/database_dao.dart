import 'package:stasi/db/database_provider.dart';
import 'package:stasi/model/recording.dart';
import 'package:stasi/model/coordinate.dart';


class DatabaseDao {
  final dbProvider = DatabaseProvider.dbProvider;

  Future<List<Recording>> getRecordings() async {
    final db = await dbProvider.db;

    final recordingDict = await db.rawQuery("""
      SELECT rec.id, rec.line_number, rec.run_number, rec.is_uploaded,
        start_cord.time AS start, end_cord.time AS end,
        MIN(cords.time) AS total_start, MAX(cords.time) AS total_end
      FROM recordings AS rec
      LEFT JOIN cords start_cord ON start_cord.id = rec.start_cord_id
      LEFT JOIN cords end_cord ON end_cord.id = rec.end_cord_id
      JOIN cords ON rec.id = cords.recording_id
      GROUP BY rec.id;
    """);

    return recordingDict.map((entry) =>
        Recording(
          id: entry["id"] as int,
          lineNumber: entry["line_number"] as int?,
          runNumber: entry["run_number"] as int?,
          isUploaded: (entry["is_uploaded"] as int) != 0,
          start: entry["start"] != null ? DateTime.parse(entry["start"] as String) : null,
          end: entry["end"] != null ? DateTime.parse(entry["end"] as String) : null,
          totalStart: DateTime.parse(entry["total_start"] as String),
          totalEnd: DateTime.parse(entry["total_end"] as String),
        ),
    ).toList();
  }

  Future<int> createRecording({int? runNumber, int? lineNumber}) async {
    final db = await dbProvider.db;

    final recordingId = await db.insert("recordings", {
      "line_number": lineNumber,
      "run_number": runNumber,
    });

    return recordingId;
  }

  Future<int> deleteRecording(int recordingId) async {
    final db = await dbProvider.db;

    return await db.delete("recordings", where: "id = ?", whereArgs: [recordingId]);
  }

  Future<int> setRecordingRunAndLineNumber(int recordingId, {
    required int? runNumber,
    required int? lineNumber,
  }) async {
    final db = await dbProvider.db;

    return await db.update(
      "recordings",
      {"run_number": runNumber, "line_number": lineNumber},
      where: "id = ?",
      whereArgs: [recordingId],
    );
  }

  Future<int> setRecordingBounds(int recordingId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final db = await dbProvider.db;

    return await db.rawUpdate(
        """
          UPDATE recordings
          SET 
            start_cord_id = (
              SELECT cords.id 
              FROM cords 
              WHERE NOT DATETIME(?) > cords.time
              ORDER BY cords.time
            ),
            end_cord_id = (
              SELECT cords.id
              FROM cords
              WHERE NOT DATETIME(?) < cords.time
              ORDER BY cords.time DESC
            )
          WHERE id = ?;
        """,
        [
          startTime.toString(),
          endTime.toString(),
          recordingId,
        ]
    );
  }
  
  Future<int> cleanRecording(int recordingId) async {
    final db = await dbProvider.db;

    // remove recording if it has less than three cords
    return await db.rawDelete("""
      DELETE FROM recordings WHERE recordings.id = ? AND (
        SELECT COUNT(cords.id) FROM cords WHERE cords.recording_id = recordings.id
      ) < 3;
    """, [recordingId]);
  }

  Future<int> markRecordingUploadDone(int recordingId) async {
    final db = await dbProvider.db;

    return await db.update(
      "recordings",
      {"is_uploaded": 1},
      where: "id = ?",
      whereArgs: [recordingId],
    );
  }

  Coordinate _cordMapToCoordinate(Map<String, Object?> cordMap) {
    return Coordinate(
      id: cordMap["id"] as int,
      time: DateTime.parse(cordMap["time"] as String),
      latitude: cordMap["latitude"] as double,
      longitude: cordMap["longitude"] as double,
      altitude: cordMap["altitude"] as double,
      speed: cordMap["speed"] as double,
      recordingId: cordMap["recording_id"] as int,
    );
  }

  List<Coordinate> _cordMapListToCoordinates(List<Map<String, Object?>> cordMaps) {
    return [
      for (final cordMap in cordMaps)
        _cordMapToCoordinate(cordMap)
    ];
  }

  Future<List<Coordinate>> getCoordinates(int recordingId) async {
    final db = await dbProvider.db;

    return _cordMapListToCoordinates(await db.query(
      "cords",
      columns: ["id", "time", "latitude", "longitude", "altitude", "speed", "recording_id"],
      where: "recording_id = ?",
      whereArgs: [recordingId],
      orderBy: "time",
    ));
  }

  Future<List<Coordinate>> getCoordinatesWithBounds(int recordingId) async {
    final db = await dbProvider.db;

    return _cordMapListToCoordinates(await db.rawQuery(
        """
          SELECT
            cords.id, cords.time, cords.latitude, cords.longitude, 
            cords.altitude, cords.speed, cords.recording_id
          FROM cords
          LEFT JOIN recordings AS rec ON cords.recording_id = rec.id
          WHERE
            rec.id = ? 
            AND (
              (cords.id >= rec.start_cord_id OR rec.start_cord_id IS NULL) AND
              (cords.id <= rec.end_cord_id OR rec.end_cord_id IS NULL)
            );
        """, [recordingId]
    ));
  }

  Future<int> createCoordinate(int recordingId, {
    required double latitude,
    required double longitude,
    required double altitude,
    required double speed,
  }) async {
    final db = await dbProvider.db;

    final coordinateId = await db.insert("cords", {
      "latitude": latitude,
      "longitude": longitude,
      "altitude": altitude,
      "speed": speed,
      "recording_id": recordingId,
    });

    return coordinateId;
  }
}
