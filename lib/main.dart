import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:provider/provider.dart';
import 'package:stasi/recording_manager.dart';
import 'package:stasi/running_recording.dart';
import 'package:stasi/theme.dart';
import 'package:stasi/vehicle_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), "cords"),
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE recordings (
          id INTEGER PRIMARY KEY,
          line_number INTEGER NOT NULL,
          run_number INTEGER NOT NULL
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

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Future<Database> database;
  const MyApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STASI',
      theme: appTheme,
      home: MyHomePage(title: 'STASI', database: database),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.database}) : super(key: key);

  final String title;
  final Future<Database> database;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ChangeNotifierProvider(
        create: (context) => RunningRecording(),
        child: PageView(
          controller: controller,
          children: [
            VehicleSelection(database: widget.database),
            RecordingManager(database: widget.database),
            const LicensePage(
              applicationName: "Stasi",
            ),
          ],
        ),
      ),
    );
  }
}

