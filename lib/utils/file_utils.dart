import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Utilidades para manejo de archivos
class FileUtils {
  /// Obtiene el directorio de descargas según la plataforma
  ///
  /// En Android: Intenta usar /storage/emulated/0/Download
  /// Si no existe, usa getExternalStorageDirectory()
  /// En iOS: Usa getApplicationDocumentsDirectory()
  static Future<Directory> getDownloadDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Intentar usar el directorio de Downloads estándar
      directory = Directory('/storage/emulated/0/Download');

      if (!await directory.exists()) {
        // Si no existe, usar el directorio externo de la app
        directory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      // En iOS usar el directorio de documentos de la app
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Fallback para otras plataformas
      directory = await getApplicationDocumentsDirectory();
    }

    // Asegurar que el directorio existe
    if (directory != null && !await directory.exists()) {
      await directory.create(recursive: true);
    }

    if (directory == null) {
      throw Exception('No se pudo obtener el directorio de descargas');
    }

    return directory;
  }

  /// Guarda bytes en un archivo
  ///
  /// [bytes] Los bytes a guardar
  /// [filename] El nombre del archivo
  /// [directory] Directorio opcional, si no se provee usa getDownloadDirectory()
  static Future<String> saveFile(
    List<int> bytes,
    String filename, {
    Directory? directory,
  }) async {
    final dir = directory ?? await getDownloadDirectory();
    final filePath = '${dir.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  /// Formatea el tamaño de un archivo en bytes a formato legible
  ///
  /// Ejemplo: 1024 -> "1.00 KB"
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Verifica si un archivo existe
  static Future<bool> fileExists(String path) async {
    final file = File(path);
    return await file.exists();
  }

  /// Elimina un archivo
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
