import 'package:flutter/material.dart';

enum TrackingKind {
  recording,
  live,
}


class TrackingStateNotifier extends ChangeNotifier {
  int? _recordingId;
  String? _trekkieUuid;

  TrackingKind? get trackingKind {
    if (_recordingId != null) return TrackingKind.recording;
    if (_trekkieUuid != null) return TrackingKind.live;
    return null;
  }

  int? get recordingId => _recordingId;
  String? get trekkieUuid => _trekkieUuid;

  void setRecordingId(int recordingId) {
    _trekkieUuid = null;
    _recordingId = recordingId;
    notifyListeners();
  }

  void setTrekkieUuid(String trekkieId) {
    _recordingId = null;
    _trekkieUuid = trekkieId;
    notifyListeners();
  }

  void setEmpty() {
    _recordingId = null;
    _trekkieUuid = null;
    notifyListeners();
  }
}
