import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stasi/database_manager.dart';


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

            final initialStartTime = widget.recording.start ?? points.keys.first;
            final initialEndTime = widget.recording.end ?? points.keys.last;

            return _RecordingEditorControl(
              points: points,
              initialStartTime: initialStartTime,
              initialEndTime: initialEndTime,
              onSaveAndExit: (startTime, endTime) async {
                final databaseManager = DatabaseManager(widget.database);

                await databaseManager.setRecordingBounds(
                  widget.recording.id,
                  startTime: startTime,
                  endTime: endTime,
                );

                if (!mounted) return;
                Navigator.pop(context);
              },
            );
          },
        ),
      ],
    );
  }

  Future<Map<DateTime, LatLng>> _getPointsFromRecord() async {
    final databaseManager = DatabaseManager(widget.database);

    return {
      for (final coordinate in await databaseManager.getCoordinates(widget.recording.id))
        coordinate.time: LatLng(coordinate.latitude, coordinate.longitude)
    };
  }

}

class _RecordingEditorControl extends StatefulWidget {
  const _RecordingEditorControl({
    Key? key,
    required this.points,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.onSaveAndExit,
  }) : super(key: key);

  final Map<DateTime, LatLng> points;
  final DateTime initialStartTime;
  final DateTime initialEndTime;
  final Future<void> Function(DateTime startTime, DateTime endTime) onSaveAndExit;

  @override
  State<StatefulWidget> createState() => _RecordingEditorControlState();
}

class _RecordingEditorControlState extends State<_RecordingEditorControl> {
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
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
            startTime: _startTime,
            endTime: _endTime,
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


class _RecordingEditorSlider extends StatelessWidget {
  const _RecordingEditorSlider({
    Key? key,
    required this.timeList,
    required this.startTime,
    required this.endTime,
    required this.onChanged,
  }) : super(key: key);

  final List<DateTime> timeList;
  final DateTime startTime;
  final DateTime endTime;
  final void Function(DateTime startTime, DateTime endTime) onChanged;

  @override
  Widget build(BuildContext context) {
    return RangeSlider(
      onChanged: (RangeValues values) {
        // prevent the selection of only one cord
        if (values.end - values.start == 0) return;

        onChanged(
          timeList[values.start.toInt()],
          timeList[values.end.toInt()],
        );
      },
      divisions: timeList.length - 1,
      values: RangeValues(
        timeList.indexOf(startTime).toDouble(),
        timeList.indexOf(endTime).toDouble(),
      ),
      min: 0,
      max: timeList.length - 1,
      labels: RangeLabels(
        startTime.toString(),
        endTime.toString(),
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
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: onSaveAndExit,
        child: const Text("Save & Exit"),
      ),
    ],
  );
}
