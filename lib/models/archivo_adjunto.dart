import 'package:flutter/material.dart';

class ArchivoAdjunto {
  final int id;
  final String nombreOriginal;
  final String tipoArchivo;
  final int tamanoBytes;
  final DateTime fechaSubida;
  final String? descripcion;
  final String? subidoPorNombre;

  ArchivoAdjunto({
    required this.id,
    required this.nombreOriginal,
    required this.tipoArchivo,
    required this.tamanoBytes,
    required this.fechaSubida,
    this.descripcion,
    this.subidoPorNombre,
  });

  factory ArchivoAdjunto.fromJson(Map<String, dynamic> json) {
    return ArchivoAdjunto(
      id: json['id'],
      nombreOriginal: json['nombre_original'],
      tipoArchivo: json['tipo_archivo'],
      tamanoBytes: json['tamano_bytes'],
      fechaSubida: DateTime.parse(json['fecha_subida']),
      descripcion: json['descripcion'],
      subidoPorNombre: json['subido_por_nombre'],
    );
  }

  // Formatear tamaño del archivo
  String get tamanoFormateado {
    if (tamanoBytes < 1024) {
      return '$tamanoBytes B';
    } else if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Obtener icono según tipo de archivo
  IconData get icono {
    final extension = tipoArchivo.toLowerCase();
    if (extension == 'pdf') {
      return Icons.picture_as_pdf;
    } else if (extension == 'doc' || extension == 'docx') {
      return Icons.description;
    } else if (extension == 'xls' || extension == 'xlsx') {
      return Icons.table_chart;
    } else if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'gif') {
      return Icons.image;
    } else if (extension == 'zip' || extension == 'rar') {
      return Icons.folder_zip;
    } else {
      return Icons.insert_drive_file;
    }
  }

  // Color del icono según tipo
  Color get colorIcono {
    final extension = tipoArchivo.toLowerCase();
    if (extension == 'pdf') {
      return Colors.red;
    } else if (extension == 'doc' || extension == 'docx') {
      return Colors.blue;
    } else if (extension == 'xls' || extension == 'xlsx') {
      return Colors.green;
    } else if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'gif') {
      return Colors.orange;
    } else if (extension == 'zip' || extension == 'rar') {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }
}
