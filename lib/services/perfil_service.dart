import 'dart:convert';
import '../models/perfil.dart';
import 'api_service.dart';

class PerfilService {
  static Future<Perfil> getPerfil() async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.get(
        '/actas/api/perfil/',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Perfil.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error al cargar perfil');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<bool> actualizarPerfil({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.put(
        '/actas/api/perfil/',
        {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
        },
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Actualizar datos guardados localmente
        await ApiService.saveUserData(data['user']);
        return true;
      } else {
        throw Exception('Error al actualizar perfil');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}