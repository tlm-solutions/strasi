class Recording {
  int id;
  int lineNumber;
  int runNumber;

  Recording({
    required this.id,
    required this.lineNumber,
    required this.runNumber,
  });

  factory Recording.fromDict(Map<String, Object?> dict) =>
    Recording(
      id: dict["id"] as int,
      lineNumber: dict["line_number"] as int,
      runNumber: dict["run_number"] as int,
    );
}
