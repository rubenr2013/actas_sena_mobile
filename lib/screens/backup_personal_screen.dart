import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_personal_service.dart';

class BackupPersonalScreen extends StatefulWidget {
  const BackupPersonalScreen({super.key});

  @override
  State<BackupPersonalScreen> createState() => _BackupPersonalScreenState();
}

class _BackupPersonalScreenState extends State<BackupPersonalScreen> {
  bool _isLoading = false;

  Future<void> _exportarDatos() async {
    setState(() => _isLoading = true);

    try {
      final resultado = await BackupPersonalService.exportarDatos();

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado['success'] == true) {
        _mostrarDialog(
          'Exportación Exitosa',
          'Tus datos se han exportado correctamente.\n\n'
              'Archivo: ${resultado['filename']}\n'
              'Ubicación: ${resultado['filepath']}',
          Icons.check_circle,
          Colors.green,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al exportar datos: $e');
    }
  }

  Future<void> _importarDatos() async {
    try {
      // Seleccionar archivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;

      setState(() => _isLoading = true);

      // Validar backup
      final validacion = await BackupPersonalService.validarBackup(filePath);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (validacion['success'] == true) {
        // Mostrar estadísticas y confirmar
        _mostrarConfirmacionImportacion(filePath, validacion);
      } else {
        _mostrarError(validacion['error'] ?? 'Error al validar backup');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al importar datos: $e');
    }
  }

  void _mostrarConfirmacionImportacion(
      String filePath, Map<String, dynamic> validacion) {
    final stats = validacion['stats'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Confirmar Importación'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                validacion['advertencia'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Datos en el backup:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${stats['actas_en_backup']} acta(s)'),
              Text('• ${stats['compromisos_en_backup']} compromiso(s)'),
              const SizedBox(height: 16),
              const Text(
                'Datos actuales (se perderán):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${stats['actas_actuales']} acta(s)'),
              Text('• ${stats['compromisos_actuales']} compromiso(s)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  '⚠️ Esta acción NO se puede deshacer. Tus datos actuales serán reemplazados por los del backup.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmarImportacion(filePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Sí, Importar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarImportacion(String filePath) async {
    setState(() => _isLoading = true);

    try {
      final resultado =
          await BackupPersonalService.confirmarImportacion(filePath);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado['success'] == true) {
        final stats = resultado['stats'] as Map<String, dynamic>;
        _mostrarDialog(
          'Importación Exitosa',
          'Tus datos se han restaurado correctamente.\n\n'
              'Actas restauradas: ${stats['actas_restauradas']}',
          Icons.check_circle,
          Colors.green,
        );
      } else {
        _mostrarError(resultado['error'] ?? 'Error al importar datos');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al importar datos: $e');
    }
  }

  void _mostrarDialog(
      String titulo, String mensaje, IconData icono, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(width: 12),
            Text(titulo),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Datos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF39A900),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF39A900),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Gestión de Datos Personales',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exporta e importa tus datos de forma segura',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Card de Exportar
                  _buildCard(
                    titulo: 'Exportar Mis Datos',
                    descripcion:
                        'Descarga un archivo ZIP con todas tus actas, compromisos y firmas. Úsalo como respaldo personal.',
                    icono: Icons.download,
                    color: const Color(0xFF39A900),
                    botonTexto: 'Exportar Ahora',
                    onPressed: _exportarDatos,
                  ),

                  const SizedBox(height: 16),

                  // Card de Importar
                  _buildCard(
                    titulo: 'Importar Mis Datos',
                    descripcion:
                        '⚠️ Restaura tus datos desde un backup. ADVERTENCIA: Esto reemplazará tus datos actuales.',
                    icono: Icons.upload,
                    color: Colors.orange,
                    botonTexto: 'Importar Backup',
                    onPressed: _importarDatos,
                  ),

                  const SizedBox(height: 32),

                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Información Importante',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• El backup contiene solo TUS datos personales\n'
                          '• No afecta los datos de otros usuarios\n'
                          '• Los archivos están en formato ZIP\n'
                          '• Solo puedes importar tus propios backups\n'
                          '• Recomendamos hacer backups regularmente',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required String botonTexto,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              descripcion,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icono),
                label: Text(botonTexto),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
