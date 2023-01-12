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

            return _RecordingEditorControl(points: points);
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
  }) : super(key: key);

  final Map<DateTime, LatLng> points;

  @override
  State<StatefulWidget> createState() => _RecordingEditorControlState();
}

class _RecordingEditorControlState extends State<_RecordingEditorControl> {
  late List<LatLng> _pointList;

  @override
  void initState() {
    _pointList = widget.points.values.toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          flex: 9,
          child: _RecordingEditorMap(pointList: _pointList),
        ),
        Flexible(
          flex: 1,
          child: _RecordingEditorSlider(
            timeList: widget.points.keys.toList(),
            onChanged: (List<DateTime> newTimeList) {
              setState(() {
                _pointList = newTimeList.map((dateTime) => widget.points[dateTime]!).toList();
              });
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
    required ValueChanged<List<DateTime>> onChanged,
  }) :  _onChanged = onChanged,
        super(key: key);

  final List<DateTime> timeList;
  final ValueChanged<List<DateTime>>  _onChanged;

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
        setState(() {
          // prevent the selection of only one cord
          if (values.end - values.start > 0) {
            _timeRange = values;
          }
        });
        widget._onChanged(
          widget.timeList.sublist(
            _timeRange.start.toInt(),
            _timeRange.end.toInt() + 1,
          ),
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
