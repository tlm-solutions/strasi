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
              onSaveAndExit: (startTime, endTime) async {
                final db = await widget.database;

                await db.rawUpdate('''
                  UPDATE recordings
                  SET 
                    start_cord_id = (
                      SELECT cords.id 
                      FROM cords 
                      WHERE NOT ? > cords.time
                      ORDER BY cords.time
                    ),
                    end_cord_id = (
                      SELECT cords.id
                      FROM cords
                      WHERE NOT ? < cords.time
                      ORDER BY cords.time DESC
                    )
                  WHERE id = ?;
                ''', [startTime, endTime, widget.recording.id]);
              },
            );
          },
        ),
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
  final Future<void> Function(DateTime startTime, DateTime endTime) onSaveAndExit;

  @override
  State<StatefulWidget> createState() => _RecordingEditorControlState();
}

class _RecordingEditorControlState extends State<_RecordingEditorControl> {
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    _startTime = widget.points.keys.first;
    _endTime = widget.points.keys.last;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          flex: 9,
          child: _RecordingEditorMap(
            pointList: [
              for (final time in widget.points.keys)
                if (_startTime.compareTo(time) <= 0 && _endTime.compareTo(time) >= 0)
                  widget.points[time]!
            ],
          ),
        ),
        Flexible(
          flex: 1,
          child: _RecordingEditorSlider(
            timeList: widget.points.keys.toList(),
            onChanged: (startTime, endTime) {
              setState(() {
                _startTime = startTime;
                _endTime = endTime;
              });
            },
          ),
        ),
        Flexible(
          child: _RecordingEditorButtons(
            onSaveAndExit: () async {
              await widget.onSaveAndExit(_startTime, _endTime);
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
    required Function(DateTime startTime, DateTime endTime) onChanged,
  }) :  _onChanged = onChanged,
        super(key: key);

  final List<DateTime> timeList;
  final void Function(DateTime startTime, DateTime endTime) _onChanged;

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
          widget.timeList[_timeRange.start.toInt()],
          widget.timeList[_timeRange.end.toInt()],
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
