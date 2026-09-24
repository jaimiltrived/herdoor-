import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Production live server URL hosted on VPS
  static const String liveBaseUrl = 'https://vps.jenili.in/api/v1';

  /// Local development fallback URLs
  static const String localAndroidEmulatorUrl = 'http://10.0.2.2:5000/api/v1';
  static const String localDefaultUrl = 'http://localhost:5000/api/v1';

  /// Configurable via `--dart-define=API_URL=...`
  static const String _envApiUrl =
      String.fromEnvironment('API_URL', defaultValue: '');

  /// Standard network timeout for remote API calls
  static const Duration timeout = Duration(seconds: 15);

  /// Set to true to link app with the live backend server
  /// Can be overridden with `--dart-define=USE_LIVE_SERVER=false` for local offline dev
  static const bool useLiveServer =
      bool.fromEnvironment('USE_LIVE_SERVER', defaultValue: true);

  /// Resolved base URL for all HTTP service calls
  static String get baseUrl {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    if (useLiveServer) {
      return liveBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return localAndroidEmulatorUrl;
    }
    return localDefaultUrl;
  }
}
