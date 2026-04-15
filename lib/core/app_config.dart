class AppConfig {
  // For Android emulator use 10.0.2.2, for real devices use your PC's local IP.
  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://10.0.2.2:8000",
  );
}
