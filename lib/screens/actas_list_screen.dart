import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/acta.dart';
import '../services/actas_service.dart';
import 'acta_detalle_screen.dart'; 
import 'crear_acta_screen.dart';

class ActasListScreen extends StatefulWidget {
  const ActasListScreen({super.key});

  @override
  State<ActasListScreen> createState() => _ActasListScreenState();
}

class _ActasListScreenState extends State<ActasListScreen> {
  List<Acta> _actas = [];
  List<Acta> _actasFiltradas = [];
  bool _isLoading = true;
  String? _error;
  String _filtroEstado = 'todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final actas = await ActasService.getActas(
        estado: _filtroEstado,
        search: _searchController.text,
      );

      setState(() {
        _actas = actas;
        _actasFiltradas = actas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _actasFiltradas = _actas;
      } else {
        _actasFiltradas = _actas.where((acta) {
          return acta.titulo.toLowerCase().contains(query.toLowerCase()) ||
              acta.numeroActa.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _onFiltroChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _filtroEstado = newValue;
      });
      _loadActas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Actas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF39A900),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadActas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF39A900),
                    ),
                  )
                : _error != null
                    ? _buildError()
                    : _actasFiltradas.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadActas,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _actasFiltradas.length,
                              itemBuilder: (context, index) {
                                return _buildActaCard(_actasFiltradas[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=> const CrearActaScreen()),
          );
        },
        backgroundColor: const Color(0xFF39A900),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Búsqueda
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por título o número...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF39A900)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF39A900)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF39A900), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtro de estado
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF39A900)),
              const SizedBox(width: 8),
              const Text(
                'Filtrar por estado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _filtroEstado,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'borrador', child: Text('Borrador')),
                    DropdownMenuItem(value: 'en_revision', child: Text('En Revisión')),
                    DropdownMenuItem(value: 'finalizada', child: Text('Finalizada')),
                    DropdownMenuItem(value: 'archivada', child: Text('Archivada')),
                  ],
                  onChanged: _onFiltroChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActaCard(Acta acta) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle de acta
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActaDetalleScreen(actaId: acta.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Número y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      acta.numeroActa,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF39A900),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: acta.estadoColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      acta.estadoTexto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Título
              Text(
                acta.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Información adicional
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(acta.fechaReunion),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      acta.lugarReunion,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    acta.tipoReunionTexto,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    acta.modalidad == 'presencial'
                        ? Icons.people
                        : acta.modalidad == 'virtual'
                            ? Icons.videocam
                            : Icons.location_city,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    acta.modalidadTexto,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              // Badge de IA si aplica
              if (acta.generadaConIa) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology, size: 12, color: Colors.purple),
                      const SizedBox(width: 4),
                      const Text(
                        'Generada con IA',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const Divider(height: 20),
              
              // Progreso de firmas
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Firmas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${acta.estadisticasFirmas.completadas}/${acta.estadisticasFirmas.total}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: acta.estadisticasFirmas.porcentaje / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            acta.estadisticasFirmas.porcentaje == 100
                                ? Colors.green
                                : const Color(0xFF39A900),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${acta.estadisticasFirmas.porcentaje.toStringAsFixed(0)}% completado',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay actas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty || _filtroEstado != 'todos'
                  ? 'No se encontraron actas con estos filtros'
                  : 'Aún no has creado ninguna acta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.isNotEmpty || _filtroEstado != 'todos') {
                  // Limpiar filtros
                  setState(() {
                    _searchController.clear();
                    _filtroEstado = 'todos';
                  });
                  _loadActas();
                } else {
                  // Crear nueva acta
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidad próximamente')),
                  );
                }
              },
              icon: Icon(
                _searchController.text.isNotEmpty || _filtroEstado != 'todos'
                    ? Icons.clear
                    : Icons.add,
              ),
              label: Text(
                _searchController.text.isNotEmpty || _filtroEstado != 'todos'
                    ? 'Limpiar filtros'
                    : 'Crear primera acta',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39A900),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
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
              'Error al cargar actas',
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadActas,
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