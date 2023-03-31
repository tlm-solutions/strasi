import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:provider/provider.dart';
import 'package:gpx/gpx.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:stasi/db/database_bloc.dart';
import 'package:stasi/routes/recording_editor_route.dart';
import 'package:stasi/notifiers/running_recording.dart';
import 'package:stasi/util/theme.dart';
import 'package:stasi/util/api_client.dart';
import 'package:stasi/model/recording.dart';


class RecordingManager extends StatefulWidget {
  final DatabaseBloc databaseBloc;

  const RecordingManager({Key? key, required this.databaseBloc}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RecordingManagerState();
}

class _RecordingManagerState extends State<RecordingManager> {
  @override
  Widget build(BuildContext context) {
    widget.databaseBloc.getRecordings();
    return StreamBuilder(
        stream: widget.databaseBloc.recordings,
        builder: (context, AsyncSnapshot<List<Recording>> snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          } else if (snapshot.hasData) {

            return Consumer<RunningRecording>(
              builder: (context, curRecording, child) {
                final recordings = snapshot.data!.reversed
                    .where((recording) => recording.id != curRecording.recordingId)
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(4),
                  itemCount: recordings.length,
                  itemBuilder: (context, index) => _RecordingEntry(
                    recording: recordings[index],
                    onExport: () async {
                      final gpxPath = await _exportCoordinatesToFile(
                          widget.databaseBloc,
                          recordings[index],
                      );

                      if (gpxPath == null) {
                        debugPrint("User canceled export");
                      } else {
                        debugPrint("GPX-file saved to $gpxPath");
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                        content: Text(
                            gpxPath != null
                                ? "Stored file."
                                : "You did not select a path. Export canceled!",
                        ),
                      ));
                    },
                    onDelete: () async {
                      await widget.databaseBloc.deleteRecording(recordings[index].id);
                    },
                    onUpload: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        await _uploadRecording(widget.databaseBloc, recordings[index]);
                      } on http.ClientException {
                        scaffoldMessenger.showSnackBar(const SnackBar(
                            content: Text("We couldn't connect to the KGB server. Is your Internet working?"),
                        ));
                        return;
                      }
                      scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text("Uploaded!"),
                      ));
                      await widget.databaseBloc.markRecordingUploadDone(recordings[index].id);
                    },
                    onEdit: () async {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => RecordingEditorRoute(
                              databaseBloc: widget.databaseBloc,
                              recording: recordings[index],
                          ),
                      ));
                    },
                  ),
                  separatorBuilder: (context, index) => const Divider(),
                );
              },
            );
          }

          return const Offstage();
        },
    );

  }
}

class _RecordingEntry extends StatelessWidget {
  _RecordingEntry({
    Key? key,
    required this.recording,
    required this.onExport,
    required this.onDelete,
    required this.onUpload,
    required this.onEdit,
  }) : super(key: key);

  final Recording recording;
  final Future<void> Function() onExport;
  final Future<void> Function() onDelete;
  final Future<void> Function() onUpload;
  final Future<void> Function() onEdit;
  final ValueNotifier<bool> _buttonsLoadingNotifier = ValueNotifier(false);

  Future<void> Function() _wrapWithNotifier(Future<void> Function() toWrap) {
    Future<void> wrappedFunction() async {
      _buttonsLoadingNotifier.value = true;
      await toWrap();
      _buttonsLoadingNotifier.value = false;
    }

    return wrappedFunction;
  }

  bool get _allFieldsAreSet =>
      recording.lineNumber != null && recording.runNumber != null && recording.regionId != null;

  bool get _isUploadable => _allFieldsAreSet && !recording.isUploaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: dvbYellow.shade500),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Stack(children: [
        _OverflowingText("${recording.lineNumber}"),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          columnWidths: const {
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(3),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                Text("#${recording.id}", style: const TextStyle(fontSize: 21)),
                Text(
                  "Line ${recording.lineNumber}",
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.end,
                ),
                IconButton(
                  onPressed: _wrapWithNotifier(onEdit),
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: _wrapWithNotifier(onDelete),
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            TableRow(
              children: [
                const Offstage(),
                SizedBox(
                  height: 30,
                  child: Text(
                    "Region id ${recording.regionId}",
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.end,
                  ),
                ),
                const Offstage(),
                const Offstage(),
              ]
            ),
            TableRow(
              children: [
                const Offstage(),
                Text(
                  "Run ${recording.runNumber}",
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.end,
                ),
                IconButton(
                  onPressed: _wrapWithNotifier(onExport),
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.save_alt),
                ),
                IconButton(
                  onPressed: _isUploadable ? _wrapWithNotifier(onUpload) : null,
                  padding: const EdgeInsets.all(6.0),
                  constraints: const BoxConstraints(),
                  icon: recording.isUploaded ? const Icon(Icons.done) : const Icon(Icons.upload),
                ),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}

class _OverflowingText extends StatelessWidget {
  const _OverflowingText(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ClipRect(
          child: Opacity(
            opacity: 0.4,
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textScaleFactor: 2.1,
              style: TextStyle(
                fontSize: 60,
                height: 0.9,
                color: dvbYellow.shade900,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        )
    );
  }
}

Future<Gpx> _getCoordinatesAsGpx(DatabaseBloc databaseBloc, Recording recording) async {
  final recordingStart = recording.start ?? recording.totalStart;
  final recordingEnd = recording.end ?? recording.totalEnd;

  final gpx = Gpx()
    ..metadata = Metadata(
      name: DateFormat("y-M-d_H-m-s").format(DateTime.now().toUtc()),
      desc: "Tracked by your friendly stasi comrades.",
      keywords: "stasi",
      time: DateTime.now().toUtc(),
      extensions: {
        "line": "${recording.lineNumber}",
        "run": "${recording.runNumber}",
        "region": "${recording.regionId}",
        "start": recordingStart.toIso8601String(),
        "stop": recordingEnd.toIso8601String(),
      },
    )
    ..creator = "Stasi for ${io.Platform.operatingSystem} - https://github.com/tlm-solutions/stasi"
    ..version = "1.1"
    ..trks = [Trk(
      trksegs: [Trkseg(
        trkpts: (await databaseBloc.getCoordinatesWithBounds(recording.id))
            .map((coordinate) => Wpt(
            lat: coordinate.latitude,
            lon: coordinate.longitude,
            ele: coordinate.altitude,
            time: coordinate.time,
            extensions: {"speed": '${coordinate.speed}'},
          )).toList(),
      )]
    )];

  return gpx;
}

/// Returns filepath or null if user canceled export.
Future<String?> _exportCoordinatesToFile(DatabaseBloc databaseBloc, Recording recording) async {
  final gpxData = await _getCoordinatesAsGpx(databaseBloc, recording);
  final fileName = "stasi-export_${recording.id}_${recording.lineNumber}_${recording.runNumber}.gpx";
  final gpxFileContents = GpxWriter().asString(gpxData, pretty: true);

  // store using the dialog so the files are independent from the app
  final saveFileParams = SaveFileDialogParams(
    fileName: fileName,
    data: Uint8List.fromList(gpxFileContents.codeUnits),
  );

  return await FlutterFileDialog.saveFile(params: saveFileParams);
}

Future<void> _uploadRecording(DatabaseBloc databaseBloc, Recording recording) async {
  final gpx = await _getCoordinatesAsGpx(databaseBloc, recording);

  await ApiClient().sendGpx(gpx, recording);
}
