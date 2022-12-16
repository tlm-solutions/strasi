import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:background_location/background_location.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stasi/running_recording.dart';


class VehicleSelection extends StatefulWidget {
  final Future<Database> database;

  const VehicleSelection({Key? key, required this.database}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VehicleSelectionState();
}

class _VehicleSelectionState extends State<VehicleSelection> with AutomaticKeepAliveClientMixin<VehicleSelection> {
  int? lineNumber;
  int? runNumber;

  final _dropdownFormKey = GlobalKey<FormState>();
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<RunningRecording>(
      builder: (context, recording, child) {
        final started = recording.recordingId != null;

        return Form(
          key: _dropdownFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "line number"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (String? value) {
                  setState(() {
                    lineNumber = value != null && value.isNotEmpty ? int.parse(value) : null;
                  });

                  if (!started) return;

                  _scheduleUpdateRecording(recording.recordingId!);
                },
                validator: (value) => value != null && value.isNotEmpty ? null : 'Enter the line number',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'run number'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (String? value) {
                  setState(() {
                    runNumber = value != null && value.isNotEmpty ? int.parse(value) : null;
                  });

                  if (!started) return;

                  _scheduleUpdateRecording(recording.recordingId!);
                },
                validator: (value) => value != null && value.isNotEmpty ? null : 'Enter the run number',
              ),
              ElevatedButton(
                onPressed: () async {
                  if(started) {
                    BackgroundLocation.stopLocationService();
                    _killDebounce();
                    recording.setRecordingId(null);
                    return;
                  }

                  final db = await widget.database;
                  final recordingId = await db.insert("recordings", {
                    "line_number": lineNumber,
                    "run_number": runNumber,
                  });

                  recording.setRecordingId(recordingId);

                  BackgroundLocation.setAndroidNotification(
                    title: "Stasi",
                    message: "Stasi is watching you!",
                    icon: "@mipmap/ic_launcher",
                  );
                  BackgroundLocation.setAndroidConfiguration(800);
                  BackgroundLocation.startLocationService();

                  BackgroundLocation.getLocationUpdates((location) async {
                    await db.insert("cords", {
                      "latitude": location.latitude,
                      "longitude": location.longitude,
                      "altitude": location.altitude,
                      "speed": location.speed,
                      "recording_id": recordingId,
                    });
                  });
                },
                child: started ? const Text("WE'RE DONE HERE!") : const Text("LET'S TRACK"),
              )
            ],
          )
        );
      },
    );

  }

  @override
  bool get wantKeepAlive => true;

  void _killDebounce() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
  }

  void _scheduleUpdateRecording(int recordingId) {
    _killDebounce();
    _debounce = Timer(const Duration(seconds: 1), () async {
      _updateRecording(recordingId);
    });
  }

  Future<void> _updateRecording(int recordingId) async {
    final db = await widget.database;

    await db.update(
      "recordings",
      {"run_number": runNumber, "line_number": lineNumber},
      where: "id = ?",
      whereArgs: [recordingId],
    );
  }
}
