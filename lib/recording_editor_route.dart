import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'recording.dart';
import 'recording_editor.dart';

class RecordingEditorRoute extends StatelessWidget {
  const RecordingEditorRoute({
    Key? key,
    required this.database,
    required this.recording
  }) : super(key: key);

  final Future<Database> database;
  final Recording recording;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit route ${recording.id}"),
      ),
      body: RecordingEditor(
        database: database,
        recording: recording,
      ),
    );
  }
}
