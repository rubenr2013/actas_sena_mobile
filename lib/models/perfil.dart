class Perfil {
  final UsuarioPerfil user;
  final EstadisticasUsuario stats;

  Perfil({
    required this.user,
    required this.stats,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      user: UsuarioPerfil.fromJson(json['user']),
      stats: EstadisticasUsuario.fromJson(json['stats']),
    );
  }
}

class UsuarioPerfil {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String rol;
  final DateTime fechaRegistro;
  final DateTime? ultimoLogin;
  final String? firmaDigital;
  final bool tieneFirma;
  final bool isStaff;
  final bool isSuperuser;

  UsuarioPerfil({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rol,
    required this.fechaRegistro,
    this.ultimoLogin,
    this.firmaDigital,
    required this.tieneFirma,
    this.isStaff = false,
    this.isSuperuser = false,
  });

  factory UsuarioPerfil.fromJson(Map<String, dynamic> json) {
    return UsuarioPerfil(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      rol: json['rol'] ?? '',
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      ultimoLogin: json['ultimo_login'] != null
          ? DateTime.parse(json['ultimo_login'])
          : null,
      firmaDigital: json['firma_digital'],
      tieneFirma: json['tiene_firma'],
      isStaff: json['is_staff'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
    );
  }

  String get nombreCompleto => '$firstName $lastName'.trim();
}

class EstadisticasUsuario {
  final int totalActasCreadas;
  final int actasEnBorrador;
  final int actasFinalizadas;
  final int compromisosAsignados;
  final int compromisosCompletados;
  final int firmasPendientes;

  EstadisticasUsuario({
    required this.totalActasCreadas,
    required this.actasEnBorrador,
    required this.actasFinalizadas,
    required this.compromisosAsignados,
    required this.compromisosCompletados,
    required this.firmasPendientes,
  });

  factory EstadisticasUsuario.fromJson(Map<String, dynamic> json) {
    return EstadisticasUsuario(
      totalActasCreadas: json['total_actas_creadas'],
      actasEnBorrador: json['actas_en_borrador'],
      actasFinalizadas: json['actas_finalizadas'],
      compromisosAsignados: json['compromisos_asignados'],
      compromisosCompletados: json['compromisos_completados'],
      firmasPendientes: json['firmas_pendientes'],
    );
  }
}