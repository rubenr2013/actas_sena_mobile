import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../utils/file_utils.dart';

class BackupGeneralService {
  /// Listar todos los backups disponibles en el servidor
  static Future<Map<String, dynamic>> listarBackups() async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/actas/api/admin/backups/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'backups': data['backups'],
          'total': data['total'],
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'No tienes permisos de administrador',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al listar backups',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Crear un nuevo backup de la base de datos
  static Future<Map<String, dynamic>> crearBackup() async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/actas/api/admin/backups/crear/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'filename': data['filename'],
          'size': data['size'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al crear backup',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Descargar un backup específico
  static Future<Map<String, dynamic>> descargarBackup(String filename) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/actas/api/admin/backups/descargar/$filename/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Usar utilidad para guardar archivo
        final filePath = await FileUtils.saveFile(
          response.bodyBytes,
          filename,
        );

        return {
          'success': true,
          'message': 'Backup descargado correctamente',
          'filepath': filePath,
          'filename': filename,
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'error': data['error'] ?? 'Error al descargar backup',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Restaurar base de datos desde un backup
  static Future<Map<String, dynamic>> restaurarBackup(
    String filename,
    String confirmacion,
  ) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/actas/api/admin/backups/restaurar/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'filename': filename,
          'confirmacion': confirmacion,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al restaurar backup',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar un backup
  static Future<Map<String, dynamic>> eliminarBackup(String filename) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.delete(
        Uri.parse(
            '${ApiService.baseUrl}/actas/api/admin/backups/eliminar/$filename/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al eliminar backup',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
