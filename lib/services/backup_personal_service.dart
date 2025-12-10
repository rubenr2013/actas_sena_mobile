import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class BackupPersonalService {
  /// Exportar datos del usuario
  static Future<Map<String, dynamic>> exportarDatos() async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/actas/api/perfil/exportar-datos/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Obtener directorio de descargas
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        // Generar nombre de archivo
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'backup_personal_$timestamp.zip';
        final filePath = '${directory!.path}/$filename';

        // Guardar archivo
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return {
          'success': true,
          'message': 'Backup exportado correctamente',
          'filepath': filePath,
          'filename': filename,
        };
      } else {
        throw Exception('Error al exportar datos');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Validar archivo de backup antes de importar
  static Future<Map<String, dynamic>> validarBackup(String filePath) async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado');
      }

      // Crear request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/actas/api/perfil/importar-datos/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('backup_file', filePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'stats': data['stats'],
          'advertencia': data['advertencia'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al validar backup',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Confirmar e importar datos
  static Future<Map<String, dynamic>> confirmarImportacion(String filePath) async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Archivo no encontrado');
      }

      // Crear request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/actas/api/perfil/confirmar-importacion/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('backup_file', filePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'stats': data['stats'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al importar datos',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}