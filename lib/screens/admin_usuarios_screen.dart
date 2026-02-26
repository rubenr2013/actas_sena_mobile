import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_usuario.dart';
import '../services/admin_service.dart';
import 'admin_usuario_detalle_screen.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  List<AdminUsuario> _usuarios = [];
  bool _isLoading = true;
  String? _error;
  int _total = 0;

  // Filtros activos
  String _filtroActivo = 'todos'; // todos | no_verificados | no_aprobados | rol
  String? _filtroRol;
  final TextEditingController _buscarController = TextEditingController();
  String _buscarTexto = '';

  static const _roles = [
    'aprendiz',
    'instructor',
    'invitado',
    'funcionario',
    'coordinador',
    'director',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool? verificado;
      bool? aprobado;
      String? rol;

      switch (_filtroActivo) {
        case 'no_verificados':
          verificado = false;
          break;
        case 'no_aprobados':
          aprobado = false;
          break;
        case 'rol':
          rol = _filtroRol;
          break;
      }

      final resultado = await AdminService.getUsuarios(
        rol: rol,
        verificado: verificado,
        aprobado: aprobado,
        buscar: _buscarTexto.isNotEmpty ? _buscarTexto : null,
      );

      setState(() {
        _usuarios = resultado['usuarios'] as List<AdminUsuario>;
        _total = resultado['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onBuscar(String valor) {
    setState(() => _buscarTexto = valor);
    _cargarUsuarios();
  }

  void _aplicarFiltro(String filtro, {String? rol}) {
    setState(() {
      _filtroActivo = filtro;
      _filtroRol = rol;
    });
    _cargarUsuarios();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF39A900),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarUsuarios,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _aplicarFiltro('no_aprobados'),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.pending_actions, color: Colors.white),
        label: const Text(
          'Pendientes',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildBusqueda(),
          _buildFiltros(),
          if (!_isLoading && !(_error != null))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '$_total usuario${_total != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildBusqueda() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _buscarController,
        onChanged: _onBuscar,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o email...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF39A900)),
          suffixIcon: _buscarTexto.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscarController.clear();
                    _onBuscar('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _buildChipFiltro('Todos', 'todos', Icons.people),
          const SizedBox(width: 8),
          _buildChipFiltro(
              'No verificados', 'no_verificados', Icons.email_outlined,
              color: Colors.red),
          const SizedBox(width: 8),
          _buildChipFiltro(
              'No aprobados', 'no_aprobados', Icons.hourglass_empty,
              color: Colors.orange),
          const SizedBox(width: 8),
          _buildMenuRoles(),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String label, String valor, IconData icono,
      {Color? color}) {
    final activo = _filtroActivo == valor;
    final chipColor = color ?? const Color(0xFF39A900);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: activo ? Colors.white : chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: activo ? Colors.white : chipColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
      selected: activo,
      onSelected: (_) => _aplicarFiltro(valor),
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      side: BorderSide(color: chipColor),
      showCheckmark: false,
    );
  }

  Widget _buildMenuRoles() {
    final activo = _filtroActivo == 'rol';
    return PopupMenuButton<String>(
      onSelected: (rol) => _aplicarFiltro('rol', rol: rol),
      itemBuilder: (_) => _roles
          .map((r) => PopupMenuItem(
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
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge,
                size: 14,
                color: activo ? Colors.white : Colors.indigo),
            const SizedBox(width: 4),
            Text(
              activo && _filtroRol != null
                  ? _filtroRol![0].toUpperCase() + _filtroRol!.substring(1)
                  : 'Por rol',
              style: TextStyle(
                color: activo ? Colors.white : Colors.indigo,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color: activo ? Colors.white : Colors.indigo),
          ],
        ),
        selected: activo,
        onSelected: null,
        backgroundColor: Colors.white,
        selectedColor: Colors.indigo,
        side: const BorderSide(color: Colors.indigo),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39A900)),
      );
    }
    if (_error != null) {
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
                onPressed: _cargarUsuarios,
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
    if (_usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No se encontraron usuarios',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarUsuarios,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        itemCount: _usuarios.length,
        itemBuilder: (_, i) => _buildUsuarioCard(_usuarios[i]),
      ),
    );
  }

  Widget _buildUsuarioCard(AdminUsuario u) {
    final rolColor = _colorRol(u.rol);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final actualizado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AdminUsuarioDetalleScreen(usuarioId: u.id),
            ),
          );
          if (actualizado == true) _cargarUsuarios();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar con iniciales
              CircleAvatar(
                radius: 26,
                backgroundColor: rolColor.withOpacity(0.15),
                child: Text(
                  u.iniciales,
                  style: TextStyle(
                    color: rolColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + badge de rol
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            u.nombreCompleto.isNotEmpty
                                ? u.nombreCompleto
                                : u.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: rolColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            u.rol[0].toUpperCase() + u.rol.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: rolColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      u.email,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Íconos de estado
                    Row(
                      children: [
                        _buildEstadoIcono(
                          u.emailVerificado,
                          'Email',
                          Icons.email,
                        ),
                        const SizedBox(width: 10),
                        _buildEstadoIcono(
                          u.cuentaAprobada,
                          'Aprobado',
                          Icons.verified,
                        ),
                        const SizedBox(width: 10),
                        _buildEstadoIcono(
                          u.activo,
                          'Activo',
                          Icons.circle,
                        ),
                        const Spacer(),
                        if (u.fechaRegistro != null)
                          Text(
                            dateFormat.format(u.fechaRegistro!),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoIcono(bool activo, String label, IconData icono) {
    final color = activo ? Colors.green : Colors.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(activo ? Icons.check_circle : Icons.cancel,
            size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
