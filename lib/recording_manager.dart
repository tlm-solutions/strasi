import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:gpx/gpx.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
                    onUpload: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await _uploadRecording(widget.database, recordings[index]);
                      scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text("Uploaded!")
                      ));
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
    required this.onUpload,
  }) : super(key: key);

  final Recording recording;
  final Future<void> Function() onExport;
  final Future<void> Function() onDelete;
  final Future<void> Function() onUpload;

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
                            IconButton(
                              onPressed: onUpload,
                              icon: const Icon(Icons.upload),
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

class _LoginData {
  const _LoginData({
    required this.userId,
    required this.password,
  });

  final String userId;
  final String password;

  Map<String, String> toMap() => {"user_id": userId, "password": password};
}

class _Session {
  static final _Session _session = _Session._internal();

  factory _Session() {
    return _session;
  }

  _Session._internal(): _url = "trekkie.staging.dvb.solutions";

  final String _url;
  io.Cookie? _cookie;


  Future<bool> loginUser(_LoginData loginData) async {
    final response = await http.post(
      Uri(scheme: "https", host: _url, path: "/user/login"),
      body: jsonEncode(loginData.toMap()),
      headers: {"Content-Type": "application/json"}
    );
    if (response.statusCode != 200) return false;
    _updateCookie(response.headers);
    return true;
  }

  Future<_LoginData?> createAccount() async {
    final response = await http.post(Uri(scheme: "https", host: _url, path: "/user/create"));
    if (response.statusCode != 200) return null;
    _updateCookie(response.headers);
    final responseDict = jsonDecode(response.body);
    return _LoginData(userId: responseDict["user_id"], password: responseDict["password"]);
  }

  Future<bool> sendGpx(Gpx gpx, Recording recording) async {
    final gpxRequest = http.MultipartRequest("POST", Uri.parse("https://trekkie.staging.dvb.solutions/travel/submit/gpx"));
    gpxRequest.files.add(http.MultipartFile.fromString(
      "yo mama",
      GpxWriter().asString(gpx, pretty: true),
      contentType: MediaType("text", "xml"),
    ));
    gpxRequest.headers["cookie"] = await _getCookie();
    final gpxResponse = await gpxRequest.send();
    if (gpxResponse.statusCode != 200) return false;

    final timesJson = {
      "gpx_id": jsonDecode(await gpxResponse.stream.bytesToString())["gpx_id"],
      "vehicles": [{
        "start": recording.start.toIso8601String(),
        "stop": recording.stop.toIso8601String(),
        "line": recording.lineNumber,
        "run": recording.runNumber,
        "region": 0,
      }]
    };

    final submitResponse = await http.post(
      Uri(scheme: "https", host: _url, path: "/travel/submit/run"),
      headers: {"cookie": await _getCookie(), "Content-Type": "application/json"},
      body: jsonEncode(timesJson),
    );

    return submitResponse.statusCode == 200;
  }

  void _updateCookie(Map<String, String> headers) {
    _cookie = io.Cookie.fromSetCookieValue(headers["set-cookie"]!);
  }

  Future<_LoginData> _getLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (userId != null) {
      final password = prefs.getString("password")!;
      return _LoginData(userId: userId, password: password);
    }

    final loginData = (await createAccount())!;

    prefs.setString("user_id", loginData.userId);
    prefs.setString("password", loginData.password);

    return loginData;
  }

  Future<String> _getCookie() async {
    if (_cookie == null /* || _cookie!.expires!.isAfter(DateTime.now().toUtc()) */) {
      final loginData = await _getLoginData();
      assert (await loginUser(loginData));
    }
    return _cookie!.value;
  }
}

Future<void> _uploadRecording(Future<Database> database, Recording recording) async {
  final gpx = await _getCoordinatesAsGpx(database, recording);

  await _Session().sendGpx(gpx, recording);
}

