import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gpx/gpx.dart';
import 'package:intl/intl.dart';
import 'package:stasi/recording.dart';
import 'package:stasi/running_recording.dart';
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
        future: Recording.fromDb(widget.database),
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
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      final gpxPath = await _exportCoordinatesToFile(
                          widget.database, recordings[index]
                      );

                      if (kDebugMode) print("GPX-Path: $gpxPath");

                      scaffoldMessenger.showSnackBar(SnackBar(
                        content: Text("Stored to $gpxPath"),
                      ));
                    },
                    onDelete: () async {
                      await _deleteRecording(widget.database, recordings[index]);
                      setState(() {});
                    },
                  ),
                  separatorBuilder: (context, index) => const Divider(),
                );
              },
            );
          }

          return const Offstage();
        }
    );

  }
}

class _RecordingEntry extends StatelessWidget {
  const _RecordingEntry({
    Key? key,
    required this.recording,
    required this.onExport,
    required this.onDelete,
  }) : super(key: key);

  final Recording recording;
  final Future<void> Function() onExport;
  final Future<void> Function() onDelete;

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
                            ),
                            IconButton(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete),
                            ),
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

Future<Gpx> _getCoordinatesAsGpx(Future<Database> database, Recording recording) async {
  final db = await database;

  final gpx = Gpx();
  gpx.metadata = Metadata(
    name: DateFormat("y-M-d_H-m-s").format(DateTime.now().toUtc()),
    desc: "Tracked by your friendly stasi comrades.",
    keywords: "stasi",
    time: DateTime.now().toUtc(),
    extensions: {
      "line": "${recording.lineNumber}",
      "run": "${recording.runNumber}",
      "start": recording.start.toIso8601String(),
      "stop": recording.stop.toIso8601String(),
    },
  );
  gpx.creator = "Stasi for ${io.Platform.operatingSystem} - https://github.com/dump-dvb/stasi";
  gpx.version = "1.1";
  gpx.trks = [Trk(
    trksegs: [Trkseg(
      trkpts: (await db.query(
          "cords",
          columns: ["recording_id", "latitude", "longitude", "speed", "altitude", "time"],
          where: "recording_id = ?",
          whereArgs: [recording.id],
        )).map((cordMap) => Wpt(
          lat: cordMap["latitude"] as double,
          lon: cordMap["longitude"] as double,
          ele: cordMap["altitude"] as double,
          time: DateTime.parse(cordMap["time"] as String),
          extensions: {"speed": '${cordMap["speed"] as double}'},
        )).toList(),
    )]
  )];

  return gpx;
}

Future<String> _exportCoordinatesToFile(Future<Database> database, Recording recording) async {
  final gpxData = await _getCoordinatesAsGpx(database, recording);

  // This should be the start or stop time
  final secondsEpoch = (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).round();
  final fileName = "${recording.id}_${recording.lineNumber}_${recording.runNumber}_$secondsEpoch.gpx";

  final io.Directory storageDir;
  if (io.Platform.isAndroid) {
    storageDir = (await path_provider.getExternalStorageDirectory())!;
  } else {
    storageDir = await path_provider.getApplicationDocumentsDirectory();
  }

  final gpxPath = path.join(storageDir.path, fileName);
  final gpxFile = io.File(gpxPath);

  await gpxFile.writeAsString(GpxWriter().asString(gpxData, pretty: true));
  return gpxPath;
}

Future<void> _deleteRecording(Future<Database> database, Recording recording) async {
  final db = await database;

  // cords should just be deleted via foreign key but that doesnt wok
  await db.delete("recordings", where: "id = ?", whereArgs: [recording.id]);
}
