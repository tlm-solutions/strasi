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
          builder: (context, AsyncSnapshot<Map<DateTime, LatLng>> snapshot) {
            if (snapshot.hasError) {
              throw snapshot.error!;
            } else if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final points = snapshot.data!;

            return _RecordingEditorControl(
              points: points,
              onSaveAndExit: (startCordId, endCordId) async {
                final db = await widget.database;

                await db.update(
                  "recordings",
                  {
                    "start_cord_id": startCordId,
                    "end_cord_id": endCordId,
                  },
                  where: "id = ?",
                  whereArgs: [widget.recording.id],
                );
              },
            );
          }
        )
      ],
    );
  }

  Future<Map<DateTime, LatLng>> _getPointsFromRecord() async {
    final db = await widget.database;

    return { for (var dbCord in await db.query(
        "cords",
        columns: ["latitude", "longitude", "time", "recording_id"],
        where: "recording_id = ?",
        whereArgs: [widget.recording.id],
      )) DateTime.parse(dbCord["time"] as String) : LatLng(
        dbCord["latitude"] as double,
        dbCord["longitude"] as double,
      ) };
  }

}

class _RecordingEditorControl extends StatefulWidget {
  const _RecordingEditorControl({
    Key? key,
    required this.points,
    required this.onSaveAndExit,
  }) : super(key: key);

  final Map<DateTime, LatLng> points;
  final Future<void> Function(int startCordId, int endCordId) onSaveAndExit;

  @override
  State<StatefulWidget> createState() => _RecordingEditorControlState();
}

class _RecordingEditorControlState extends State<_RecordingEditorControl> {
  late int _startPointList;
  late int _endPointList;

  @override
  void initState() {
    _startPointList = 0;
    _endPointList = widget.points.values.length - 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          flex: 9,
          child: _RecordingEditorMap(
            pointList: widget.points.values.toList().sublist(
              _startPointList,
              _endPointList,
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: _RecordingEditorSlider(
            timeList: widget.points.keys.toList(),
            onChanged: (int start, int end) {
              setState(() {
                _startPointList = start;
                _endPointList = end;
              });
            },
          ),
        ),
        Flexible(
          child: _RecordingEditorButtons(
            onSaveAndExit: () async {
              await widget.onSaveAndExit(_startPointList, _endPointList);
            },
          ),
        ),
      ]
    );
  }
}

class _RecordingEditorMap extends StatelessWidget {
  const _RecordingEditorMap({
    Key? key,
    required this.pointList,
  }) : super(key: key);

  final List<LatLng> pointList;

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds.fromPoints(pointList);

    return FlutterMap(
      options: MapOptions(
        bounds: bounds,
        boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(80.0)),
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
            points: pointList,
            strokeWidth: 10,
          )],
        ),
      ],
    );
  }
}

class _RecordingEditorSlider extends StatefulWidget {
  const _RecordingEditorSlider({
    Key? key,
    required this.timeList,
    required Function(int start, int end) onChanged,
  }) :  _onChanged = onChanged,
        super(key: key);

  final List<DateTime> timeList;
  final void Function(int start, int end) _onChanged;

  @override
  State<StatefulWidget> createState() => _RecordingEditorSliderState();
}

class _RecordingEditorSliderState extends State<_RecordingEditorSlider> {
  late RangeValues _timeRange;

  @override
  void initState() {
    _timeRange = RangeValues(0, widget.timeList.length - 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RangeSlider(
      onChanged: (RangeValues values) {
        // prevent the selection of only one cord
        if (values.end - values.start == 0) return;

        setState(() {
          _timeRange = values;
        });

        widget._onChanged(
          _timeRange.start.toInt(),
          _timeRange.end.toInt() + 1,
        );
      },
      divisions: widget.timeList.length - 1,
      values: _timeRange,
      min: 0,
      max: widget.timeList.length - 1,
      labels: RangeLabels(
        widget.timeList[_timeRange.start.toInt()].toIso8601String(),
        widget.timeList[_timeRange.end.toInt()].toIso8601String(),
      ),
    );
  }
}

class _RecordingEditorButtons extends StatelessWidget {
  const _RecordingEditorButtons({
    Key? key,
    required this.onSaveAndExit,
  }) : super(key: key);

  final VoidCallback onSaveAndExit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ElevatedButton(
        onPressed: onSaveAndExit,
        child: const Text("Save & Exit"),
      ),
    ],
  );

}
