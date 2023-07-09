import 'package:flutter/services.dart';

class AppVersion {
  static String? _commitId;

  static Future<String> getCommitId() async {
    _commitId ??= (await rootBundle.loadString(".git/ORIG_HEAD")).trim();
    return _commitId!;
  }
}
