import 'package:flutter/material.dart';

import 'db/database_bloc.dart';
import 'model/recording.dart';
import 'recording_editor.dart';


class RecordingEditorRoute extends StatelessWidget {
  const RecordingEditorRoute({
    Key? key,
    required this.databaseBloc,
    required this.recording
  }) : super(key: key);

  final DatabaseBloc databaseBloc;
  final Recording recording;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit route ${recording.id}"),
      ),
      body: RecordingEditor(
        databaseBloc: databaseBloc,
        recording: recording,
      ),
    );
  }
}
