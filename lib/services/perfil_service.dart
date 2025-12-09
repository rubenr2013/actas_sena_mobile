import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/perfil.dart';
import 'api_service.dart';
import '../utils/constants.dart';

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

  static Future<Map<String, dynamic>> actualizarFirma(File imagenFirma) async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'error': 'No autenticado',
        };
      }

      // Crear request multipart
      final uri = Uri.parse('${AppConstants.baseUrl}/actas/api/perfil/actualizar-firma/');
      final request = http.MultipartRequest('POST', uri);
      
      // Agregar headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Determinar el tipo MIME de la imagen
      String mimeType = 'image/jpeg';
      final extension = imagenFirma.path.toLowerCase().split('.').last;
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      }
      
      // Agregar archivo
      final stream = http.ByteStream(imagenFirma.openRead());
      final length = await imagenFirma.length();
      
      final multipartFile = http.MultipartFile(
        'firma_digital',
        stream,
        length,
        filename: 'firma_${DateTime.now().millisecondsSinceEpoch}.$extension',
        contentType: MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
      
      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Actualizar datos locales del usuario con la nueva firma
        final userData = await ApiService.getUserData();
        if (userData != null && data['data'] != null) {
          userData['firma_digital'] = data['data']['firma_digital'];
          userData['tiene_firma'] = true;
          await ApiService.saveUserData(userData);
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Firma actualizada correctamente',
          'firma_url': data['data']['firma_digital'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al actualizar firma',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}