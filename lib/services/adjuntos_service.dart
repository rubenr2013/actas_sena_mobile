import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/archivo_adjunto.dart';
import 'api_service.dart';
import '../utils/file_utils.dart';

class AdjuntosService {
  /// Seleccionar archivo desde el dispositivo
  static Future<File?> seleccionarArchivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'jpg',
          'jpeg',
          'png',
          'zip'
        ],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Error al seleccionar archivo: $e');
    }
  }

  /// Subir archivo adjunto a un acta
  static Future<Map<String, dynamic>> subirArchivo({
    required int actaId,
    required File archivo,
    String? descripcion,
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      // Crear request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/actas/api/actas/$actaId/adjuntos/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Agregar archivo
      request.files.add(
        await http.MultipartFile.fromPath('archivo', archivo.path),
      );

      // Agregar descripción si existe
      if (descripcion != null && descripcion.isNotEmpty) {
        request.fields['descripcion'] = descripcion;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'adjunto': ArchivoAdjunto.fromJson(data['adjunto']),
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al subir archivo',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Listar archivos adjuntos de un acta
  static Future<List<ArchivoAdjunto>> listarAdjuntos(int actaId) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/actas/api/actas/$actaId/adjuntos/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final adjuntos = (data['adjuntos'] as List)
            .map((json) => ArchivoAdjunto.fromJson(json))
            .toList();
        return adjuntos;
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para ver estos adjuntos');
      } else {
        throw Exception('Error al cargar adjuntos');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Descargar archivo adjunto
  static Future<String> descargarAdjunto({
    required int actaId,
    required int adjuntoId,
    required String nombreArchivo,
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/actas/api/actas/$actaId/adjuntos/$adjuntoId/descargar/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Usar utilidad para guardar archivo
        final filePath = await FileUtils.saveFile(
          response.bodyBytes,
          nombreArchivo,
        );
        return filePath;
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para descargar este archivo');
      } else if (response.statusCode == 404) {
        throw Exception('Archivo no encontrado');
      } else {
        throw Exception('Error al descargar archivo');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Eliminar archivo adjunto
  static Future<Map<String, dynamic>> eliminarAdjunto({
    required int actaId,
    required int adjuntoId,
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await http.delete(
        Uri.parse(
            '${ApiService.baseUrl}/actas/api/actas/$actaId/adjuntos/$adjuntoId/'),
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
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sesión expirada',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'error': 'No tienes permiso para eliminar este archivo',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al eliminar archivo',
        };
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
