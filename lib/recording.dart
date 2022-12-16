import 'package:sqflite/sqflite.dart';

class Recording {
  int id;
  int? lineNumber;
  int? runNumber;
  bool isUploaded;
  DateTime start;
  DateTime stop;

  Recording({
    required this.id,
    required this.lineNumber,
    required this.runNumber,
    required this.isUploaded,
    required this.start,
    required this.stop,
  });

  static Future<List<Recording>> fromDb(Future<Database> database) async {
    final db = await database;
    final recordingDict = await db.rawQuery('''
      SELECT rec.id, rec.line_number, rec.run_number, rec.is_uploaded,
        MIN(cords.time) AS start, MAX(cords.time) AS stop
        FROM recordings AS rec JOIN cords ON rec.id = cords.recording_id
        GROUP BY rec.id;
    ''');

    return recordingDict.map((entry) =>
      Recording(
          id: entry["id"] as int,
          lineNumber: entry["line_number"] as int?,
          runNumber: entry["run_number"] as int?,
          isUploaded: (entry["is_uploaded"] as int) != 0,
          start: DateTime.parse(entry["start"] as String),
          stop: DateTime.parse(entry["stop"] as String),
      )
    ).toList();
  }
}
