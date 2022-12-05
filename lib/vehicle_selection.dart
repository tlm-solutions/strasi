import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:background_location/background_location.dart';
import 'package:sqflite/sqflite.dart';


class VehicleSelection extends StatefulWidget {
  final Future<Database> database;

  const VehicleSelection({Key? key, required this.database}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VehicleSelectionState();
}

class _VehicleSelectionState extends State<VehicleSelection> {
  int? lineNumber;
  int? runNumber;
  final _dropdownFormKey = GlobalKey<FormState>();
  bool started = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _dropdownFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            enabled: !started,
            decoration: const InputDecoration(labelText: "line number"),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (String? value) {
              setState(() {
                lineNumber = value != null && value.isNotEmpty ? int.parse(value) : null;
              });
            },
            validator: (value) => value != null && value.isNotEmpty ? null : 'Enter the line number',
          ),
          TextFormField(
            enabled: !started,
            decoration: const InputDecoration(labelText: 'run number'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (String? value) {
              setState(() {
                runNumber = value != null && value.isNotEmpty ? int.parse(value) : null;
              });
            },
            validator: (value) => value != null && value.isNotEmpty ? null : 'Enter the run number',
          ),
          ElevatedButton(
            onPressed: (_dropdownFormKey.currentState == null || !_dropdownFormKey.currentState!.validate()) ? null : () async {
              if(started) {
                BackgroundLocation.stopLocationService();
                setState(() {
                  started = false;
                });
                return;
              }

              setState(() {
                started = true;
              });

              final db = await widget.database;
              final recordingId = await db.insert("recordings", {
                "line_number": lineNumber,
                "run_number": runNumber,
              });

              BackgroundLocation.setAndroidNotification(
                title: "Stasi",
                message: "Stasi is watching you!",
                icon: "@mipmap/ic_launcher",
              );
              BackgroundLocation.setAndroidConfiguration(3000);
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
  }
}
