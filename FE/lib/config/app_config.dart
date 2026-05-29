import 'dart:io';

/// Environment configuration for the application
class AppConfig {
  // Backend API Configuration
  // Android emulator routes localhost → 10.0.2.2 (host machine)
  static String get backendBaseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';
  static String get apiBase => '$backendBaseUrl/api';

  // Feature flags
  static const bool enableLogging = true;
  static const bool debugMode = true;

  // Timeout values (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
}
