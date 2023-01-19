class Recording {
  Recording({
    required this.id,
    required this.lineNumber,
    required this.runNumber,
    required this.isUploaded,
    required this.start,
    required this.end,
    required this.totalStart,
    required this.totalEnd,
  });

  int id;
  int? lineNumber;
  int? runNumber;
  bool isUploaded;
  DateTime? start;
  DateTime? end;
  DateTime totalStart;
  DateTime totalEnd;
}
