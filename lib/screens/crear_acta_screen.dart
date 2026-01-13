import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/actas_service.dart';
import 'acta_detalle_screen.dart';
import '../services/adjuntos_service.dart';

class CrearActaScreen extends StatefulWidget {
  const CrearActaScreen({super.key});

  @override
  State<CrearActaScreen> createState() => _CrearActaScreenState();
}

class _CrearActaScreenState extends State<CrearActaScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _tituloController = TextEditingController();
  final _lugarController = TextEditingController();
  final _ordenDiaController = TextEditingController();
  final _desarrolloController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _promptIAController = TextEditingController();

  // Datos del formulario
  DateTime _fechaReunion = DateTime.now();
  String _tipoReunion = 'consejo_academico';
  String _modalidad = 'presencial';
  bool _usarIA = false;

  // Participantes
  List<Map<String, dynamic>> _todosUsuarios = [];
  List<Map<String, dynamic>> _participantesSeleccionados = [];
  List<Map<String, dynamic>> _compromisosTemp = [];
  bool _cargandoUsuarios = false;

  // Archivos adjuntos
  List<File> _archivosSeleccionados = [];
  List<String> _descripcionesAdjuntos = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _lugarController.dispose();
    _ordenDiaController.dispose();
    _desarrolloController.dispose();
    _observacionesController.dispose();
    _promptIAController.dispose();
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

  Future<void> _generarConIA() async {
    if (_promptIAController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Escribe una descripción para generar con IA')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado =
          await ActasService.generarConIA(_promptIAController.text);

      if (resultado['success']) {
        setState(() {
          // ✅ CAMBIO: Ahora asignamos los campos separados correctamente
          _ordenDiaController.text = resultado['orden_dia']; // ← AGENDA
          _desarrolloController.text = resultado['desarrollo']; // ← DESARROLLO
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contenido generado con IA exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
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

  Future<void> _seleccionarArchivo() async {
    try {
      final archivo = await AdjuntosService.seleccionarArchivo();
      if (archivo != null) {
        setState(() {
          _archivosSeleccionados.add(archivo);
          _descripcionesAdjuntos.add(''); // Descripción vacía por defecto
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

  void _eliminarArchivo(int index) {
    setState(() {
      _archivosSeleccionados.removeAt(index);
      _descripcionesAdjuntos.removeAt(index);
    });
  }

  Future<void> _crearActa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_participantesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un participante')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Preparar compromisos en formato correcto para el backend
      final compromisosFormateados = _compromisosTemp.map((comp) {
        return {
          'descripcion': comp['descripcion'],
          'responsable_id': comp['responsable_id'],
          'fecha_limite': comp['fecha_limite'], // Ya está en formato YYYY-MM-DD
          'observaciones': comp['observaciones'] ?? '',
        };
      }).toList();

      // PASO 1: Crear el acta CON compromisos incluidos
      final resultado = await ActasService.crearActa(
        titulo: _tituloController.text,
        fechaReunion: _fechaReunion.toIso8601String(),
        lugarReunion: _lugarController.text,
        tipoReunion: _tipoReunion,
        modalidad: _modalidad,
        ordenDia: _ordenDiaController.text,
        desarrollo: _desarrolloController.text,
        observaciones: _observacionesController.text,
        participantes: _participantesSeleccionados,
        compromisos: compromisosFormateados,
        generadaConIa: _usarIA,
        promptOriginal: _usarIA ? _promptIAController.text : '',
        modeloIaUsado: _usarIA ? 'llama-3.3-70b-versatile' : '',
      );

      if (resultado['success']) {
        final actaId = resultado['acta_id'];
        final compromisosCreados = resultado['compromisos_creados'] ?? [];

        // PASO 2: Subir archivos adjuntos si existen
        if (_archivosSeleccionados.isNotEmpty) {
          for (int i = 0; i < _archivosSeleccionados.length; i++) {
            try {
              await AdjuntosService.subirArchivo(
                actaId: actaId,
                archivo: _archivosSeleccionados[i],
                descripcion: _descripcionesAdjuntos[i].isNotEmpty
                    ? _descripcionesAdjuntos[i]
                    : null,
              );
            } catch (e) {
              print('Error al subir archivo: $e');
              // Continuar con los demás aunque uno falle
            }
          }
        }

        setState(() => _isLoading = false);

        if (mounted) {
          // Construir mensaje de éxito
          final mensaje = compromisosFormateados.isEmpty
              ? 'Acta ${resultado['numero_acta']} creada correctamente'
              : 'Acta ${resultado['numero_acta']} creada con ${compromisosCreados.length} compromiso(s)';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensaje),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar al detalle de la acta creada
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ActaDetalleScreen(actaId: actaId),
            ),
          );
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
          'Crear Acta',
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
            if (_currentStep < 5) {
              setState(() => _currentStep++);
            } else {
              _crearActa();
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
                        : Text(_currentStep == 5 ? 'Crear Acta' : 'Continuar'),
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
              title: const Text('Compromisos'),
              content: _buildStepCompromisos(),
              isActive: _currentStep >= 3,
            ),
            Step(
              title: const Text('Archivos Adjuntos'),
              content: _buildStepAdjuntos(),
              isActive: _currentStep >= 4,
            ),
            Step(
              title: const Text('Revisión'),
              content: _buildStepRevision(),
              isActive: _currentStep >= 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepInformacionBasica() {
    return Column(
      children: [
        TextFormField(
          controller: _tituloController,
          decoration: InputDecoration(
            labelText: 'Título del Acta',
            prefixIcon: const Icon(Icons.title, color: Color(0xFF39A900)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El título es requerido';
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
              lastDate: DateTime(2030),
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
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lugarController,
          decoration: InputDecoration(
            labelText: 'Lugar de Reunión',
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF39A900)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El lugar es requerido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _tipoReunion,
          decoration: InputDecoration(
            labelText: 'Tipo de Reunión',
            prefixIcon: const Icon(Icons.category, color: Color(0xFF39A900)),
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
            prefixIcon: const Icon(Icons.people, color: Color(0xFF39A900)),
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
    if (_cargandoUsuarios) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39A900)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participantes seleccionados: ${_participantesSeleccionados.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_participantesSeleccionados.isNotEmpty) ...[
          ..._participantesSeleccionados.map((p) {
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF39A900),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(p['nombre_completo']),
                subtitle: Text(p['rol_en_reunion'] ?? 'Sin rol especificado'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _participantesSeleccionados.removeWhere(
                        (item) => item['usuario_id'] == p['usuario_id'],
                      );
                    });
                  },
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: () => _mostrarDialogoAgregarParticipante(),
          icon: const Icon(Icons.add),
          label: const Text('Agregar Participante'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39A900),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoAgregarParticipante() {
    final rolController = TextEditingController();
    Map<String, dynamic>? usuarioSeleccionado;

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
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Usuario',
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

  Widget _buildStepContenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Generar con IA'),
          subtitle: const Text(
              'Usa inteligencia artificial para generar el contenido'),
          value: _usarIA,
          activeColor: const Color(0xFF39A900),
          onChanged: (value) {
            setState(() => _usarIA = value);
          },
        ),
        if (_usarIA) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple),
            ),
            child: Row(
              children: const [
                Icon(Icons.psychology, color: Colors.purple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Describe la reunión y la IA generará el contenido automáticamente',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptIAController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Descripción para IA',
              hintText:
                  'Ej: Reunión sobre planificación del segundo semestre...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generarConIA,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generar con IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
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
          'Archivos Adjuntos (Opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Puedes adjuntar documentos, imágenes u otros archivos relevantes al acta.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Botón para seleccionar archivo
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _seleccionarArchivo,
            icon: const Icon(Icons.attach_file),
            label: const Text('Seleccionar Archivo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF39A900),
              side: const BorderSide(color: Color(0xFF39A900)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de archivos seleccionados
        if (_archivosSeleccionados.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No has seleccionado archivos',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._archivosSeleccionados.asMap().entries.map((entry) {
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
                          onPressed: () => _eliminarArchivo(index),
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
                        _descripcionesAdjuntos[index] = value;
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStepRevision() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revisa la información antes de crear',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),
        _buildRevisionItem('Título', _tituloController.text),
        _buildRevisionItem(
            'Fecha', DateFormat('dd/MM/yyyy HH:mm').format(_fechaReunion)),
        _buildRevisionItem('Lugar', _lugarController.text),
        _buildRevisionItem('Tipo', _getTipoReunionText(_tipoReunion)),
        _buildRevisionItem('Modalidad', _getModalidadText(_modalidad)),
        _buildRevisionItem('Participantes',
            '${_participantesSeleccionados.length} persona(s)'),
        _buildRevisionItem(
            'Compromisos', '${_compromisosTemp.length} compromiso(s)'),
        _buildRevisionItem(
            'Archivos Adjuntos', '${_archivosSeleccionados.length} archivo(s)'),
        if (_usarIA)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.psychology, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text('Generada con IA', style: TextStyle(color: Colors.purple)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRevisionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getTipoReunionText(String tipo) {
    switch (tipo) {
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
        return tipo;
    }
  }

  String _getModalidadText(String modalidad) {
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

  // ========================================
  // FUNCIONES PARA COMPROMISOS
  // ========================================

  Widget _buildStepCompromisos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agregar compromisos que surgieron de la reunión',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Botón agregar compromiso
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _mostrarDialogoAgregarCompromiso,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Compromiso'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF39A900),
              side: const BorderSide(color: Color(0xFF39A900)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de compromisos agregados
        if (_compromisosTemp.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No has agregado compromisos aún',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._compromisosTemp.asMap().entries.map((entry) {
            final index = entry.key;
            final compromiso = entry.value;
            return _buildCompromisoCard(compromiso, index);
          }),
      ],
    );
  }

  Widget _buildCompromisoCard(Map<String, dynamic> compromiso, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    compromiso['descripcion'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      _compromisosTemp.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  compromiso['responsable_nombre'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Color(0xFF39A900)),
                const SizedBox(width: 4),
                Text(
                  'Vence: ${dateFormat.format(DateTime.parse(compromiso['fecha_limite']))}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF39A900),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (compromiso['observaciones'] != null &&
                compromiso['observaciones'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                compromiso['observaciones'],
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarCompromiso() {
    if (_participantesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero agrega participantes en el paso anterior'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final descripcionController = TextEditingController();
    final observacionesController = TextEditingController();
    Map<String, dynamic>? responsableSeleccionado;
    DateTime? fechaSeleccionada;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Agregar Compromiso'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descripción
                    const Text(
                      'Descripción *',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(
                        hintText: 'Describe el compromiso...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Responsable
                    const Text(
                      'Responsable *',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: responsableSeleccionado,
                      decoration: const InputDecoration(
                        hintText: 'Selecciona un responsable',
                        border: OutlineInputBorder(),
                      ),
                      items: _participantesSeleccionados.map((participante) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: participante,
                          child: Text(participante['nombre_completo']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          responsableSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha límite
                    const Text(
                      'Fecha Límite *',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (fecha != null) {
                          setStateDialog(() {
                            fechaSeleccionada = fecha;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color(0xFF39A900)),
                            const SizedBox(width: 12),
                            Text(
                              fechaSeleccionada != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(fechaSeleccionada!)
                                  : 'Selecciona una fecha',
                              style: TextStyle(
                                color: fechaSeleccionada != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Observaciones
                    const Text(
                      'Observaciones (opcional)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: observacionesController,
                      decoration: const InputDecoration(
                        hintText: 'Observaciones adicionales...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
                  onPressed: () {
                    // Validar campos
                    if (descripcionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('La descripción es obligatoria'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (responsableSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debes seleccionar un responsable'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (fechaSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debes seleccionar una fecha límite'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Agregar a la lista temporal
                    setState(() {
                      _compromisosTemp.add({
                        'descripcion': descripcionController.text.trim(),
                        'responsable_id':
                            responsableSeleccionado!['usuario_id'],
                        'responsable_nombre':
                            responsableSeleccionado!['nombre_completo'],
                        'fecha_limite':
                            DateFormat('yyyy-MM-dd').format(fechaSeleccionada!),
                        'observaciones': observacionesController.text.trim(),
                      });
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compromiso agregado a la lista'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
