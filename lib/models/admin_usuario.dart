class AdminUsuario {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String nombreCompleto;
  final String rol;
  final String? centro;
  final String? telefono;
  final bool emailVerificado;
  final bool cuentaAprobada;
  final bool activo;
  final bool isActive;
  final DateTime? fechaRegistro;
  final DateTime? ultimoLogin;
  final bool tieneFirma;
  final String? firmaDigital;
  final AdminStats? stats;

  AdminUsuario({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.nombreCompleto,
    required this.rol,
    this.centro,
    this.telefono,
    required this.emailVerificado,
    required this.cuentaAprobada,
    required this.activo,
    required this.isActive,
    this.fechaRegistro,
    this.ultimoLogin,
    required this.tieneFirma,
    this.firmaDigital,
    this.stats,
  });

  factory AdminUsuario.fromJson(Map<String, dynamic> json) {
    return AdminUsuario(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      rol: json['rol'] ?? 'aprendiz',
      centro: json['centro'],
      telefono: json['telefono'],
      emailVerificado: json['email_verificado'] ?? false,
      cuentaAprobada: json['cuenta_aprobada'] ?? false,
      activo: json['activo'] ?? true,
      isActive: json['is_active'] ?? true,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'])
          : null,
      ultimoLogin: json['ultimo_login'] != null
          ? DateTime.tryParse(json['ultimo_login'])
          : null,
      tieneFirma: json['tiene_firma'] ?? false,
      firmaDigital: json['firma_digital'],
      stats: json['stats'] != null ? AdminStats.fromJson(json['stats']) : null,
    );
  }

  String get iniciales {
    final nombre = nombreCompleto.isNotEmpty ? nombreCompleto : username;
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }
}

class AdminStats {
  final int totalActasCreadas;
  final int firmasPendientes;
  final int compromisosAsignados;
  final int compromisosCompletados;

  AdminStats({
    required this.totalActasCreadas,
    required this.firmasPendientes,
    required this.compromisosAsignados,
    required this.compromisosCompletados,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalActasCreadas: json['total_actas_creadas'] ?? 0,
      firmasPendientes: json['firmas_pendientes'] ?? 0,
      compromisosAsignados: json['compromisos_asignados'] ?? 0,
      compromisosCompletados: json['compromisos_completados'] ?? 0,
    );
  }
}
