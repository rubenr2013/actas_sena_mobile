class AppConstants {
  // API URLs
  static const String baseUrl = 'http://10.4.219.217:8000';
  static const String loginEndpoint = '/actas/api/auth/login/';
  static const String dashboardEndpoint = '/actas/api/dashboard/'; 
  static const String actasEndpoint = '/actas/api/actas/';
  
  // App Info
  static const String appName = 'SENA Actas';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}