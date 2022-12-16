import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';

import 'recording.dart';

class RecordingEditor extends StatefulWidget {
  const RecordingEditor({
    Key? key,
    required this.database,
    required this.recording,
  }) : super(key: key);
  final Future<Database> database;
  final Recording recording;

  @override
  State<StatefulWidget> createState() => _RecordingEditorState();
}

class _RecordingEditorState extends State<RecordingEditor> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder(
          future: _getPointsFromRecord(),
          builder: (context, AsyncSnapshot<List<LatLng>> snapshot) {
            print("hey");

            if (snapshot.hasError) {
              throw snapshot.error!;
            } else if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final points = snapshot.data!;

            return _RecordingEditorMap(points: points);
          }
        )
      ],
    );
  }

  Future<List<LatLng>> _getPointsFromRecord() async {
    final db = await widget.database;

    return (await db.query(
      "cords",
      columns: ["latitude", "longitude", "recording_id"],
      where: "recording_id = ?",
      whereArgs: [widget.recording.id],

    )).map((dbCoordinate) => LatLng(
        dbCoordinate["latitude"] as double,
        dbCoordinate["longitude"] as double,
    )).toList();
  }

}

class _RecordingEditorMap extends StatelessWidget {
  const _RecordingEditorMap({
    Key? key,
    required this.points,
  }) : super(key: key);

  final List<LatLng> points;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        bounds: LatLngBounds.fromPoints(points),
        boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(8.0)),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ["a", "b", "c"],
          tileBuilder: darkModeTileBuilder,
          backgroundColor: Colors.black54,
        ),
        PolylineLayer(
          polylines: [Polyline(
            points: Path.from(points).equalize(30, smoothPath: true).coordinates,
            strokeWidth: 10,
          )],
        ),
      ],
    );
  }
}
