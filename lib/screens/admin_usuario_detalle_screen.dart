import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_usuario.dart';
import '../services/admin_service.dart';

class AdminUsuarioDetalleScreen extends StatefulWidget {
  final int usuarioId;

  const AdminUsuarioDetalleScreen({super.key, required this.usuarioId});

  @override
  State<AdminUsuarioDetalleScreen> createState() =>
      _AdminUsuarioDetalleScreenState();
}

class _AdminUsuarioDetalleScreenState
    extends State<AdminUsuarioDetalleScreen> {
  AdminUsuario? _usuario;
  bool _isLoading = true;
  String? _error;
  bool _guardando = false;
  bool _huboCambios = false;

  // Estado local mutable mientras se edita
  late bool _cuentaAprobada;
  late bool _activo;
  late String _rolSeleccionado;

  static const _rolesDisponibles = [
    'aprendiz',
    'instructor',
    'invitado',
    'funcionario',
    'coordinador',
    'director',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usuario = await AdminService.getUsuarioDetalle(widget.usuarioId);
      setState(() {
        _usuario = usuario;
        _cuentaAprobada = usuario.cuentaAprobada;
        _activo = usuario.activo;
        _rolSeleccionado = _rolesDisponibles.contains(usuario.rol)
            ? usuario.rol
            : _rolesDisponibles.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _aprobarCuenta(bool aprobar) async {
    setState(() => _guardando = true);
    try {
      final resultado =
          await AdminService.aprobarCuenta(widget.usuarioId, aprobar);
      setState(() {
        _cuentaAprobada = resultado['cuenta_aprobada'] ?? aprobar;
        _huboCambios = true;
        _guardando = false;
      });
      _mostrarExito(resultado['message'] ?? 'Operación exitosa');
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _toggleActivo(bool activar) async {
    setState(() => _guardando = true);
    try {
      final resultado =
          await AdminService.activarUsuario(widget.usuarioId, activar);
      setState(() {
        _activo = resultado['activo'] ?? activar;
        _huboCambios = true;
        _guardando = false;
      });
      _mostrarExito(resultado['message'] ?? 'Operación exitosa');
    } catch (e) {
      setState(() {
        _activo = !activar; // revertir toggle
        _guardando = false;
      });
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _cambiarRol(String nuevoRol) async {
    setState(() => _guardando = true);
    try {
      final resultado =
          await AdminService.cambiarRol(widget.usuarioId, nuevoRol);
      setState(() {
        _rolSeleccionado = resultado['rol'] ?? nuevoRol;
        _huboCambios = true;
        _guardando = false;
      });
      _mostrarExito(resultado['message'] ?? 'Rol actualizado');
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _eliminarUsuario() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a '
          '${_usuario?.nombreCompleto ?? 'este usuario'}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _guardando = true);
    try {
      await AdminService.eliminarUsuario(widget.usuarioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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

  Color _colorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'instructor':
        return Colors.blue;
      case 'coordinador':
        return Colors.indigo;
      case 'director':
        return Colors.purple;
      case 'aprendiz':
        return Colors.green;
      case 'funcionario':
        return Colors.teal;
      case 'invitado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _huboCambios) {
          // Ya pasamos true cuando se hicieron cambios
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detalle de Usuario',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF39A900),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _huboCambios),
          ),
          actions: [
            if (_isLoading == false && _error == null)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _cargarDetalle,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF39A900)))
            : _error != null
                ? _buildError()
                : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          children: [
                            _buildHeader(),
                            _buildEstadoCuenta(),
                            _buildSeccionRol(),
                            _buildEstadisticas(),
                            _buildBotonEliminar(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      if (_guardando)
                        Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                    color: Color(0xFF39A900)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_usuario == null) return const SizedBox();
    final rolColor = _colorRol(_rolSeleccionado);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF39A900),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              _usuario!.iniciales,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF39A900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _usuario!.nombreCompleto.isNotEmpty
                ? _usuario!.nombreCompleto
                : _usuario!.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _usuario!.email,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: rolColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white54),
            ),
            child: Text(
              _rolSeleccionado[0].toUpperCase() + _rolSeleccionado.substring(1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          if (_usuario!.ultimoLogin != null) ...[
            const SizedBox(height: 8),
            Text(
              'Último acceso: ${dateFormat.format(_usuario!.ultimoLogin!)}',
              style:
                  const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoCuenta() {
    return _buildSeccion(
      'Estado de la Cuenta',
      Icons.manage_accounts,
      Column(
        children: [
          // Email verificado (solo lectura)
          _buildFilaEstado(
            'Email verificado',
            Icons.email,
            _usuario!.emailVerificado,
            null, // Solo lectura
          ),
          const Divider(height: 20),
          // Cuenta aprobada con botón
          Row(
            children: [
              Icon(Icons.verified,
                  size: 20,
                  color: _cuentaAprobada ? Colors.green : Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cuenta aprobada',
                        style: TextStyle(fontSize: 14)),
                    Text(
                      _cuentaAprobada ? 'Aprobada' : 'Pendiente de aprobación',
                      style: TextStyle(
                        fontSize: 12,
                        color: _cuentaAprobada ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _guardando ? null : () => _aprobarCuenta(!_cuentaAprobada),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _cuentaAprobada ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(_cuentaAprobada ? 'Rechazar' : 'Aprobar'),
              ),
            ],
          ),
          const Divider(height: 20),
          // Activo / inactivo con Switch
          Row(
            children: [
              Icon(Icons.power_settings_new,
                  size: 20, color: _activo ? Colors.blue : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cuenta activa', style: TextStyle(fontSize: 14)),
                    Text(
                      _activo ? 'El usuario puede iniciar sesión' : 'Cuenta suspendida',
                      style: TextStyle(
                        fontSize: 12,
                        color: _activo ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _activo,
                onChanged: _guardando ? null : _toggleActivo,
                activeColor: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilaEstado(
      String label, IconData icono, bool valor, VoidCallback? onTap) {
    return Row(
      children: [
        Icon(icono,
            size: 20, color: valor ? Colors.green : Colors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(
                valor ? 'Verificado' : 'No verificado',
                style: TextStyle(
                    fontSize: 12,
                    color: valor ? Colors.green : Colors.red),
              ),
            ],
          ),
        ),
        Icon(
          valor ? Icons.check_circle : Icons.cancel,
          color: valor ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildSeccionRol() {
    return _buildSeccion(
      'Rol del Usuario',
      Icons.badge,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona el rol del usuario. El rol "admin" no se puede asignar desde aquí.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _rolSeleccionado,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _rolesDisponibles
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _colorRol(r),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(r[0].toUpperCase() + r.substring(1)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: _guardando
                ? null
                : (nuevoRol) {
                    if (nuevoRol != null &&
                        nuevoRol != _rolSeleccionado) {
                      _cambiarRol(nuevoRol);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    if (_usuario?.stats == null) return const SizedBox();
    final s = _usuario!.stats!;

    return _buildSeccion(
      'Estadísticas',
      Icons.bar_chart,
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Actas creadas', s.totalActasCreadas, Icons.description,
                    Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Firmas pend.', s.firmasPendientes, Icons.edit,
                    Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Compromisos', s.compromisosAsignados, Icons.assignment,
                    Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Completados', s.compromisosCompletados, Icons.done_all,
                    Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icono, size: 26, color: color),
          const SizedBox(height: 6),
          Text(
            valor.toString(),
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildBotonEliminar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _guardando ? null : _eliminarUsuario,
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          label: const Text('Eliminar usuario',
              style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, IconData icono, Widget contenido) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: const Color(0xFF39A900), size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          contenido,
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarDetalle,
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
