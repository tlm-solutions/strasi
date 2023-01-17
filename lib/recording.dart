import 'package:sqflite/sqflite.dart';

class Recording {
  int id;
  int? lineNumber;
  int? runNumber;
  bool isUploaded;
  DateTime? start;
  DateTime? end;
  DateTime totalStart;
  DateTime totalEnd;

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

  static Future<List<Recording>> fromDb(Future<Database> database) async {
    final db = await database;
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
}
