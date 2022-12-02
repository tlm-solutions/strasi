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
  int? vehicleNumber;
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
            decoration: const InputDecoration(labelText: "vehicle number"),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (String? value) {
              setState(() {
                vehicleNumber = value != null && value.isNotEmpty ? int.parse(value) : null;
              });
            },
            validator: (value) => value != null && value.isNotEmpty ? null : 'Enter vehicle number',
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

              BackgroundLocation.setAndroidNotification(
                title: "Stasi",
                message: "Stasi is watching you!",
                icon: "@mipmap/ic_launcher"
              );
              BackgroundLocation.setAndroidConfiguration(3000);
              BackgroundLocation.startLocationService();
              BackgroundLocation.getLocationUpdates((location) async {
                final db = await widget.database;
                await db.insert("runs", {
                  "vehicle_number": vehicleNumber,
                  "run_number": runNumber,
                  "latitude": location.latitude,
                  "longitude": location.longitude,
                  "speed": location.speed,
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
