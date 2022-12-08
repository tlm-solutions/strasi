import 'package:flutter/material.dart';

class RunningRecording extends ChangeNotifier {
  int? _recordingId;

  int? get recordingId => _recordingId;

  void setRecordingId(int? recordingId) {
    _recordingId = recordingId;
    notifyListeners();
  }
}
