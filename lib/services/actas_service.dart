import 'dart:convert';
import '../models/acta.dart';
import 'api_service.dart';

class ActasService {
  static Future<List<Acta>> getActas({
    String? estado,
    String? search,
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      // Construir query parameters de forma segura
      Map<String, dynamic> queryParams = {};
      if (estado != null && estado != 'todos') {
        queryParams['estado'] = estado;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Construir la URL con codificación correcta
      String endpoint = '/actas/api/actas/';
      if (queryParams.isNotEmpty) {
        final uri = Uri(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
        endpoint += uri.toString();
      }

      final response = await ApiService.get(
        endpoint,
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final actasList = (data['data']['actas'] as List)
            .map((json) => Acta.fromJson(json))
            .toList();
        return actasList;
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error al cargar actas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<ActaDetalle> getActaDetalle(int actaId) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.get(
        '/actas/api/actas/$actaId/',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ActaDetalle.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para ver esta acta');
      } else if (response.statusCode == 404) {
        throw Exception('Acta no encontrada');
      } else {
        throw Exception('Error al cargar acta');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.get(
        '/actas/api/usuarios/',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Error al cargar usuarios');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> crearActa({
    required String titulo,
    required String fechaReunion,
    required String lugarReunion,
    required String tipoReunion,
    required String modalidad,
    String ordenDia = '',
    String desarrollo = '',
    String observaciones = '',
    List<Map<String, dynamic>> participantes = const [],
    bool generadaConIa = false,
    String promptOriginal = '',
    String modeloIaUsado = '',
  }) async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.post(
        '/actas/api/actas/crear/',
        {
          'titulo': titulo,
          'fecha_reunion': fechaReunion,
          'lugar_reunion': lugarReunion,
          'tipo_reunion': tipoReunion,
          'modalidad': modalidad,
          'orden_dia': ordenDia,
          'desarrollo': desarrollo,
          'observaciones': observaciones,
          'participantes': participantes,
          'generada_con_ia': generadaConIa,
          'prompt_original': promptOriginal,
          'modelo_ia_usado': modeloIaUsado,
        },
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'acta_id': data['data']['acta_id'],
          'numero_acta': data['data']['numero_acta'],
        };
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al crear acta');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> generarConIA(String prompt) async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.post(
        '/actas/api/actas/generar-ia/',
        {'prompt': prompt},
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          // ✅ CAMBIO: Ahora recibimos orden_dia y desarrollo por separado
          'orden_dia': data['data']['orden_dia'],      // ← NUEVO
          'desarrollo': data['data']['desarrollo'],    // ← NUEVO
          'modelo_usado': data['data']['modelo_usado'],
        };
      }
      else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al generar con IA');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<bool> cambiarEstadoActa({
    required int actaId,
    required String nuevoEstado,
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.post(
        '/actas/api/actas/$actaId/cambiar-estado/',
        {'estado': nuevoEstado},
        token: token,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al cambiar estado');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> editarActa({
    required int actaId,
    required String titulo,
    required String fechaReunion,
    required String lugarReunion,
    required String tipoReunion,
    required String modalidad,
    String ordenDia = '',
    String desarrollo = '',
    String observaciones = '',
    List<Map<String, dynamic>> participantes = const [],
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.put(
        '/actas/api/actas/$actaId/editar/',
        {
          'titulo': titulo,
          'fecha_reunion': fechaReunion,
          'lugar_reunion': lugarReunion,
          'tipo_reunion': tipoReunion,
          'modalidad': modalidad,
          'orden_dia': ordenDia,
          'desarrollo': desarrollo,
          'observaciones': observaciones,
          'participantes': participantes,
        },
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'cambios_realizados': data['data']['cambios_realizados'],
        };
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al editar acta');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}