import 'dart:async';
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';


LocationSettings _getLocationSettings() {
  final locationSettings = Platform.isAndroid ?
    AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
      forceLocationManager: true,
      intervalDuration: const Duration(seconds: 2),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "Stasi",
        notificationText: "Stasi is watching you!",
      ),
    ) :
    AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.automotiveNavigation,
    );

  return locationSettings;
}

class LocationClient {
  /*
  Garbage Singleton.
  This is one of the most ugliest things I ever wrote.
  REWRITE! REWRITE! REWRITE!
  But y'all are forcing my hand.
   */

  static final LocationClient _locationClient = LocationClient._internal();

  factory LocationClient() {
    return _locationClient;
  }

  LocationClient._internal();

  StreamSubscription<Position>? _positionStream;

  bool get locationUpdatesRunning => _positionStream != null;

  Future<void> getLocationUpdates(Future<void> Function(Position position) toExec) async {
    await stopLocationUpdates();
    _positionStream = Geolocator.getPositionStream(locationSettings: _getLocationSettings())
        .listen(toExec);
  }

  Future<void> stopLocationUpdates() async {
    await _positionStream?.cancel();
  }
}
