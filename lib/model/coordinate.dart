class Coordinate {
  Coordinate({
    required this.id,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.recordingId,
  });

  final int id;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final int recordingId;
}
