import 'package:sqflite/sqflite.dart';


class Recording {
  Recording({
    required this.id,
    required this.lineNumber,
    required this.runNumber,
    required this.isUploaded,
    required this.start,
    required this.end,
    required this.totalStart,
    required this.totalEnd,
  });

  int id;
  int? lineNumber;
  int? runNumber;
  bool isUploaded;
  DateTime? start;
  DateTime? end;
  DateTime totalStart;
  DateTime totalEnd;
}

class Coordinate {
  Coordinate({
    required this.id,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.recordingId,
  });

  final int id;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final int recordingId;
}


class DatabaseManager {
  DatabaseManager(Future<Database> database) : _database = database;
  final Future<Database> _database;

  Future<List<Recording>> getRecordings() async {
    final db = await _database;

    final recordingDict = await db.rawQuery('''
      SELECT rec.id, rec.line_number, rec.run_number, rec.is_uploaded,
        start_cord.time AS start, end_cord.time AS end,
        MIN(cords.time) AS total_start, MAX(cords.time) AS total_end
        FROM recordings AS rec
        LEFT JOIN cords start_cord ON start_cord.id = rec.start_cord_id
        LEFT JOIN cords end_cord ON end_cord.id = rec.end_cord_id
        JOIN cords ON rec.id = cords.recording_id
        GROUP BY rec.id;
    ''');

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
    final db = await _database;

    final recordingId = await db.insert("recordings", {
      "line_number": lineNumber,
      "run_number": runNumber,
    });

    return recordingId;
  }

  Future<void> deleteRecording(int recordingId) async {
    final db = await _database;

    await db.delete("recordings", where: "id = ?", whereArgs: [recordingId]);
  }

  Future<void> setRecordingRunAndLineNumber(int recordingId, {
    required int? runNumber,
    required int? lineNumber,
  }) async {
    final db = await _database;

    await db.update(
      "recordings",
      {"run_number": runNumber, "line_number": lineNumber},
      where: "id = ?",
      whereArgs: [recordingId],
    );
  }

  Future<void> setRecordingBounds(int recordingId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final db = await _database;

    await db.rawUpdate(
        '''
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
        ''',
        [
          startTime.toString(),
          endTime.toString(),
          recordingId,
        ]
    );
  }

  Future<void> markRecordingUploadDone(int recordingId) async {
    final db = await _database;

    await db.update(
        "recordings",
        {"is_uploaded": true},
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
    final db = await _database;

    return _cordMapListToCoordinates(await db.query(
      "cords",
      columns: ["id", "time", "latitude", "longitude", "altitude", "speed", "recording_id"],
      where: "recording_id = ?",
      whereArgs: [recordingId],
      orderBy: "time",
    ));

  }

  Future<List<Coordinate>> getCoordinatesWithBounds(int recordingId) async {
    final db = await _database;

    return _cordMapListToCoordinates(await db.rawQuery(
      """
      SELECT
        cords.id, cords.time, cords.latitude, cords.longitude, 
        cords.altitude, cords.speed, cords.recording_id
      FROM cords
      LEFT JOIN recordings AS rec ON cords.recording_id = rec.id
      WHERE
        rec.id = ? 
        AND cords.id BETWEEN rec.start_cord_id AND rec.end_cord_id;
      """, [recordingId]
    ));
  }

  Future<int> createCoordinate(int recordingId, {
    required double latitude,
    required double longitude,
    required double altitude,
    required double speed,
  }) async {
    final db = await _database;

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
