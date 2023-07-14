class LoginData {
  const LoginData({
    required this.userId,
    required this.password,
  });

  final String userId;
  final String password;

  Map<String, String> toMap() => {"user_id": userId, "password": password};
}
