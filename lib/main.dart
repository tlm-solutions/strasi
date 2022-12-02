import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stasi/theme.dart';
import 'package:stasi/vehicle_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), "cords"),
    onCreate: (db, version) {
      return db.execute('CREATE TABLE runs(id INTEGER PRIMARY KEY, vehicle_number INTEGER NOT NULL, run_number INTEGER NOT NULL, time DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, latitude DOUBLE NOT NULL, longitude DOUBLE NOT NULL, speed DOUBLE NOT NULL);');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(child: VehicleSelection(database: widget.database))
          ],
        ),
      ),
    );
  }
}
