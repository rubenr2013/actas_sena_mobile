import 'package:flutter/material.dart';

class Acta {
  final int id;
  final String numeroActa;
  final String titulo;
  final String tipoReunion;
  final String estado;
  final DateTime fechaReunion;
  final DateTime fechaCreacion;
  final String lugarReunion;
  final String modalidad;
  final bool generadaConIa;
  final Creador creador;
  final EstadisticasFirmas estadisticasFirmas;

  Acta({
    required this.id,
    required this.numeroActa,
    required this.titulo,
    required this.tipoReunion,
    required this.estado,
    required this.fechaReunion,
    required this.fechaCreacion,
    required this.lugarReunion,
    required this.modalidad,
    required this.generadaConIa,
    required this.creador,
    required this.estadisticasFirmas,
  });

  factory Acta.fromJson(Map<String, dynamic> json) {
    return Acta(
      id: json['id'],
      numeroActa: json['numero_acta'],
      titulo: json['titulo'],
      tipoReunion: json['tipo_reunion'],
      estado: json['estado'],
      fechaReunion: DateTime.parse(json['fecha_reunion']),
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      lugarReunion: json['lugar_reunion'],
      modalidad: json['modalidad'],
      generadaConIa: json['generada_con_ia'],
      creador: Creador.fromJson(json['creador']),
      estadisticasFirmas:
          EstadisticasFirmas.fromJson(json['estadisticas_firmas']),
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'borrador':
        return 'Borrador';
      case 'en_revision':
        return 'En Revisión';
      case 'finalizada':
        return 'Finalizada';
      case 'archivada':
        return 'Archivada';
      default:
        return estado;
    }
  }

  Color get estadoColor {
    switch (estado) {
      case 'borrador':
        return Colors.grey;
      case 'en_revision':
        return Colors.orange;
      case 'finalizada':
        return Colors.green;
      case 'archivada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get tipoReunionTexto {
    switch (tipoReunion) {
      case 'consejo_academico':
        return 'Consejo Académico';
      case 'comite_evaluacion':
        return 'Comité de Evaluación';
      case 'coordinacion':
        return 'Coordinación';
      case 'administrativa':
        return 'Administrativa';
      case 'tecnica':
        return 'Técnica';
      case 'otra':
        return 'Otra';
      default:
        return tipoReunion;
    }
  }

  String get modalidadTexto {
    switch (modalidad) {
      case 'presencial':
        return 'Presencial';
      case 'virtual':
        return 'Virtual';
      case 'hibrida':
        return 'Híbrida';
      default:
        return modalidad;
    }
  }
}

// Modelo completo para detalle
class ActaDetalle {
  final int id;
  final String numeroActa;
  final String titulo;
  final String tipoReunion;
  final String estado;
  final DateTime fechaReunion;
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;
  final String lugarReunion;
  final String modalidad;
  final String ordenDia;
  final String desarrollo;
  final String observaciones;
  final bool generadaConIa;
  final String? promptOriginal;
  final String? modeloIaUsado;
  final DateTime? fechaLimiteFirmas;
  final bool silencioAdministrativo;
  final bool puedeAplicarSilencio;
  final Creador creador;
  final List<Participante> participantes;
  final List<Compromiso> compromisos;
  final EstadisticasFirmas estadisticasFirmas;
  final PermisosUsuario permisosUsuario;

  ActaDetalle({
    required this.id,
    required this.numeroActa,
    required this.titulo,
    required this.tipoReunion,
    required this.estado,
    required this.fechaReunion,
    required this.fechaCreacion,
    required this.fechaModificacion,
    required this.lugarReunion,
    required this.modalidad,
    required this.ordenDia,
    required this.desarrollo,
    required this.observaciones,
    required this.generadaConIa,
    this.promptOriginal,
    this.modeloIaUsado,
    this.fechaLimiteFirmas,
    required this.silencioAdministrativo,
    required this.puedeAplicarSilencio,
    required this.creador,
    required this.participantes,
    required this.compromisos,
    required this.estadisticasFirmas,
    required this.permisosUsuario,
  });

  factory ActaDetalle.fromJson(Map<String, dynamic> json) {
    return ActaDetalle(
      id: json['id'],
      numeroActa: json['numero_acta'],
      titulo: json['titulo'],
      tipoReunion: json['tipo_reunion'],
      estado: json['estado'],
      fechaReunion: DateTime.parse(json['fecha_reunion']),
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaModificacion: DateTime.parse(json['fecha_modificacion']),
      lugarReunion: json['lugar_reunion'],
      modalidad: json['modalidad'],
      ordenDia: json['orden_dia'] ?? '',
      desarrollo: json['desarrollo'] ?? '',
      observaciones: json['observaciones'] ?? '',
      generadaConIa: json['generada_con_ia'],
      promptOriginal: json['prompt_original'],
      modeloIaUsado: json['modelo_ia_usado'],
      fechaLimiteFirmas: json['fecha_limite_firmas'] != null
          ? DateTime.parse(json['fecha_limite_firmas'])
          : null,
      silencioAdministrativo: json['silencio_administrativo'] ?? false,
      puedeAplicarSilencio: json['puede_aplicar_silencio'] ?? false,
      creador: Creador.fromJson(json['creador']),
      participantes: (json['participantes'] as List)
          .map((p) => Participante.fromJson(p))
          .toList(),
      compromisos: (json['compromisos'] as List)
          .map((c) => Compromiso.fromJson(c))
          .toList(),
      estadisticasFirmas:
          EstadisticasFirmas.fromJson(json['estadisticas_firmas']),
      permisosUsuario: PermisosUsuario.fromJson(json['permisos_usuario']),
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'borrador':
        return 'Borrador';
      case 'en_revision':
        return 'En Revisión';
      case 'finalizada':
        return 'Finalizada';
      case 'archivada':
        return 'Archivada';
      default:
        return estado;
    }
  }

