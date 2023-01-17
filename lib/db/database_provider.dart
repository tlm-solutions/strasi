import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseProvider {
  static final DatabaseProvider dbProvider = DatabaseProvider();

  Database? _db;

  Future<Database> get db async {
    _db ??= await createDatabase();
    return _db!;
  }

  Future<Database> createDatabase() async {
    final String databasePath;
    if (io.Platform.isIOS) {
      databasePath = (await getLibraryDirectory()).path;
    } else {
      databasePath = await getDatabasesPath();
    }

    final database = await openDatabase(
      join(databasePath, "cords.db"),
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recordings (
            id INTEGER PRIMARY KEY,
            line_number INTEGER,
            run_number INTEGER,
            is_uploaded BOOLEAN NOT NULL CHECK (is_uploaded IN (0, 1)) DEFAULT 0,
            start_cord_id INTEGER,
            end_cord_id INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE cords (
            id INTEGER PRIMARY KEY,
            time DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
            latitude DOUBLE NOT NULL,
            longitude DOUBLE NOT NULL,
            altitude DOUBLE NOT NULL,
            speed DOUBLE NOT NULL,
            recording_id INTEGER NOT NULL,
            FOREIGN KEY (recording_id) REFERENCES recordings (id)
              ON UPDATE CASCADE
              ON DELETE CASCADE
          );
        ''');
      },
      version: 1,
    );

    return database;
  }
}
