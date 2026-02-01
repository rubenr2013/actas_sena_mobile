class FirmaPendiente {
  final int firmaId;
  final ActaFirma acta;
  final String firmasCompletadas;
  final int porcentajeFirmado;

  FirmaPendiente({
    required this.firmaId,
    required this.acta,
    required this.firmasCompletadas,
    required this.porcentajeFirmado,
  });

  factory FirmaPendiente.fromJson(Map<String, dynamic> json) {
    return FirmaPendiente(
      firmaId: json['firma_id'] ?? 0,
      acta: json['acta'] != null
          ? ActaFirma.fromJson(json['acta'])
          : ActaFirma.empty(),
      firmasCompletadas: json['firmas_completadas'] ?? '0/0',
      porcentajeFirmado: json['porcentaje_firmado'] ?? 0,
    );
  }
}

class ActaFirma {
  final int id;
  final String numeroActa;
  final String titulo;
  final DateTime fechaReunion;
  final String lugarReunion;
  final String tipoReunion;
  final String modalidad;
  final String estado;
  final String ordenDia;
  final String desarrollo;
  final String observaciones;
  final CreadorInfo creador;

  ActaFirma({
    required this.id,
    required this.numeroActa,
    required this.titulo,
    required this.fechaReunion,
    required this.lugarReunion,
    required this.tipoReunion,
    required this.modalidad,
    required this.estado,
    required this.ordenDia,
    required this.desarrollo,
    required this.observaciones,
    required this.creador,
  });

  factory ActaFirma.empty() {
    return ActaFirma(
      id: 0,
      numeroActa: '',
      titulo: '',
      fechaReunion: DateTime.now(),
      lugarReunion: '',
      tipoReunion: '',
      modalidad: '',
      estado: '',
      ordenDia: '',
      desarrollo: '',
      observaciones: '',
      creador: CreadorInfo.empty(),
    );
  }

  factory ActaFirma.fromJson(Map<String, dynamic> json) {
    return ActaFirma(
      id: json['id'] ?? 0,
      numeroActa: json['numero_acta'] ?? '',
      titulo: json['titulo'] ?? '',
      fechaReunion: _parseDate(json['fecha_reunion']),
      lugarReunion: json['lugar_reunion'] ?? '',
      tipoReunion: json['tipo_reunion'] ?? '',
      modalidad: json['modalidad'] ?? '',
      estado: json['estado'] ?? '',
      ordenDia: json['orden_dia'] ?? '',
      desarrollo: json['desarrollo'] ?? '',
      observaciones: json['observaciones'] ?? '',
      creador: json['creador'] != null
          ? CreadorInfo.fromJson(json['creador'])
          : CreadorInfo.empty(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

class CreadorInfo {
  final String nombreCompleto;
  final String username;

  CreadorInfo({
    required this.nombreCompleto,
    required this.username,
  });

  factory CreadorInfo.empty() {
    return CreadorInfo(
      nombreCompleto: '',
      username: '',
    );
  }

  factory CreadorInfo.fromJson(Map<String, dynamic> json) {
    return CreadorInfo(
      nombreCompleto: json['nombre_completo'] ?? '',
      username: json['username'] ?? '',
    );
  }
}
