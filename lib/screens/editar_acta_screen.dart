import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/actas_service.dart';
import '../models/acta.dart';
import '../services/adjuntos_service.dart';
import '../models/archivo_adjunto.dart';

class EditarActaScreen extends StatefulWidget {
  final ActaDetalle acta;

  const EditarActaScreen({super.key, required this.acta});

  @override
  State<EditarActaScreen> createState() => _EditarActaScreenState();
}

class _EditarActaScreenState extends State<EditarActaScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _tituloController;
  late TextEditingController _lugarController;
  late TextEditingController _ordenDiaController;
  late TextEditingController _desarrolloController;
  late TextEditingController _observacionesController;

  // Datos del formulario
  late DateTime _fechaReunion;
  late String _tipoReunion;
  late String _modalidad;

  // Participantes
  List<Map<String, dynamic>> _todosUsuarios = [];
  List<Map<String, dynamic>> _participantesSeleccionados = [];
  bool _cargandoUsuarios = false;

  // Archivos adjuntos
  List<ArchivoAdjunto> _adjuntosExistentes = [];
  List<File> _archivosNuevos = [];
  List<String> _descripcionesNuevos = [];
  bool _cargandoAdjuntos = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    _cargarUsuarios();
    _cargarAdjuntos();
  }

  void _inicializarDatos() {
    // Cargar datos del acta actual
    _tituloController = TextEditingController(text: widget.acta.titulo);
    _lugarController = TextEditingController(text: widget.acta.lugarReunion);
    _ordenDiaController = TextEditingController(text: widget.acta.ordenDia);
    _desarrolloController = TextEditingController(text: widget.acta.desarrollo);
    _observacionesController =
        TextEditingController(text: widget.acta.observaciones ?? '');

    _fechaReunion = widget.acta.fechaReunion;
    _tipoReunion = widget.acta.tipoReunion;
    _modalidad = widget.acta.modalidad;

    // Cargar participantes actuales
    _participantesSeleccionados = widget.acta.participantes.map((p) {
      return {
        'usuario_id': p.usuario.id,
        'nombre_completo': p.usuario.nombreCompleto,
        'rol_en_reunion': p.rolEnReunion ?? '',
        'obligatorio_firma': true,
      };
    }).toList();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _lugarController.dispose();
    _ordenDiaController.dispose();
    _desarrolloController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargandoUsuarios = true);
    try {
      final usuarios = await ActasService.getUsuarios();
      setState(() {
        _todosUsuarios = usuarios;
        _cargandoUsuarios = false;
      });
    } catch (e) {
      setState(() => _cargandoUsuarios = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  Future<void> _cargarAdjuntos() async {
    setState(() => _cargandoAdjuntos = true);
    try {
      final adjuntos = await AdjuntosService.listarAdjuntos(widget.acta.id);
      setState(() {
        _adjuntosExistentes = adjuntos;
        _cargandoAdjuntos = false;
      });
    } catch (e) {
      setState(() => _cargandoAdjuntos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar adjuntos: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final archivo = await AdjuntosService.seleccionarArchivo();
      if (archivo != null) {
        setState(() {
          _archivosNuevos.add(archivo);
          _descripcionesNuevos.add('');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _eliminarArchivoNuevo(int index) {
    setState(() {
      _archivosNuevos.removeAt(index);
      _descripcionesNuevos.removeAt(index);
    });
  }

  Future<void> _eliminarAdjuntoExistente(ArchivoAdjunto adjunto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Deseas eliminar el archivo "${adjunto.nombreOriginal}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final resultado = await AdjuntosService.eliminarAdjunto(
          actaId: widget.acta.id,
          adjuntoId: adjunto.id,
        );

        if (resultado['success']) {
          setState(() {
            _adjuntosExistentes.remove(adjunto);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Archivo eliminado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception(resultado['error']);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar archivo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_participantesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tener al menos un participante')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PASO 1: Guardar cambios del acta
      final resultado = await ActasService.editarActa(
        actaId: widget.acta.id,
        titulo: _tituloController.text,
        fechaReunion: _fechaReunion.toIso8601String(),
        lugarReunion: _lugarController.text,
        tipoReunion: _tipoReunion,
        modalidad: _modalidad,
        ordenDia: _ordenDiaController.text,
        desarrollo: _desarrolloController.text,
        observaciones: _observacionesController.text,
        participantes: _participantesSeleccionados,
      );

      // PASO 2: Subir archivos nuevos si existen
      if (_archivosNuevos.isNotEmpty) {
        for (int i = 0; i < _archivosNuevos.length; i++) {
          try {
            await AdjuntosService.subirArchivo(
              actaId: widget.acta.id,
              archivo: _archivosNuevos[i],
              descripcion: _descripcionesNuevos[i].isNotEmpty
                  ? _descripcionesNuevos[i]
                  : null,
            );
          } catch (_) {
            // Continuar con los demás aunque uno falle
          }
        }
      }

      setState(() => _isLoading = false);

      if (resultado['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['message']),
              backgroundColor: Colors.green,
            ),
          );

          // Regresar a la pantalla anterior
          Navigator.pop(context, true); // true indica que se guardaron cambios
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Acta',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF39A900),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _guardarCambios();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39A900),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_currentStep == 3
                            ? 'Guardar Cambios'
                            : 'Continuar'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      child: const Text('Atrás'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Información Básica'),
              content: _buildStepInformacionBasica(),
              isActive: _currentStep >= 0,
            ),
            Step(
              title: const Text('Participantes'),
              content: _buildStepParticipantes(),
              isActive: _currentStep >= 1,
            ),
            Step(
              title: const Text('Contenido'),
              content: _buildStepContenido(),
              isActive: _currentStep >= 2,
            ),
            Step(
              title: const Text('Archivos Adjuntos'),
              content: _buildStepAdjuntos(),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepInformacionBasica() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _tituloController,
          decoration: InputDecoration(
            labelText: 'Título del Acta',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El título es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Fecha de Reunión'),
          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_fechaReunion)),
          leading: const Icon(Icons.calendar_today, color: Color(0xFF39A900)),
          onTap: () async {
            final fecha = await showDatePicker(
              context: context,
              initialDate: _fechaReunion,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (fecha != null && mounted) {
              final hora = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_fechaReunion),
              );

              if (hora != null) {
                setState(() {
                  _fechaReunion = DateTime(
                    fecha.year,
                    fecha.month,
                    fecha.day,
                    hora.hour,
                    hora.minute,
                  );
                });
              }
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lugarController,
          decoration: InputDecoration(
            labelText: 'Lugar de Reunión',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El lugar es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipoReunion,
          decoration: InputDecoration(
            labelText: 'Tipo de Reunión',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(
                value: 'consejo_academico', child: Text('Consejo Académico')),
            DropdownMenuItem(
                value: 'comite_evaluacion',
                child: Text('Comité de Evaluación')),
            DropdownMenuItem(
                value: 'coordinacion', child: Text('Coordinación')),
            DropdownMenuItem(
                value: 'administrativa', child: Text('Administrativa')),
            DropdownMenuItem(value: 'tecnica', child: Text('Técnica')),
            DropdownMenuItem(value: 'otra', child: Text('Otra')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _tipoReunion = value);
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _modalidad,
          decoration: InputDecoration(
            labelText: 'Modalidad',
            prefixIcon: const Icon(Icons.people),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'presencial', child: Text('Presencial')),
            DropdownMenuItem(value: 'virtual', child: Text('Virtual')),
            DropdownMenuItem(value: 'hibrida', child: Text('Híbrida')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _modalidad = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildStepParticipantes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Participantes actuales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_participantesSeleccionados.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay participantes'),
            ),
          )
        else
          ..._participantesSeleccionados.map((participante) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF39A900),
                  child: Text(
                    participante['nombre_completo'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(participante['nombre_completo']),
                subtitle: participante['rol_en_reunion'].isNotEmpty
                    ? Text(participante['rol_en_reunion'])
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _participantesSeleccionados.remove(participante);
                    });
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _mostrarDialogoAgregarParticipante,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Participante'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF39A900),
              side: const BorderSide(color: Color(0xFF39A900)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ordenDiaController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Orden del Día',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _desarrolloController,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: 'Desarrollo',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones (opcional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepAdjuntos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Archivos Adjuntos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Administra los archivos adjuntos del acta.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Archivos existentes
        if (_adjuntosExistentes.isNotEmpty) ...[
          const Text(
            'Archivos existentes:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._adjuntosExistentes.map((adjunto) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(adjunto.icono, color: adjunto.colorIcono),
                title: Text(adjunto.nombreOriginal),
                subtitle: Text(adjunto.tamanoFormateado),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarAdjuntoExistente(adjunto),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Botón para agregar nuevos archivos
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _seleccionarArchivo,
            icon: const Icon(Icons.attach_file),
            label: const Text('Agregar Archivo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF39A900),
              side: const BorderSide(color: Color(0xFF39A900)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Archivos nuevos seleccionados
        if (_archivosNuevos.isNotEmpty) ...[
          const Text(
            'Nuevos archivos para subir:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._archivosNuevos.asMap().entries.map((entry) {
            final index = entry.key;
            final archivo = entry.value;
            final nombreArchivo =
                archivo.path.split('/').last.split('\\').last;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file,
                            color: Color(0xFF39A900)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nombreArchivo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 20),
                          onPressed: () => _eliminarArchivoNuevo(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        _descripcionesNuevos[index] = value;
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // Mensaje si no hay archivos
        if (_adjuntosExistentes.isEmpty && _archivosNuevos.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No hay archivos adjuntos',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  void _mostrarDialogoAgregarParticipante() {
    if (_cargandoUsuarios) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando usuarios...')),
      );
      return;
    }

    Map<String, dynamic>? usuarioSeleccionado;
    final rolController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Agregar Participante'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: usuarioSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                    ),
                    items: _todosUsuarios.map((usuario) {
                      final yaSeleccionado = _participantesSeleccionados.any(
                        (p) => p['usuario_id'] == usuario['id'],
                      );

                      return DropdownMenuItem(
                        value: usuario,
                        enabled: !yaSeleccionado,
                        child: Text(
                          usuario['nombre_completo'],
                          style: TextStyle(
                            color: yaSeleccionado ? Colors.grey : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        usuarioSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: rolController,
                    decoration: const InputDecoration(
                      labelText: 'Rol en Reunión (opcional)',
                      hintText: 'Ej: Moderador, Secretario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (usuarioSeleccionado != null) {
                      setState(() {
                        _participantesSeleccionados.add({
                          'usuario_id': usuarioSeleccionado!['id'],
                          'nombre_completo':
                              usuarioSeleccionado!['nombre_completo'],
                          'rol_en_reunion': rolController.text,
                          'obligatorio_firma': true,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39A900),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
