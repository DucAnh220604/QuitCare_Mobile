import 'package:flutter/foundation.dart';

/// Environment configuration for the application
class AppConfig {
  static String get backendBaseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static String get apiBase => '$backendBaseUrl/api';

  static const bool enableLogging = true;
  static const bool debugMode = true;

  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}
