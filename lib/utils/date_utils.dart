import 'package:flutter/foundation.dart';

/// Utilidades para manejo seguro de fechas
class DateParseUtils {
  /// Parsea una fecha de forma segura, retornando null si falla
  ///
  /// Soporta múltiples formatos:
  /// - ISO 8601: "2024-01-15T10:30:00Z"
  /// - Con timezone: "2024-01-15T10:30:00+05:00"
  /// - Solo fecha: "2024-01-15"
  /// - Con milisegundos: "2024-01-15T10:30:00.123Z"
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      if (value.isEmpty) return null;

      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ DateParseUtils: Error parseando fecha: $value - $e');
        }
        return null;
      }
    }

    return null;
  }

  /// Parsea una fecha de forma segura con valor por defecto
  ///
  /// Si el parsing falla, retorna [defaultValue] o DateTime.now()
  static DateTime parseOrDefault(dynamic value, [DateTime? defaultValue]) {
    return tryParse(value) ?? defaultValue ?? DateTime.now();
  }

  /// Parsea una fecha requerida, lanzando excepción si falla
  ///
  /// Usar solo cuando la fecha es absolutamente necesaria
  static DateTime parseRequired(dynamic value, String fieldName) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Campo "$fieldName" tiene fecha inválida: $value');
    }
    return parsed;
  }
}
