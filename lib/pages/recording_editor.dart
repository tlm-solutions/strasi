import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'package:stasi/db/database_bloc.dart';
import 'package:stasi/widgets/recording_map.dart';
import 'package:stasi/model/recording.dart';


class RecordingEditor extends StatefulWidget {
  const RecordingEditor({
    Key? key,
    required this.databaseBloc,
    required this.recording,
  }) : super(key: key);

  final DatabaseBloc databaseBloc;
  final Recording recording;

  @override
  State<RecordingEditor> createState() => _RecordingEditorState();
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
              initialLineNumber: widget.recording.lineNumber,
              initialRunNumber: widget.recording.runNumber,
              initialStartTime: initialStartTime,
              initialEndTime: initialEndTime,
              onSaveAndExit: ({
                required lineNumber,
                required runNumber,
                required startTime,
                required endTime,
              }) async {
                await widget.databaseBloc.setRecordingBounds(
                  widget.recording.id,
                  startTime: startTime,
                  endTime: endTime,
                );
                await widget.databaseBloc.setRecordingRunAndLineNumber(
                    widget.recording.id,
                    runNumber: runNumber,
                    lineNumber: lineNumber,
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
    return {
      for (final coordinate in await widget.databaseBloc.getCoordinates(widget.recording.id))
        coordinate.time: LatLng(coordinate.latitude, coordinate.longitude)
    };
  }

}

class _RecordingEditorControl extends StatefulWidget {
  const _RecordingEditorControl({
    Key? key,
    required this.points,
    required this.initialLineNumber,
    required this.initialRunNumber,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.onSaveAndExit,
  }) : super(key: key);

  final Map<DateTime, LatLng> points;
  final int? initialLineNumber;
  final int? initialRunNumber;
  final DateTime initialStartTime;
  final DateTime initialEndTime;
  final Future<void> Function({
    required int? lineNumber,
    required int? runNumber,
    required DateTime startTime,
    required DateTime endTime,
  }) onSaveAndExit;

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
        Expanded(
          child: RecordingMap(
            pointList: [
              for (final time in widget.points.keys)
                if (_startTime.compareTo(time) <= 0 && _endTime.compareTo(time) >= 0)
                  widget.points[time]!
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 100,
          ),
          child: Column(
            children: [
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
                flex: 2,
                child: _RecordingEditorButtons(
                  initialLineNumber: widget.initialLineNumber,
                  initialRunNumber: widget.initialRunNumber,
                  onSaveAndExit: (int? lineNumber, int? runNumber) async {
                    await widget.onSaveAndExit(
                      lineNumber: lineNumber,
                      runNumber: runNumber,
                      startTime: _startTime,
                      endTime: _endTime,
                    );
                  },
                ),
              ),
            ],
          ),
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

class _RecordingEditorButtons extends StatefulWidget {
  const _RecordingEditorButtons({
    Key? key,
    required this.initialLineNumber,
    required this.initialRunNumber,
    required this.onSaveAndExit,
  }) : super(key: key);

  final int? initialLineNumber;
  final int? initialRunNumber;
  final void Function(int? lineNumber, int? runNumber) onSaveAndExit;

  @override
  _RecordingEditorButtonsState createState() => _RecordingEditorButtonsState();
}

class _RecordingEditorButtonsState extends State<_RecordingEditorButtons> {
  late TextEditingController _lineNumberController;
  late TextEditingController _runNumberController;

  @override
  void initState() {
    _lineNumberController = TextEditingController(
      text: widget.initialLineNumber != null ? widget.initialLineNumber.toString() : "",
    );
    _runNumberController = TextEditingController(
      text: widget.initialRunNumber != null ? widget.initialRunNumber.toString() : "",
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Flexible(
        flex: 1,
        /*
        Extremely stupid SizedBox workaround to get the TextFormField
        to have the same height as the ElevatedButton.
         */
        child: SizedBox(
          height: 48,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: "line number",
              isDense: true,
            ),
            controller: _lineNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ),
      Flexible(
        flex: 1,
        child: SizedBox(
          height: 48,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: "run number",
              isDense: true,
            ),
            controller: _runNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ),
      Flexible(
        flex: 1,
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final lineNumberContent = _lineNumberController.value.text;
              final lineNumber = lineNumberContent.isNotEmpty ? int.parse(lineNumberContent) : null;

              final runNumberContent = _runNumberController.value.text;
              final runNumber = runNumberContent.isNotEmpty ? int.parse(runNumberContent) : null;

              widget.onSaveAndExit(lineNumber, runNumber);
            },
            child: const Text("Save & Exit"),
          ),
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _lineNumberController.dispose();
    _runNumberController.dispose();
    super.dispose();
  }
}
