import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/compromisos_service.dart';

class ActualizarCompromisoScreen extends StatefulWidget {
  final Map<String, dynamic> compromiso;

  const ActualizarCompromisoScreen({
    super.key,
    required this.compromiso,
  });

  @override
  State<ActualizarCompromisoScreen> createState() =>
      _ActualizarCompromisoScreenState();
}

class _ActualizarCompromisoScreenState
    extends State<ActualizarCompromisoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reporteController = TextEditingController();

  late String _estadoSeleccionado;
  late double _porcentajeAvance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.compromiso['estado'];
    _porcentajeAvance =
        (widget.compromiso['porcentaje_avance'] as int).toDouble();
    _reporteController.text = widget.compromiso['reporte_cumplimiento'] ?? '';
  }

  @override
  void dispose() {
    _reporteController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await CompromisosService.actualizarCompromiso(
        compromisoId: widget.compromiso['id'],
        estado: _estadoSeleccionado,
        porcentajeAvance: _porcentajeAvance.toInt(),
        reporteCumplimiento: _reporteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compromiso actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Regresar con resultado exitoso
        Navigator.pop(context, true);
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
    final fechaLimite = DateTime.parse(widget.compromiso['fecha_limite']);
    final diasRestantes = widget.compromiso['dias_restantes'] as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Compromiso'),
        backgroundColor: const Color(0xFF39A900),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del compromiso
              _buildInfoCard(fechaLimite, diasRestantes),

              const SizedBox(height: 24),

              // Estado
              _buildEstadoSelector(),

              const SizedBox(height: 24),

              // Porcentaje de avance
              _buildPorcentajeSlider(),

              const SizedBox(height: 24),

              // Reporte de cumplimiento
              _buildReporteField(),

              const SizedBox(height: 32),

              // Botón guardar
              _buildGuardarButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(DateTime fechaLimite, int diasRestantes) {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFF39A900)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.compromiso['descripcion'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Acta
            Row(
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Acta: ${widget.compromiso['acta']['numero_acta']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Fecha límite
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: diasRestantes < 0 ? Colors.red : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Vencimiento: ${DateFormat('dd/MM/yyyy').format(fechaLimite)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: diasRestantes < 0 ? Colors.red : Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Días restantes
            Row(
              children: [
                Icon(
                  diasRestantes < 0 ? Icons.warning : Icons.access_time,
                  size: 16,
                  color: diasRestantes < 0
                      ? Colors.red
                      : diasRestantes <= 3
                          ? Colors.orange
                          : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  diasRestantes < 0
                      ? 'Vencido hace ${diasRestantes.abs()} días'
                      : diasRestantes == 0
                          ? 'Vence hoy'
                          : 'Faltan $diasRestantes días',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: diasRestantes <= 3
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: diasRestantes < 0
                        ? Colors.red
                        : diasRestantes <= 3
                            ? Colors.orange
                            : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del Compromiso',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _estadoSeleccionado,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'pendiente',
                  child: Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Text('Pendiente'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'en_progreso',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Text('En Progreso'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'completado',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 12),
                      Text('Completado'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _estadoSeleccionado = value!;

                  // Si marca como completado, poner avance en 100%
                  if (value == 'completado') {
                    _porcentajeAvance = 100;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPorcentajeSlider() {
    Color sliderColor;
    if (_porcentajeAvance == 100) {
      sliderColor = Colors.green;
    } else if (_porcentajeAvance >= 50) {
      sliderColor = Colors.blue;
    } else {
      sliderColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Porcentaje de Avance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sliderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sliderColor),
              ),
              child: Text(
                '${_porcentajeAvance.toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: sliderColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: sliderColor,
            thumbColor: sliderColor,
            overlayColor: sliderColor.withOpacity(0.2),
            valueIndicatorColor: sliderColor,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: _porcentajeAvance,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_porcentajeAvance.toInt()}%',
            onChanged: (value) {
              setState(() {
                _porcentajeAvance = value;

                // Si llega a 100%, cambiar estado a completado
                if (value == 100 && _estadoSeleccionado != 'completado') {
                  _estadoSeleccionado = 'completado';
                }
                // Si baja de 100%, quitar estado completado
                else if (value < 100 && _estadoSeleccionado == 'completado') {
                  _estadoSeleccionado = 'en_progreso';
                }
              });
            },
          ),
        ),

        // Marcas de referencia
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('25%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('50%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('75%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('100%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReporteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reporte de Cumplimiento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Describe el avance, logros o justificación del estado actual',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reporteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Escribe aquí el reporte de cumplimiento...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (_estadoSeleccionado == 'completado' &&
                (value == null || value.trim().isEmpty)) {
              return 'El reporte es obligatorio para marcar como completado';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGuardarButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _guardarCambios,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF39A900),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
