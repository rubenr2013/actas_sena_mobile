import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/api_service.dart';
import '../models/usuario.dart';
import '../models/dashboard.dart';
import '../models/firma_pendiente.dart';
import 'login_screen.dart';
import 'actas_list_screen.dart';
import 'perfil_screen.dart';
import 'crear_acta_screen.dart';
import 'firmas_pendientes_screen.dart';
import 'mis_compromisos_screen.dart';
import 'notificaciones_screen.dart';
import 'acta_detalle_screen.dart';
import 'firmar_acta_screen.dart';
import '../services/notificaciones_service.dart';
import '../services/firmas_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Usuario? _usuario;
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;
  int _notificacionesNoLeidas = 0;
  bool _canCreateActas = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _cargarContadorNotificaciones();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final usuario = await AuthService.getCurrentUser();
      final dashboard = await DashboardService.getDashboard();
      final canCreate = await ApiService.canCreateActas();

      setState(() {
        _usuario = usuario;
        _dashboardData = dashboard;
        _canCreateActas = canCreate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarContadorNotificaciones() async {
    try {
      final count = await NotificacionesService.contarNoLeidas();
      if (mounted) {
        setState(() {
          _notificacionesNoLeidas = count;
        });
      }
    } catch (e) {
      // Si hay error, simplemente no mostramos el badge
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistema de Gestión de Actas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF39A900),
        elevation: 0,
        actions: [
          // Badge de notificaciones en AppBar
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificacionesScreen(),
                    ),
                  );
                  _cargarContadorNotificaciones();
                },
                tooltip: 'Notificaciones',
              ),
              if (_notificacionesNoLeidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificacionesNoLeidas > 99
                          ? '99+'
                          : _notificacionesNoLeidas.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF39A900),
              ),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildStats(),
                        _buildActasRecientes(),
                        _buildFirmasPendientes(),
                        _buildCompromisosProximos(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF39A900),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFF39A900),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _usuario?.nombreCompleto ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _usuario?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF39A900)),
            title: const Text('Inicio'),
            selected: true,
            selectedColor: const Color(0xFF39A900),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerfilScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Mis Actas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ActasListScreen()));
            },
          ),
          // Solo mostrar "Crear Acta" para instructores y admins
          if (_canCreateActas)
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Crear Acta'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CrearActaScreen()));
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Firmar Actas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FirmasPendientesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in),
            title: const Text('Mis Compromisos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MisCompromisosScreen()),
              );
            },
          ),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_notificacionesNoLeidas > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _notificacionesNoLeidas > 99
                            ? '99+'
                            : _notificacionesNoLeidas.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text('Notificaciones'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificacionesScreen(),
                ),
              );
              _cargarContadorNotificaciones();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            textColor: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF39A900),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido, ${_usuario?.firstName ?? 'Usuario'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_dashboardData == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Actas',
                  _dashboardData!.estadisticas.totalActas.toString(),
                  Icons.description,
                  const Color(0xFF39A900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Firmas Pendientes',
                  _dashboardData!.estadisticas.firmasPendientes.toString(),
                  Icons.edit,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Mis Actas',
                  _dashboardData!.estadisticas.totalActas.toString(),
                  Icons.person,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Compromisos',
                  _dashboardData!.estadisticas.compromisosActivos.toString(),
                  Icons.assignment_turned_in,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActasRecientes() {
    if (_dashboardData == null || _dashboardData!.actasRecientes.isEmpty) {
      return _buildEmptySection(
        'Actas Recientes',
        Icons.description,
        'No hay actas recientes',
      );
    }

    return _buildSection(
      'Actas Recientes',
      Icons.description,
      Column(
        children: _dashboardData!.actasRecientes.map((acta) {
          return _buildActaCard(acta);
        }).toList(),
      ),
    );
  }

  Widget _buildActaCard(ActaReciente acta) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    Color statusColor = Colors.grey;

    switch (acta.estado) {
      case 'borrador':
        statusColor = Colors.orange;
        break;
      case 'en_revision':
        statusColor = Colors.blue;
        break;
      case 'finalizada':
        statusColor = Colors.green;
        break;
      case 'archivada':
        statusColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description, color: statusColor),
        ),
        title: Text(
          acta.numeroActa,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(acta.titulo),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    acta.estadoTexto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(acta.fechaCreacion),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActaDetalleScreen(actaId: acta.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFirmasPendientes() {
    if (_dashboardData == null || _dashboardData!.firmasPendientes.isEmpty) {
      return _buildEmptySection(
        'Firmas Pendientes',
        Icons.edit,
        'No hay firmas pendientes',
      );
    }

    return _buildSection(
      'Firmas Pendientes',
      Icons.edit,
      Column(
        children: _dashboardData!.firmasPendientes.map((firma) {
          return _buildFirmaCard(firma);
        }).toList(),
      ),
    );
  }

  Widget _buildFirmaCard(FirmaPendiente firma) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.edit, color: Colors.orange),
        ),
        title: Text(
          firma.acta.numeroActa,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(firma.acta.titulo),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(firma.acta.fechaReunion),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FirmarActaScreen(firmaPendiente: firma),
              ),
            );

            // Si firmó, recargar dashboard
            if (resultado == true && mounted) {
              _loadData();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39A900),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Firmar'),
        ),
      ),
    );
  }

  Widget _buildCompromisosProximos() {
    if (_dashboardData == null || _dashboardData!.compromisosProximos.isEmpty) {
      return _buildEmptySection(
        'Compromisos Próximos',
        Icons.check_circle,
        'No hay compromisos próximos',
      );
    }

    return _buildSection(
      'Compromisos Próximos',
      Icons.assignment_turned_in,
      Column(
        children: _dashboardData!.compromisosProximos.map((compromiso) {
          return _buildCompromisoCard(compromiso);
        }).toList(),
      ),
    );
  }

  Widget _buildCompromisoCard(CompromisoProximo compromiso) {
    Color statusColor = Colors.cyan;

    if (compromiso.estaVencido) {
      statusColor = Colors.red;
    } else if (compromiso.esProximo) {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.assignment, color: statusColor),
        ),
        title: Text(
          compromiso.descripcion,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Acta: ${compromiso.acta.numeroActa}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  compromiso.estaVencido ? Icons.error : Icons.access_time,
                  size: 12,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  compromiso.estaVencido
                      ? 'Vencido hace ${-compromiso.diasRestantes} días'
                      : 'Vence en ${compromiso.diasRestantes} días',
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: compromiso.porcentajeAvance / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 2),
            Text(
              '${compromiso.porcentajeAvance}% completado',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegar a la pantalla de compromisos
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MisCompromisosScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF39A900)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildEmptySection(String title, IconData icon, String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF39A900)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.check_circle,
                    size: 48, color: Color(0xFF39A900)),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
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
