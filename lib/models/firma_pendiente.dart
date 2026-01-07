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
      firmaId: json['firma_id'],
      acta: ActaFirma.fromJson(json['acta']),
      firmasCompletadas: json['firmas_completadas'],
      porcentajeFirmado: json['porcentaje_firmado'],
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

  factory ActaFirma.fromJson(Map<String, dynamic> json) {
    return ActaFirma(
      id: json['id'],
      numeroActa: json['numero_acta'],
      titulo: json['titulo'],
      fechaReunion: DateTime.parse(json['fecha_reunion']),
      lugarReunion: json['lugar_reunion'],
      tipoReunion: json['tipo_reunion'],
      modalidad: json['modalidad'],
      estado: json['estado'],
      ordenDia: json['orden_dia'] ?? '',
      desarrollo: json['desarrollo'] ?? '',
      observaciones: json['observaciones'] ?? '',
      creador: CreadorInfo.fromJson(json['creador']),
    );
  }
}

class CreadorInfo {
  final String nombreCompleto;
  final String username;

  CreadorInfo({
    required this.nombreCompleto,
    required this.username,
  });

  factory CreadorInfo.fromJson(Map<String, dynamic> json) {
    return CreadorInfo(
      nombreCompleto: json['nombre_completo'],
      username: json['username'],
    );
  }
}
