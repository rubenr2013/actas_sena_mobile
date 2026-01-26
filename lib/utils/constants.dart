class AppConstants {
  // API URLs
  // Para emulador Android usa: http://10.0.2.2:8000
  // Para dispositivo físico en la misma red usa: http://192.168.X.X:8000 (cambia X por tu IP local)
  // Para producción o pruebas externas usa el dominio/ngrok correspondiente

  //static const String baseUrl = 'http://10.0.2.2:8000'; // Emulador Android
  // static const String baseUrl = 'http://192.168.1.100:8000'; // Dispositivo físico (ejemplo)
   static const String baseUrl = 'https://aprioristic-noninferentially-ralph.ngrok-free.dev'; // ngrok (temporal)

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
