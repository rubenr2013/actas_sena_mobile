class AppConstants {
  // API URLs
  // Para desarrollo local (emulador Android): http://10.0.2.2:8000
  // Para dispositivo físico en red local: http://192.168.X.X:8000
  // Para producción (AWS Elastic Beanstalk):

  // static const String baseUrl = 'http://10.0.2.2:8000'; // Emulador Android
  // static const String baseUrl = 'http://192.168.1.100:8000'; // Dispositivo físico
  static const String baseUrl = 'http://sistema-actas-env.eba-yjpjmjq2.us-east-2.elasticbeanstalk.com'; // AWS Producción

  static const String loginEndpoint = '/actas/api/auth/login/';
  static const String dashboardEndpoint = '/actas/api/dashboard/';
  static const String actasEndpoint = '/actas/api/actas/';

  // App InfoW
  static const String appName = 'SENA Actas';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
