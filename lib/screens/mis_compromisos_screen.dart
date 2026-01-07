import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/compromisos_service.dart';
import 'actualizar_compromiso_screen.dart';
import 'acta_detalle_screen.dart';

class MisCompromisosScreen extends StatefulWidget {
  const MisCompromisosScreen({super.key});

  @override
  State<MisCompromisosScreen> createState() => _MisCompromisosScreenState();
}

class _MisCompromisosScreenState extends State<MisCompromisosScreen> {
  List<Map<String, dynamic>> _compromisos = [];
  bool _isLoading = true;
  String? _error;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarCompromisos();
  }

  Future<void> _cargarCompromisos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final compromisos = await CompromisosService.obtenerMisCompromisos();

      setState(() {
        _compromisos = compromisos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _compromisosFiltrados {
    if (_filtroEstado == 'todos') {
      return _compromisos;
    }
    return _compromisos.where((c) => c['estado'] == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compromisos'),
        backgroundColor: const Color(0xFF39A900),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),

          // Lista de compromisos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _compromisosFiltrados.isEmpty
                        ? _buildEmpty()
                        : _buildLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChipFiltro('Todos', 'todos'),
            const SizedBox(width: 8),
            _buildChipFiltro('Pendiente', 'pendiente'),
            const SizedBox(width: 8),
            _buildChipFiltro('En Progreso', 'en_progreso'),
            const SizedBox(width: 8),
            _buildChipFiltro('Completado', 'completado'),
            const SizedBox(width: 8),
            _buildChipFiltro('Vencido', 'vencido'),
          ],
        ),
      ),
    );
  }

  Widget _buildChipFiltro(String label, String estado) {
    final isSelected = _filtroEstado == estado;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = estado;
        });
      },
      selectedColor: const Color(0xFF39A900),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _cargarCompromisos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _compromisosFiltrados.length,
        itemBuilder: (context, index) {
          final compromiso = _compromisosFiltrados[index];
          return _buildCompromisoCard(compromiso);
        },
      ),
    );
  }

  Widget _buildCompromisoCard(Map<String, dynamic> compromiso) {
    final estado = compromiso['estado'] as String;
    final porcentaje = compromiso['porcentaje_avance'] as int;
    final diasRestantes = compromiso['dias_restantes'] as int;
    final fechaLimite = DateTime.parse(compromiso['fecha_limite']);

    Color estadoColor;
    IconData estadoIcon;

    switch (estado) {
      case 'pendiente':
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
        break;
      case 'en_progreso':
        estadoColor = Colors.blue;
        estadoIcon = Icons.play_arrow;
        break;
      case 'completado':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'vencido':
        estadoColor = Colors.red;
        estadoIcon = Icons.error;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          // Navegar a actualizar compromiso
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActualizarCompromisoScreen(
                compromiso: compromiso,
              ),
            ),
          );

          // Si se actualizó, recargar lista
          if (resultado == true && mounted) {
            _cargarCompromisos();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Estado y Acta
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: estadoColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, size: 16, color: estadoColor),
                        const SizedBox(width: 4),
                        Text(
                          _getEstadoTexto(estado),
                          style: TextStyle(
                            color: estadoColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      // Navegar a detalle del acta
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActaDetalleScreen(
                            actaId: compromiso['acta']['id'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            compromiso['acta']['numero_acta'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Descripción
              Text(
                compromiso['descripcion'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // Acta título
              Text(
                'Acta: ${compromiso['acta']['titulo']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 12),

              // Fecha límite y días restantes
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: diasRestantes < 0 ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(fechaLimite),
                    style: TextStyle(
                      fontSize: 14,
                      color: diasRestantes < 0 ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    diasRestantes < 0 ? Icons.warning : Icons.access_time,
                    size: 16,
                    color: diasRestantes < 0
                        ? Colors.red
                        : diasRestantes <= 3
                            ? Colors.orange
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    diasRestantes < 0
                        ? 'Vencido hace ${diasRestantes.abs()} días'
                        : diasRestantes == 0
                            ? 'Vence hoy'
                            : 'Faltan $diasRestantes días',
                    style: TextStyle(
                      fontSize: 14,
                      color: diasRestantes < 0
                          ? Colors.red
                          : diasRestantes <= 3
                              ? Colors.orange
                              : Colors.grey[600],
                      fontWeight: diasRestantes <= 3
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barra de progreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Avance:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$porcentaje%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: porcentaje == 100
                              ? Colors.green
                              : porcentaje >= 50
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: porcentaje / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        porcentaje == 100
                            ? Colors.green
                            : porcentaje >= 50
                                ? Colors.blue
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              // Reporte (si existe)
              if (compromiso['reporte_cumplimiento'] != null &&
                  compromiso['reporte_cumplimiento'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note_alt,
                              size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Reporte:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        compromiso['reporte_cumplimiento'],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getEstadoTexto(String estado) {
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filtroEstado == 'todos'
                ? 'No tienes compromisos asignados'
                : 'No hay compromisos en este estado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar compromisos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarCompromisos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
