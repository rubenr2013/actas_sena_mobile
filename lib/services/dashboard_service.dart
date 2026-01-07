import 'dart:convert';
import '../models/dashboard.dart';
import 'api_service.dart';

class DashboardService {
  static Future<DashboardData> getDashboard() async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.get(
        '/actas/api/dashboard/',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardData.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error al cargar dashboard');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
