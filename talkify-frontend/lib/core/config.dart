/// App Configuration
/// Contains all configuration constants for the app
class AppConfig {
  // Backend Configuration
  static const String backendBaseUrl = 'http://192.168.0.229:3008';
  static const String apiBaseUrl = '$backendBaseUrl/api';
  static const String socketBaseUrl = backendBaseUrl;
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String usersEndpoint = '/users/getUserList';
  static const String profileEndpoint = '/profile';
  static const String fcmTokenEndpoint = '/fcm-token';
  static const String logoutEndpoint = '/logout';
  static const String refreshTokenEndpoint = '/refresh-token';
  
  // Socket.IO Events
  static const String callUserEvent = 'call-user';
  static const String answerCallEvent = 'answer-call';
  static const String endCallEvent = 'end-call';
  static const String iceCandidateEvent = 'ice-candidate';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration socketTimeout = Duration(seconds: 60);
  
  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Debug Configuration
  static const bool enableDebugLogs = true;
  static const bool enableApiLogs = true;
  static const bool enableSocketLogs = true;
}
