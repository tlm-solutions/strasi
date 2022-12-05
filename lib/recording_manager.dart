import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sqflite/sqflite.dart';
import 'package:gpx/gpx.dart';
import 'package:stasi/recording.dart';
import 'package:stasi/theme.dart';

class RecordingManager extends StatefulWidget {
  final Future<Database> database;

  const RecordingManager({Key? key, required this.database}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RecordingManagerState();
}

class _RecordingManagerState extends State<RecordingManager> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getRecordings(widget.database),
        builder: (context, AsyncSnapshot<List<Recording>> snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error!;
          } else if (snapshot.hasData) {
            final recordings = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(4),
              itemCount: recordings.length,
              itemBuilder: (context, index) =>
                  _RecordEntry(
                    recording: recordings[index],
                    onExport: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      if (!io.Platform.isAndroid) {
                        scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text("Exporting only works on Android."),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      final gpxPath = await _exportCoordinatesToFile(
                        widget.database, recordings[index]
                      );

                      if (kDebugMode) {
                        print("GPX-Path: $gpxPath");
                      }

                      scaffoldMessenger.showSnackBar(SnackBar(
                        content: Text("Stored to $gpxPath"),
                      ));
                    },
                  ),
              separatorBuilder: (context, index) => const Divider(),
            );
          }

          return const Offstage();
        }
    );

  }
}

class _RecordEntry extends StatelessWidget {
  const _RecordEntry({
    Key? key,
    required this.recording,
    required this.onExport,
  }) : super(key: key);

  final Recording recording;
  final Future<void> Function() onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: dvbYellow.shade500),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Row(
          children: [
            Flexible(child: Text(
              "#${recording.id}",
              style: TextStyle(
                fontSize: 60,
                color: Colors.grey.shade500,
              ),
            )),
            Flexible(
              flex: 2,
              child: Center(child: Text(
                "Run: ${recording.runNumber}",
                style: const TextStyle(fontSize: 20),
              )),
            ),
            Flexible(
              flex: 2,
              child: Stack(
                  children: [
                    _OverflowingText("${recording.lineNumber}"),
                    Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: onExport,
                              icon: const Icon(Icons.save_alt),
                            )
                          ]
                        )
                    )
                  ],
              )
            ),
          ]
      ),
    );
  }
}

class _OverflowingText extends StatelessWidget {
  const _OverflowingText(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
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
    );
  }
}

Future<List<Recording>> _getRecordings(Future<Database> database) async {
  final db = await database;
  return (await db.query('recordings')).map((run) => Recording.fromDict(run)).toList();
}

Future<Gpx> _getCoordinatesAsGpx(Future<Database> database, int recordingId) async {
  final db = await database;

  final gpx = Gpx();
  gpx.creator = "stasi";
  gpx.wpts = (await db.query(
    "cords",
    columns: ["recording_id", "latitude", "longitude", "altitude", "time"],
    where: "recording_id = ?",
    whereArgs: [recordingId],
  )).map((cordMap) => Wpt(
    lat: cordMap["latitude"] as double,
    lon: cordMap["longitude"] as double,
    ele: cordMap["altitude"] as double,
    time: DateTime.parse(cordMap["time"] as String),
  )).toList();

  return gpx;
}

Future<String> _exportCoordinatesToFile(Future<Database> database, Recording recording) async {
  final gpxData = await _getCoordinatesAsGpx(database, recording.id);

  // This should be the start or stop time
  final secondsEpoch = (DateTime.now().millisecondsSinceEpoch / 1000).round();
  final fileName = "${recording.id}_${recording.lineNumber}_${recording.runNumber}_$secondsEpoch.gpx";

  final storageDir = (await path_provider.getExternalStorageDirectory())!;
  final gpxPath = path.join(storageDir.path, fileName);
  final gpxFile = io.File(gpxPath);

  await gpxFile.writeAsString(GpxWriter().asString(gpxData, pretty: true));
  return gpxPath;
}
