class LiveGpsPoint {
  LiveGpsPoint({
    required this.time,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.verticalAccuracy,
    this.bearing,
    this.speed,
  });

  final DateTime time;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? verticalAccuracy;
  final double? bearing;
  final double? speed;

  Map<String, dynamic> toMap() => {
    "time": time.toIso8601String(),
    "lat": latitude,
    "lon": longitude,
    "elevation": altitude,
    "accuracy": accuracy,
    "vertical_accuracy": verticalAccuracy,
    "bearing": bearing,
    "speed": speed,
  };
}
