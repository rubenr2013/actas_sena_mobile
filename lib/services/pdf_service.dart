import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import '../utils/file_utils.dart';

class PdfService {
  /// Descargar PDF del acta
  static Future<String> descargarPdfActa(int actaId) async {
    try {
      // Obtener token
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      // Hacer petición al servidor
      final url = '${ApiService.baseUrl}/actas/api/actas/$actaId/pdf/';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Descargar en móvil (Android/iOS)
        return await _descargarPdfMovil(response.bodyBytes, actaId);
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para descargar esta acta');
      } else if (response.statusCode == 404) {
        throw Exception('Acta no encontrada');
      } else {
        throw Exception('Error al descargar PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al descargar PDF: $e');
    }
  }

  /// Descargar PDF en Flutter Móvil (Android/iOS)
  static Future<String> _descargarPdfMovil(
      List<int> pdfBytes, int actaId) async {
    // Solicitar permisos de almacenamiento
    final permisoOtorgado = await _solicitarPermisos();
    if (!permisoOtorgado) {
      throw Exception(
          'Se necesitan permisos de almacenamiento para descargar el PDF');
    }

    // Crear nombre del archivo con timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'ACTA_${actaId}_$timestamp.pdf';

    // Usar utilidad para guardar archivo
    final filePath = await FileUtils.saveFile(pdfBytes, fileName);

    return filePath;
  }

  /// Solicitar permisos de almacenamiento (solo móvil)
  static Future<bool> _solicitarPermisos() async {
    // Android
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        return true; // Android 13+ no requiere permisos para Downloads
      }

      // Android 12 y anteriores
      final status = await Permission.storage.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return true; // iOS maneja permisos automáticamente
  }

  /// Obtener versión de Android
  static Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      return 33; // Por defecto asumimos Android 13+
    }
    return 0;
  }
}
