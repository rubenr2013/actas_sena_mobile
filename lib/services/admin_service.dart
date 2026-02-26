import 'dart:convert';
import '../models/admin_usuario.dart';
import 'api_service.dart';

class AdminService {
  // ── Lista de usuarios ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUsuarios({
    String? rol,
    bool? verificado,
    bool? aprobado,
    String? buscar,
  }) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }

    final params = <String, String>{};
    if (rol != null && rol.isNotEmpty) params['rol'] = rol;
    if (verificado != null) params['verificado'] = verificado.toString();
    if (aprobado != null) params['aprobado'] = aprobado.toString();
    if (buscar != null && buscar.isNotEmpty) params['buscar'] = buscar;

    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await ApiService.get(
      '/actas/api/admin/usuarios/$query',
      token: token,
    );

    final data = json.decode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permisos de administrador');
    }
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Error al obtener usuarios');
    }

    final usuarios = (data['data'] as List)
        .map((u) => AdminUsuario.fromJson(u))
        .toList();

    return {'total': data['total'] ?? usuarios.length, 'usuarios': usuarios};
  }

  // ── Detalle de un usuario ────────────────────────────────────────────────
  static Future<AdminUsuario> getUsuarioDetalle(int id) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }

    final response = await ApiService.get(
      '/actas/api/admin/usuarios/$id/',
      token: token,
    );

    final data = json.decode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permisos de administrador');
    }
    if (response.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    }
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Error al obtener detalle del usuario');
    }

    return AdminUsuario.fromJson(data['data']);
  }

  // ── Aprobar / rechazar cuenta ────────────────────────────────────────────
  static Future<Map<String, dynamic>> aprobarCuenta(
      int id, bool aprobar) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }

    final response = await ApiService.post(
      '/actas/api/admin/usuarios/$id/aprobar/',
      {'aprobar': aprobar},
      token: token,
    );

    final data = json.decode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para esta acción');
    }
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
          data['error'] ?? 'Error al ${aprobar ? 'aprobar' : 'rechazar'} cuenta');
    }

    return data;
  }

  // ── Activar / desactivar usuario ─────────────────────────────────────────
  static Future<Map<String, dynamic>> activarUsuario(
      int id, bool activar) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }

    final response = await ApiService.post(
      '/actas/api/admin/usuarios/$id/activar/',
      {'activar': activar},
      token: token,
    );

    final data = json.decode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }
    if (response.statusCode == 403) {
      throw Exception(
          data['error'] ?? 'No tienes permisos para esta acción');
    }
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
          data['error'] ??
              'Error al ${activar ? 'activar' : 'desactivar'} usuario');
    }

    return data;
  }

  // ── Cambiar rol ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> cambiarRol(int id, String rol) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }

    final response = await ApiService.patch(
      '/actas/api/admin/usuarios/$id/rol/',
      {'rol': rol},
      token: token,
    );

    final data = json.decode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }
    if (response.statusCode == 403) {
      throw Exception('No tienes permisos para esta acción');
    }
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Error al cambiar el rol');
    }

    return data;
  }

  // ── Eliminar usuario ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> eliminarUsuario(int id) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }

    final response = await ApiService.delete(
      '/actas/api/admin/usuarios/$id/eliminar/',
      token: token,
    );

    final data = json.decode(response.body);

    if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor inicia sesión');
    }
    if (response.statusCode == 403) {
      throw Exception(
          data['error'] ?? 'No tienes permisos para eliminar este usuario');
    }
    if (response.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    }
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Error al eliminar el usuario');
    }

    return data;
  }
}
