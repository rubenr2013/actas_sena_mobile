import 'package:flutter/material.dart';

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
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      tipo: json['tipo'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      enlace: json['enlace'] ?? '',
      leida: json['leida'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaLectura: json['fecha_lectura'] != null
          ? DateTime.parse(json['fecha_lectura'])
          : null,
      metadata: json['metadata'] ?? {},
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
