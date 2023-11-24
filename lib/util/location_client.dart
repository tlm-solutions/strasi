import 'dart:async';
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


Future<bool> _getLocationPermissions() async {
  if (!(await Geolocator.isLocationServiceEnabled())) {
    return false;
  }

  var permissions = await Geolocator.checkPermission();
  if (permissions == LocationPermission.denied) {
    permissions = await Geolocator.requestPermission();
    if (permissions == LocationPermission.denied) {
      return false;
    }
  }

  if (permissions == LocationPermission.deniedForever) {
    return false;
  }

  return Permission.notification.request().isGranted;
}

LocationSettings _getLocationSettings() {
  final locationSettings = Platform.isAndroid ?
    AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
      forceLocationManager: false,
      intervalDuration: const Duration(milliseconds: 500),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: "Strasi",
        notificationText: "Strasi is watching you!",
        enableWakeLock: true,
        setOngoing: true,
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

  Future<bool> getLocationUpdates(Future<void> Function(Position? position) toExec) async {
    await stopLocationUpdates();

    if (!(await _getLocationPermissions())) {
      // definitively gotta create a better system
      return false;
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: _getLocationSettings())
        .listen(toExec);
    return true;
  }

  Future<void> stopLocationUpdates() async {
    await _positionStream?.cancel();
  }
}
