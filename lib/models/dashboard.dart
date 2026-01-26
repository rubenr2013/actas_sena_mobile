import 'package:flutter/material.dart';
import 'firma_pendiente.dart';
import '../utils/date_utils.dart';

class DashboardData {
  final Estadisticas estadisticas;
  final List<ActaReciente> actasRecientes;
  final List<FirmaPendiente> firmasPendientes;
  final List<CompromisoProximo> compromisosProximos;

  DashboardData({
    required this.estadisticas,
    required this.actasRecientes,
    required this.firmasPendientes,
    required this.compromisosProximos,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      estadisticas: Estadisticas.fromJson(json['estadisticas']),
      actasRecientes: (json['actas_recientes'] as List? ?? [])
          .map((item) => ActaReciente.fromJson(item))
          .toList(),
      firmasPendientes: (json['firmas_pendientes'] as List? ?? [])
          .map((item) => FirmaPendiente.fromJson(item))
          .toList(),
      compromisosProximos: (json['compromisos_proximos'] as List? ?? [])
          .map((item) => CompromisoProximo.fromJson(item))
          .toList(),
    );
  }
}

class Estadisticas {
  final int totalActas;
  final int firmasPendientes;
  final int compromisosActivos;
  final int compromisosVencidos;

  Estadisticas({
    required this.totalActas,
    required this.firmasPendientes,
    required this.compromisosActivos,
    required this.compromisosVencidos,
  });

  factory Estadisticas.fromJson(Map<String, dynamic> json) {
    return Estadisticas(
      totalActas: json['total_actas'] ?? 0,
      firmasPendientes: json['firmas_pendientes'] ?? 0,
      compromisosActivos: json['compromisos_activos'] ?? 0,
      compromisosVencidos: json['compromisos_vencidos'] ?? 0,
    );
  }
}

class ActaReciente {
  final int id;
  final String numeroActa;
  final String titulo;
  final String estado;
  final DateTime fechaReunion;
  final DateTime fechaCreacion;

  ActaReciente({
    required this.id,
    required this.numeroActa,
    required this.titulo,
    required this.estado,
    required this.fechaReunion,
    required this.fechaCreacion,
  });

  factory ActaReciente.fromJson(Map<String, dynamic> json) {
    return ActaReciente(
      id: json['id'],
      numeroActa: json['numero_acta'],
      titulo: json['titulo'],
      estado: json['estado'],
      fechaReunion: DateParseUtils.parseOrDefault(json['fecha_reunion']),
      fechaCreacion: DateParseUtils.parseOrDefault(json['fecha_creacion']),
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
}

class ActaInfo {
  final int id;
  final String numeroActa;
  final String titulo;
  final DateTime fechaReunion;

  ActaInfo({
    required this.id,
    required this.numeroActa,
    required this.titulo,
    required this.fechaReunion,
  });

  factory ActaInfo.fromJson(Map<String, dynamic> json) {
    return ActaInfo(
      id: json['id'],
      numeroActa: json['numero_acta'],
      titulo: json['titulo'],
      fechaReunion: DateParseUtils.parseOrDefault(json['fecha_reunion']),
    );
  }
}

class CompromisoProximo {
  final int id;
  final String descripcion;
  final DateTime fechaLimite;
  final String estado;
  final int porcentajeAvance;
  final int diasRestantes;
  final ActaInfo acta;

  CompromisoProximo({
    required this.id,
    required this.descripcion,
    required this.fechaLimite,
    required this.estado,
    required this.porcentajeAvance,
    required this.diasRestantes,
    required this.acta,
  });

  factory CompromisoProximo.fromJson(Map<String, dynamic> json) {
    return CompromisoProximo(
      id: json['id'],
      descripcion: json['descripcion'] ?? '',
      fechaLimite: DateParseUtils.parseOrDefault(json['fecha_limite']),
      estado: json['estado'] ?? '',
      porcentajeAvance: json['porcentaje_avance'] ?? 0,
      diasRestantes: json['dias_restantes'] ?? 0,
      acta: ActaInfo.fromJson(json['acta']),
    );
  }

  bool get estaVencido => diasRestantes < 0 && estado != 'completado';
  bool get esProximo => diasRestantes <= 3 && diasRestantes >= 0;
}
