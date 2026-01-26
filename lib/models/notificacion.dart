import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

class Notificacion {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String enlace;
  final bool leida;
  final DateTime fechaCreacion;
  final DateTime? fechaLectura;
  final Map<String, dynamic> metadata;
  final int? actaId;
  final int? compromisoId;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.enlace,
    required this.leida,
    required this.fechaCreacion,
    this.fechaLectura,
    required this.metadata,
    this.actaId,
    this.compromisoId,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    // Intentar obtener actaId de diferentes fuentes
    int? actaId = json['acta_id'] as int?;
    if (actaId == null && json['acta'] != null) {
      actaId = json['acta']['id'] as int?;
    }
    if (actaId == null && json['metadata'] != null) {
      actaId = json['metadata']['acta_id'] as int?;
    }

    // Intentar obtener compromisoId de diferentes fuentes
    int? compromisoId = json['compromiso_id'] as int?;
    if (compromisoId == null && json['compromiso'] != null) {
      compromisoId = json['compromiso']['id'] as int?;
    }
    if (compromisoId == null && json['metadata'] != null) {
      compromisoId = json['metadata']['compromiso_id'] as int?;
    }

    return Notificacion(
      id: json['id'],
      tipo: json['tipo'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      enlace: json['enlace'] ?? '',
      leida: json['leida'],
      fechaCreacion: DateParseUtils.parseOrDefault(json['fecha_creacion']),
      fechaLectura: DateParseUtils.tryParse(json['fecha_lectura']),
      metadata: json['metadata'] ?? {},
      actaId: actaId,
      compromisoId: compromisoId,
    );
  }

  String get tipoTexto {
    switch (tipo) {
      case 'firma_pendiente':
        return 'Firma Pendiente';
      case 'firma_completada':
        return 'Firma Completada';
      case 'acta_lista_finalizar':
        return 'Acta Lista para Finalizar';
      case 'compromiso_vencido':
        return 'Compromiso Vencido';
      case 'compromiso_proximo':
        return 'Compromiso Próximo a Vencer';
      case 'silencio_administrativo':
        return 'Silencio Administrativo';
      case 'nueva_acta':
        return 'Nueva Acta';
      case 'acta_finalizada':
        return 'Acta Finalizada';
      case 'sistema':
        return 'Notificación del Sistema';
      default:
        return tipo;
    }
  }

  IconData get icono {
    switch (tipo) {
      case 'firma_pendiente':
        return Icons.edit;
      case 'firma_completada':
        return Icons.check_circle;
      case 'acta_lista_finalizar':
        return Icons.flag;
      case 'compromiso_vencido':
        return Icons.warning;
      case 'compromiso_proximo':
        return Icons.access_time;
      case 'silencio_administrativo':
        return Icons.gavel;
      case 'nueva_acta':
        return Icons.description;
      case 'acta_finalizada':
        return Icons.task_alt;
      case 'sistema':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (tipo) {
      case 'firma_pendiente':
        return Colors.orange;
      case 'firma_completada':
        return Colors.green;
      case 'acta_lista_finalizar':
        return Colors.blue;
      case 'compromiso_vencido':
        return Colors.red;
      case 'compromiso_proximo':
        return Colors.orange;
      case 'silencio_administrativo':
        return Colors.grey;
      case 'nueva_acta':
        return const Color(0xFF39A900);
      case 'acta_finalizada':
        return Colors.green;
      case 'sistema':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
