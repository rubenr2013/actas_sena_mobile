import 'package:flutter/material.dart';
import '../services/backup_general_service.dart';

class BackupGeneralScreen extends StatefulWidget {
  const BackupGeneralScreen({Key? key}) : super(key: key);

  @override
  _BackupGeneralScreenState createState() => _BackupGeneralScreenState();
}

class _BackupGeneralScreenState extends State<BackupGeneralScreen> {
  bool _isLoading = false;
  List<dynamic> _backups = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarBackups();
  }

  Future<void> _cargarBackups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await BackupGeneralService.listarBackups();

      if (result['success']) {
        setState(() {
          _backups = result['backups'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _crearBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await BackupGeneralService.crearBackup();

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarBackups(); // Recargar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _descargarBackup(String filename) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await BackupGeneralService.descargarBackup(filename);

      Navigator.of(context).pop(); // Cerrar loading

      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Descarga Exitosa'),
              ],
            ),
            content: Text(
              '${result['message']}\n\n'
              'Ubicación: ${result['filepath']}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restaurarBackup(String filename) async {
    // Primer diálogo de confirmación
    final confirmar1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('⚠️ ADVERTENCIA'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas RESTAURAR la base de datos?\n\n'
          'Archivo: $filename\n\n'
          '⚠️ ESTA ACCIÓN ES DESTRUCTIVA Y NO SE PUEDE DESHACER.\n\n'
          '• Se eliminarán TODOS los datos actuales\n'
          '• Se reemplazarán con los datos del backup\n'
          '• Todos los usuarios serán desconectados\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmar1 != true) return;

    // Segundo diálogo: escribir "RESTAURAR"
    final controller = TextEditingController();
    final confirmar2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmación Final'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para confirmar, escribe la palabra:\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'RESTAURAR',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Escribe aquí',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'RESTAURAR') {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Debes escribir exactamente: RESTAURAR'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar2 != true) return;

    // Ejecutar restauración
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await BackupGeneralService.restaurarBackup(
        filename,
        controller.text,
      );

      Navigator.of(context).pop(); // Cerrar loading

      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Restauración Exitosa'),
              ],
            ),
            content: Text(
              '${result['message']}\n\n'
              'La base de datos ha sido restaurada.\n'
              'Por favor, reinicia la aplicación.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Opcionalmente: cerrar sesión o reiniciar app
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarBackup(String filename) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar este backup?\n\n'
          'Archivo: $filename\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final result = await BackupGeneralService.eliminarBackup(filename);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarBackups(); // Recargar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Backups'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Header con botón crear backup
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backup General del Sistema',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gestiona los backups completos de la base de datos',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _crearBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Crear Nuevo Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),

          // Lista de backups
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cargarBackups,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _backups.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay backups disponibles',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarBackups,
                            child: ListView.builder(
                              itemCount: _backups.length,
                              itemBuilder: (context, index) {
                                final backup = _backups[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ExpansionTile(
                                    leading: const Icon(
                                      Icons.archive,
                                      color: Colors.blue,
                                    ),
                                    title: Text(
                                      backup['filename'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Fecha: ${backup['created']}'),
                                        Text('Tamaño: ${backup['size']} MB'),
                                      ],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => _descargarBackup(
                                                  backup['filename']),
                                              icon: const Icon(Icons.download),
                                              label: const Text('Descargar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () => _restaurarBackup(
                                                  backup['filename']),
                                              icon: const Icon(Icons.restore),
                                              label: const Text('Restaurar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _eliminarBackup(
                                                  backup['filename']),
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                              tooltip: 'Eliminar',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
