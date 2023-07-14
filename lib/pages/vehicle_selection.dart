import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stasi/api_model/live_gps_point.dart';

import 'package:stasi/notifiers/tracking_state_notifier.dart';
import 'package:stasi/db/database_bloc.dart';
import 'package:stasi/util/api_client.dart';
import 'package:stasi/util/location_client.dart';

import '../api_model/run.dart';


const _minimumAccuracy = 62;


class _IntegerTextField extends StatefulWidget {
  const _IntegerTextField({
    required this.fieldName,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  final String fieldName;
  final ValueChanged<int?> onChanged;

  @override
  State<StatefulWidget> createState() => _IntegerTextFieldState();
}

class _IntegerTextFieldState extends State<_IntegerTextField> {

  @override
  Widget build(BuildContext context) => TextFormField(
    decoration: InputDecoration(labelText: widget.fieldName),
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: (String value) {
        widget.onChanged(value.isNotEmpty ? int.parse(value) : null);
    },
    validator: (value) => value != null && value.isNotEmpty ? null : 'Enter the ${widget.fieldName}',
  );

}

class VehicleSelection extends StatefulWidget {
  final DatabaseBloc databaseBloc;

  const VehicleSelection({Key? key, required this.databaseBloc}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VehicleSelectionState();
}


class _VehicleSelectionState extends State<VehicleSelection> with AutomaticKeepAliveClientMixin<VehicleSelection> {
  int? lineNumber;
  int? runNumber;
  int regionId = 0;

  final _dropdownFormKey = GlobalKey<FormState>();
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<TrackingStateNotifier>(
      builder: (context, recording, child) {
        final started = recording.recordingId != null;

        return Form(
          key: _dropdownFormKey,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IntegerTextField(
                    fieldName: "line number",
                    onChanged: (int? lineNumber) {
                      setState(() {
                        this.lineNumber = lineNumber;
                      });

                      if (!started) return;

                      _scheduleUpdateRecording(recording.recordingId!);
                    },
                  ),
                  _IntegerTextField(
                    fieldName: 'run number',
                    onChanged: (int? runNumber) {
                      setState(() {
                        this.runNumber = runNumber;
                      });

                      if (!started) return;

                      _scheduleUpdateRecording(recording.recordingId!);
                    },
                  ),
                  DropdownButton<int>(
                    value: regionId,
                    alignment: AlignmentDirectional.bottomEnd,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Center(child: Text("Dresden")),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Center(child: Text("Chemnitz")),
                      ),
                    ],
                    onChanged: (newRegion) {
                      setState(() {
                        regionId = newRegion ?? 0;
                      });

                      if (!started) return;

                      _scheduleUpdateRecording(recording.recordingId!);
                    },
                  ),
                  ElevatedButton(
                    onPressed: recording.trackingKind == TrackingKind.live ? null : () async {
                      if (started) {
                        await LocationClient().stopLocationUpdates();
                        _killDebounce();
                        await widget.databaseBloc.cleanRecording(recording.recordingId!);
                        recording.setEmpty();
                        return;
                      }

                      final recordingId = await widget.databaseBloc.createRecording(
                        runNumber: runNumber,
                        lineNumber: lineNumber,
                        regionId: regionId,
                      );

                      recording.setRecordingId(recordingId);

                      final permissionSuccess = await LocationClient().getLocationUpdates(
                          (position) async {
                            /*
                             * This skips the location values while the
                             * gps chip is still calibrating.
                             * Haven't tested this on IOS yet.
                             */

                            if (position == null) {
                              debugPrint("Unknown location!");
                              return;
                            }

                            if (position.accuracy > _minimumAccuracy) {
                              debugPrint("Too inaccurate location: ${position.accuracy} (> $_minimumAccuracy)");
                              return;
                            }

                            await widget.databaseBloc.createCoordinate(recordingId,
                              latitude: position.latitude,
                              longitude: position.longitude,
                              altitude: position.altitude,
                              speed: position.speed,
                            );
                            debugPrint("Created coordinate ${position.latitude} ${position.longitude}");
                          }
                      );

                      if (!permissionSuccess) {
                        recording.setEmpty();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Couldn't start location services because of missing permissions!")),
                          );
                        }
                      }
                    },
                    child: recording.trackingKind == TrackingKind.recording ? const Text("LEAVING VEHICLE") : const Text("ENTERING VEHICLE"),
                  ),
                  ElevatedButton(
                    onPressed: recording.trackingKind == TrackingKind.recording
                        || runNumber == null
                        || lineNumber == null ? null : () async {
                      if (started) {
                        await LocationClient().stopLocationUpdates();
                        await ApiClient().finishLiveRun(recording.trekkieUuid!);
                        _killDebounce();
                        recording.setEmpty();
                        return;
                      }

                      final apiClient = ApiClient();
                      final trekkieUuid = await apiClient.createLiveRun(Run(
                        runNumber: runNumber!,
                        lineNumber: lineNumber!,
                        regionId: regionId,
                        start: DateTime(0),
                        end: DateTime(0),
                      ));

                      recording.setTrekkieUuid(trekkieUuid);

                      final permissionSuccess = await LocationClient().getLocationUpdates((position) async {
                        /*
                         * This skips the location values while the
                         * gps chip is still calibrating.
                         * Haven't tested this on IOS yet.
                         */

                        if (position == null) {
                          debugPrint("Unknown location!");
                          return;
                        }

                        if (position.accuracy > _minimumAccuracy) {
                          debugPrint("Too inaccurate location: ${position.accuracy} (> $_minimumAccuracy)");
                          return;
                        }
                        
                        await apiClient.sendLiveCords(trekkieUuid, LiveGpsPoint(
                          time: position.timestamp!,
                          latitude: position.latitude,
                          longitude: position.longitude,
                          altitude: position.altitude,
                          accuracy: position.accuracy,
                          speed: position.speed,
                        ));
                        debugPrint("Send coordinate ${position.latitude} ${position.longitude}");
                      });

                      if (!permissionSuccess) {
                        await apiClient.finishLiveRun(trekkieUuid);
                        recording.setEmpty();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Couldn't start location services because of missing permissions!")),
                          );
                        }
                      }
                    },
                    child: recording.trackingKind == TrackingKind.live ? const Text("End live tracking") :  const Text("Live tracking")
                  ),
                ],
              ),
            ),
          ),
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
    await widget.databaseBloc.setRecordingRunAndLineNumber(
      recordingId,
      runNumber: runNumber,
      lineNumber: lineNumber,
    );

    await widget.databaseBloc.setRecordingRegionId(recordingId, regionId);
  }
}
