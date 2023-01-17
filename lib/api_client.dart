import 'dart:convert';
import 'dart:io' as io;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:gpx/gpx.dart';

import 'database_manager.dart';


class LoginData {
  const LoginData({
    required this.userId,
    required this.password,
  });

  final String userId;
  final String password;

  Map<String, String> toMap() => {"user_id": userId, "password": password};
}


class ApiClient {
  static final ApiClient _apiClient = ApiClient._internal();

  factory ApiClient() {
    return _apiClient;
  }

  ApiClient._internal(): _url = "trekkie.staging.dvb.solutions";

  final String _url;
  io.Cookie? _cookie;

  Future<void> loginUser(LoginData loginData) async {
    final response = await http.post(
        Uri(scheme: "https", host: _url, path: "/user/login"),
        body: jsonEncode(loginData.toMap()),
        headers: {"Content-Type": "application/json"}
    );

    if (response.statusCode != 200) throw http.ClientException(response.body);
    _updateCookie(response.headers);
  }

  Future<LoginData?> createAccount() async {
    final response = await http.post(Uri(scheme: "https", host: _url, path: "/user/create"));
    if (response.statusCode != 200) throw http.ClientException(response.body);
    _updateCookie(response.headers);
    final responseDict = jsonDecode(response.body);
    return LoginData(userId: responseDict["user_id"], password: responseDict["password"]);
  }

  Future<void> sendGpx(Gpx gpx, Recording recording) async {
    final gpxUri = Uri(scheme: "https", host: _url, path: "/travel/submit/gpx");

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

    final timesJson = {
      "gpx_id": jsonDecode(await gpxResponse.stream.bytesToString())["gpx_id"],
      "vehicles": [{
        "start": recording.totalStart.toIso8601String(),
        "stop": recording.totalEnd.toIso8601String(),
        "line": recording.lineNumber,
        "run": recording.runNumber,
        "region": 0,
      }]
    };

    final submitResponse = await http.post(
      Uri(scheme: "https", host: _url, path: "/travel/submit/run"),
      headers: {"cookie": await _getCookie(), "Content-Type": "application/json"},
      body: jsonEncode(timesJson),
    );

    if (submitResponse.statusCode != 200) throw http.ClientException(submitResponse.body);
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

    final loginData = (await createAccount())!;

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
