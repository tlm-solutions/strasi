import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stasi/db/database_bloc.dart';
import 'package:stasi/pages/running_recording.dart';
import 'package:stasi/util/theme.dart';
import 'package:stasi/pages/recording_manager.dart';
import 'package:stasi/pages/vehicle_selection.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseBloc = DatabaseBloc();

  runApp(MyApp(databaseBloc: databaseBloc));
}

class MyApp extends StatelessWidget {
  final DatabaseBloc databaseBloc;
  const MyApp({Key? key, required this.databaseBloc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STASI',
      theme: appTheme,
      home: MyHomePage(title: 'STASI', databaseBloc: databaseBloc),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.databaseBloc}) : super(key: key);

  final String title;
  final DatabaseBloc databaseBloc;

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
            VehicleSelection(databaseBloc: widget.databaseBloc),
            RecordingManager(databaseBloc: widget.databaseBloc),
            const LicensePage(
              applicationName: "Stasi",
            ),
          ],
        ),
      ),
    );
  }
}