  Color get estadoColor {
    switch (estado) {
      case 'borrador':
        return Colors.grey;
      case 'en_revision':
        return Colors.orange;
      case 'finalizada':
        return Colors.green;
      case 'archivada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get tipoReunionTexto {
    switch (tipoReunion) {
      case 'consejo_academico':
        return 'Consejo Académico';
      case 'comite_evaluacion':
        return 'Comité de Evaluación';
      case 'coordinacion':
        return 'Coordinación';
      case 'administrativa':
        return 'Administrativa';
      case 'tecnica':
        return 'Técnica';
      case 'otra':
        return 'Otra';
      default:
        return tipoReunion;
    }
  }

  String get modalidadTexto {
    switch (modalidad) {
      case 'presencial':
        return 'Presencial';
      case 'virtual':
        return 'Virtual';
      case 'hibrida':
        return 'Híbrida';
      default:
        return modalidad;
    }
  }
}

class Creador {
  final int id;
  final String nombreCompleto;
  final String? email;
  final String? rol;

  Creador({
    required this.id,
    required this.nombreCompleto,
    this.email,
    this.rol,
  });

  factory Creador.fromJson(Map<String, dynamic> json) {
    return Creador(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      email: json['email'],
      rol: json['rol'],
    );
  }
}

class Participante {
  final int id;
  final UsuarioParticipante usuario;
  final String rolEnReunion;
  final bool obligatorioFirma;
  final Firma? firma;

  Participante({
    required this.id,
    required this.usuario,
    required this.rolEnReunion,
    required this.obligatorioFirma,
    this.firma,
  });

  factory Participante.fromJson(Map<String, dynamic> json) {
    return Participante(
      id: json['id'],
      usuario: UsuarioParticipante.fromJson(json['usuario']),
      rolEnReunion: json['rol_en_reunion'] ?? '',
      obligatorioFirma: json['obligatorio_firma'],
      firma: json['firma'] != null ? Firma.fromJson(json['firma']) : null,
    );
  }
}

class UsuarioParticipante {
  final int id;
  final String nombreCompleto;
  final String email;
  final String rol;

  UsuarioParticipante({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
  });

  factory UsuarioParticipante.fromJson(Map<String, dynamic> json) {
    return UsuarioParticipante(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
      email: json['email'],
      rol: json['rol'],
    );
  }
}

class Firma {
  final bool firmado;
  final DateTime? fechaFirma;
  final bool tieneFirma;

  Firma({
    required this.firmado,
    this.fechaFirma,
    required this.tieneFirma,
  });

  factory Firma.fromJson(Map<String, dynamic> json) {
    return Firma(
      firmado: json['firmado'],
      fechaFirma: json['fecha_firma'] != null
          ? DateTime.parse(json['fecha_firma'])
          : null,
      tieneFirma: json['tiene_firma'] ?? false,
    );
  }
}

class Compromiso {
  final int id;
  final String descripcion;
  final Responsable responsable;
  final DateTime fechaLimite;
  final String estado;
  final int porcentajeAvance;
  final int diasRestantes;
  final String observaciones;

  Compromiso({
    required this.id,
    required this.descripcion,
    required this.responsable,
    required this.fechaLimite,
    required this.estado,
    required this.porcentajeAvance,
    required this.diasRestantes,
    required this.observaciones,
  });

  factory Compromiso.fromJson(Map<String, dynamic> json) {
    return Compromiso(
      id: json['id'],
      descripcion: json['descripcion'],
      responsable: Responsable.fromJson(json['responsable']),
      fechaLimite: DateTime.parse(json['fecha_limite']),
      estado: json['estado'],
      porcentajeAvance: json['porcentaje_avance'],
      diasRestantes: json['dias_restantes'],
      observaciones: json['observaciones'] ?? '',
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Completado';
      case 'vencido':
        return 'Vencido';
      default:
        return estado;
    }
  }

  Color get estadoColor {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_progreso':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      case 'vencido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get estaVencido => diasRestantes < 0 && estado != 'completado';
  bool get esProximo => diasRestantes <= 3 && diasRestantes >= 0;
}

class Responsable {
  final int id;
  final String nombreCompleto;

  Responsable({
    required this.id,
    required this.nombreCompleto,
  });

  factory Responsable.fromJson(Map<String, dynamic> json) {
    return Responsable(
      id: json['id'],
      nombreCompleto: json['nombre_completo'],
    );
  }
}

class EstadisticasFirmas {
  final int total;
  final int completadas;
  final double porcentaje;

  EstadisticasFirmas({
    required this.total,
    required this.completadas,
    required this.porcentaje,
  });

  factory EstadisticasFirmas.fromJson(Map<String, dynamic> json) {
    return EstadisticasFirmas(
      total: json['total'],
      completadas: json['completadas'],
      porcentaje: (json['porcentaje'] as num).toDouble(),
    );
  }
}

class PermisosUsuario {
  final bool esCreador;
  final bool esParticipante;
  final bool puedeEditar;
  final bool puedeFirmar;

  PermisosUsuario({
    required this.esCreador,
    required this.esParticipante,
    required this.puedeEditar,
    required this.puedeFirmar,
  });

  factory PermisosUsuario.fromJson(Map<String, dynamic> json) {
    return PermisosUsuario(
      esCreador: json['es_creador'],
      esParticipante: json['es_participante'],
      puedeEditar: json['puede_editar'],
      puedeFirmar: json['puede_firmar'],
    );
  }
}
