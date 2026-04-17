import "package:flutter/foundation.dart";

class AppConfig {
  static String get apiBaseUrl {
    const overrideUrl = String.fromEnvironment("API_BASE_URL", defaultValue: "");
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.0.2.2:8000";
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return "http://127.0.0.1:8000";
      case TargetPlatform.fuchsia:
        return "http://127.0.0.1:8000";
    }
  }
}
