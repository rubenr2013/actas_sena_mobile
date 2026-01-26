import 'package:flutter/material.dart';
import '../models/notificacion.dart';
import '../services/notificaciones_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'acta_detalle_screen.dart';
import 'mis_compromisos_screen.dart';
import 'firmas_pendientes_screen.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({Key? key}) : super(key: key);

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Notificacion> _notificaciones = [];
  bool _isLoading = true;
  String? _error;
  String _filtroTipo = 'todas';
  bool? _filtroLeida;
  int _totalNoLeidas = 0;

  final List<Map<String, dynamic>> _tiposNotificacion = [
    {'value': 'todas', 'label': 'Todas'},
    {'value': 'firma_pendiente', 'label': 'Firmas'},
    {'value': 'compromiso_vencido', 'label': 'Compromisos'},
    {'value': 'nueva_acta', 'label': 'Nuevas Actas'},
    {'value': 'sistema', 'label': 'Sistema'},
  ];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resultado = await NotificacionesService.obtenerNotificaciones(
        leida: _filtroLeida,
        tipo: _filtroTipo == 'todas' ? null : _filtroTipo,
      );

      setState(() {
        _notificaciones = resultado['notificaciones'];
        _totalNoLeidas = resultado['total_no_leidas'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarComoLeida(Notificacion notificacion) async {
    if (notificacion.leida) return;

    try {
      await NotificacionesService.marcarComoLeida(notificacion.id);
      _cargarNotificaciones();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación marcada como leída'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    try {
      final count = await NotificacionesService.marcarTodasComoLeidas();
      _cargarNotificaciones();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count notificaciones marcadas como leídas'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarNotificacion(Notificacion notificacion) async {
    // Confirmar eliminación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Notificación'),
        content: const Text('¿Estás seguro de eliminar esta notificación?'),
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

    if (confirmar != true) return;

    try {
      await NotificacionesService.eliminarNotificacion(notificacion.id);
      _cargarNotificaciones();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación eliminada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navega al contenido relacionado según el tipo de notificación
  void _navegarDesdeNotificacion(Notificacion notificacion) {
    // Primero marcar como leída si no lo está
    if (!notificacion.leida) {
      _marcarComoLeida(notificacion);
    }

    // Navegar según el tipo de notificación
    switch (notificacion.tipo) {
      case 'firma_pendiente':
        // Navegar a firmas pendientes o al acta específica
        if (notificacion.actaId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActaDetalleScreen(actaId: notificacion.actaId!),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FirmasPendientesScreen(),
            ),
          );
        }
        break;

      case 'firma_completada':
      case 'acta_lista_finalizar':
      case 'nueva_acta':
      case 'acta_finalizada':
      case 'silencio_administrativo':
        // Navegar al detalle del acta
        if (notificacion.actaId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActaDetalleScreen(actaId: notificacion.actaId!),
            ),
          );
        } else {
          _mostrarMensaje('No se encontró el acta asociada');
        }
        break;

      case 'compromiso_vencido':
      case 'compromiso_proximo':
        // Navegar a Mis Compromisos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MisCompromisosScreen(),
          ),
        );
        break;

      case 'sistema':
      default:
        // Para notificaciones del sistema, solo mostrar mensaje
        _mostrarMensaje('Notificación del sistema');
        break;
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFF39A900),
        foregroundColor: Colors.white,
        actions: [
          if (_totalNoLeidas > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas como leídas',
              onPressed: _marcarTodasComoLeidas,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),

          // Contador de no leídas
          if (_totalNoLeidas > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.notifications_active,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$_totalNoLeidas notificación${_totalNoLeidas > 1 ? 'es' : ''} sin leer',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de notificaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _notificaciones.isEmpty
                        ? _buildEmpty()
                        : _buildLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro por tipo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tiposNotificacion.map((tipo) {
                final isSelected = _filtroTipo == tipo['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tipo['label']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filtroTipo = tipo['value'];
                      });
                      _cargarNotificaciones();
                    },
                    selectedColor: const Color(0xFF39A900).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF39A900),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Filtro por estado
          Row(
            children: [
              FilterChip(
                label: const Text('No leídas'),
                selected: _filtroLeida == false,
                onSelected: (selected) {
                  setState(() {
                    _filtroLeida = selected ? false : null;
                  });
                  _cargarNotificaciones();
                },
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Leídas'),
                selected: _filtroLeida == true,
                onSelected: (selected) {
                  setState(() {
                    _filtroLeida = selected ? true : null;
                  });
                  _cargarNotificaciones();
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView.builder(
        itemCount: _notificaciones.length,
        itemBuilder: (context, index) {
          final notificacion = _notificaciones[index];
          return Dismissible(
            key: Key('notificacion-${notificacion.id}'),
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Deslizar a la derecha: marcar como leída
                if (!notificacion.leida) {
                  await _marcarComoLeida(notificacion);
                }
                return false;
              } else {
                // Deslizar a la izquierda: eliminar
                return true;
              }
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                _eliminarNotificacion(notificacion);
              }
            },
            child: _buildNotificacionCard(notificacion),
          );
        },
      ),
    );
  }

  Widget _buildNotificacionCard(Notificacion notificacion) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: notificacion.leida ? 0 : 2,
      color: notificacion.leida ? Colors.grey.shade50 : Colors.white,
      child: InkWell(
        onTap: () => _navegarDesdeNotificacion(notificacion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notificacion.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notificacion.icono,
                  color: notificacion.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: TextStyle(
                              fontWeight: notificacion.leida
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notificacion.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF39A900),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Mensaje
                    Text(
                      notificacion.mensaje,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Tipo y fecha
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: notificacion.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notificacion.tipoTexto,
                            style: TextStyle(
                              fontSize: 12,
                              color: notificacion.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(notificacion.fechaCreacion,
                              locale: 'es'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando recibas notificaciones\naparecerán aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar notificaciones',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarNotificaciones,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39A900),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
