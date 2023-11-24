import 'package:strasi/api_model/run.dart';

class Recording {
  Recording({
    required this.id,
    required this.lineNumber,
    required this.runNumber,
    required this.regionId,
    required this.isUploaded,
    required this.start,
    required this.end,
    required this.totalStart,
    required this.totalEnd,
  });

  int id;
  int? lineNumber;
  int? runNumber;
  int? regionId;
  bool isUploaded;
  DateTime? start;
  DateTime? end;
  DateTime totalStart;
  DateTime totalEnd;

  bool canConvertToRun() =>
      lineNumber != null
      && runNumber != null
      && regionId != null;

  Run? toRun() => canConvertToRun() ? Run(
      lineNumber: lineNumber!,
      runNumber: runNumber!,
      regionId: regionId!,
      start: start ?? totalStart,
      end: end ?? totalEnd,
  ) : null;
}
