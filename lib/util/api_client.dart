import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart' as foundation;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:gpx/gpx.dart';
import 'package:stasi/api_model/live_gps_point.dart';
import 'package:stasi/api_model/login_data.dart';
import 'package:stasi/api_model/run.dart';
import 'package:stasi/util/app_version.dart';


class ApiClient {
  static final ApiClient _apiClient = ApiClient._internal();

  factory ApiClient() {
    return _apiClient;
  }

  static String getURL() {
    if (foundation.kReleaseMode) {
        return "trekkie.tlm.solutions";
    } else {
        return "trekkie.staging.tlm.solutions";
    }
  }

  static Uri _getTrekkieUri(String trekkieUuid, {String? subPath}) {
    return Uri(
      scheme: "https",
      host: getURL(),
      pathSegments: ["v2", "trekkie", trekkieUuid, subPath ?? ""],
    );
  }

  ApiClient._internal(): _url = getURL();
  final String _url;
  io.Cookie? _cookie;

  Future<void> loginUser(LoginData loginData) async {
    final response = await http.post(
        Uri(scheme: "https", host: _url, path: "/v2/auth/login"),
        body: jsonEncode(loginData.toMap()),
        headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) throw http.ClientException(response.body);
    _updateCookie(response.headers);
  }

  Future<LoginData> createAccount() async {
    final response = await http.post(Uri(scheme: "https", host: _url, path: "/v2/user"));

    if (response.statusCode != 200) throw http.ClientException(response.body);
    _updateCookie(response.headers);

    final responseDict = jsonDecode(response.body);
    return LoginData(userId: responseDict["user_id"], password: responseDict["password"]);
  }

  Future<void> sendGpx(Gpx gpx, Run run) async {
    final trekkieUuid = await _submitRun(run: run);

    final gpxUri = _getTrekkieUri(trekkieUuid, subPath: "gpx");

    final gpxRequest = http.MultipartRequest("POST", gpxUri)
      ..files.add(http.MultipartFile.fromString(
        "yo mama",
        GpxWriter().asString(gpx, pretty: true),
        contentType: MediaType("text", "xml"),
      ))
      ..headers["cookie"] = await _getCookie();

    final gpxResponse = await gpxRequest.send();
    if (gpxResponse.statusCode != 200) {
      final errorCode = gpxResponse.statusCode;
      final errorMessage = await gpxResponse.stream.bytesToString();

      throw http.ClientException("$errorCode: $errorMessage");
    }
  }

  Future<String> createLiveRun(Run run) async {
    final trekkieUuid = await _submitRun(run: run, live: true);
    return trekkieUuid;
  }

  Future<void> finishLiveRun(String trekkieUuid) async {
    final liveUri = _getTrekkieUri(trekkieUuid);

    final liveResponse = await http.delete(Uri(scheme: "https", host: getURL(),
    pathSegments: ["v2", "trekkie", trekkieUuid]),
    headers: {"cookie": await _getCookie()},
    );

    if (liveResponse.statusCode != 200) {
      final errorCode = liveResponse.statusCode;
      final errorMessage = liveResponse.body;

      throw http.ClientException("$errorCode: $errorMessage");
    }
  }

  Future<void> sendLiveCords(String trekkieUuid, LiveGpsPoint liveGpsPoint) async {
    final liveUri = _getTrekkieUri(trekkieUuid, subPath: "live");
    final requestBody = jsonEncode(liveGpsPoint.toMap());
    final liveResponse = await http.post(liveUri,
      headers: {"cookie": await _getCookie()},
      body: requestBody,
    );

    if (liveResponse.statusCode != 200) {
      final errorCode = liveResponse.statusCode;
      final errorMessage = liveResponse.body;

      throw http.ClientException("$errorCode: $errorMessage");
    }
  }

  Future<String> _submitRun({
    required Run run,
    bool live = false,
  }) async {
    final timesJson = {
      "start": run.start.toIso8601String(),
      "stop": run.end.toIso8601String(),
      "line": run.lineNumber,
      "run": run.runNumber,
      "region": run.regionId,
      "app_commit": await AppVersion.getCommitId(),
      "app_name": "stasi",
      "finished": !live,
    };

    final submitResponse = await http.post(
      Uri(scheme: "https", host: _url, path: "/v2/trekkie"),
      headers: {"cookie": await _getCookie(), "Content-Type": "application/json"},
      body: jsonEncode(timesJson),
    );

    if (submitResponse.statusCode != 200) throw http.ClientException(submitResponse.body);

    final trekkieUuid = jsonDecode(submitResponse.body)["trekkie_run"] as String;

    return trekkieUuid;
  }

  void _updateCookie(Map<String, String> headers) {
    _cookie = io.Cookie.fromSetCookieValue(headers["set-cookie"]!);
  }

  Future<void> _refreshCookie() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (userId != null) {
      final password = prefs.getString("password")!;
      await loginUser(LoginData(userId: userId, password: password));
      return;
    }

    final loginData = await createAccount();

    prefs.setString("user_id", loginData.userId);
    prefs.setString("password", loginData.password);
  }

  Future<String> _getCookie() async {
    if (_cookie == null) {
      await _refreshCookie();
    }
    return "${_cookie!.name}=${_cookie!.value}";
  }
}
