import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/acta.dart';
import '../services/actas_service.dart';
import '../services/firmas_service.dart';
import 'firmar_acta_screen.dart';
import 'editar_acta_screen.dart';
import '../services/pdf_service.dart';
import 'package:open_file/open_file.dart';
import '../services/adjuntos_service.dart';
import '../models/archivo_adjunto.dart';

class ActaDetalleScreen extends StatefulWidget {
  final int actaId;

  const ActaDetalleScreen({super.key, required this.actaId});

  @override
  State<ActaDetalleScreen> createState() => _ActaDetalleScreenState();
}

class _ActaDetalleScreenState extends State<ActaDetalleScreen> {
  ActaDetalle? _acta;
  bool _isLoading = true;
  String? _error;
  List<ArchivoAdjunto> _adjuntos = [];
  bool _cargandoAdjuntos = false;

  @override
  void initState() {
    super.initState();
    _loadActa();
    _cargarAdjuntos();
  }

  Future<void> _loadActa() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final acta = await ActasService.getActaDetalle(widget.actaId);

      setState(() {
        _acta = acta;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarAdjuntos() async {
    setState(() => _cargandoAdjuntos = true);
    try {
      final adjuntos = await AdjuntosService.listarAdjuntos(widget.actaId);
      setState(() {
        _adjuntos = adjuntos;
        _cargandoAdjuntos = false;
      });
    } catch (e) {
      setState(() => _cargandoAdjuntos = false);
    }
  }

  Future<void> _descargarAdjunto(ArchivoAdjunto adjunto) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descargando archivo...')),
      );

      final filePath = await AdjuntosService.descargarAdjunto(
        actaId: widget.actaId,
        adjuntoId: adjunto.id,
        nombreArchivo: adjunto.nombreOriginal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo descargado: $filePath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    // Mensajes según el estado
    String mensaje = '';
    String confirmacion = '';

    if (nuevoEstado == 'en_revision') {
      mensaje = '¿Enviar acta a revisión?';
      confirmacion = 'Los participantes podrán firmarla';
    } else if (nuevoEstado == 'archivada') {
      mensaje = '¿Archivar esta acta?';
      confirmacion = 'Podrás recuperarla después';
    }

    // Confirmar con el usuario
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mensaje),
        content: Text(confirmacion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39A900),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      await ActasService.cambiarEstadoActa(
        actaId: widget.actaId,
        nuevoEstado: nuevoEstado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar el acta
        _loadActa();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aplicarSilencioAdministrativo() async {
    // Confirmar con el usuario
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.orange),
            SizedBox(width: 10),
            Text('Aplicar Silencio Administrativo'),
          ],
        ),
        content: const Text(
          'Se aplicará silencio administrativo a esta acta. '
          'Todas las firmas pendientes serán marcadas como firmadas automáticamente '
          'y el acta pasará a estado "Finalizada".\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final resultado =
          await ActasService.aplicarSilencioAdministrativo(widget.actaId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                resultado['message'] ?? 'Silencio administrativo aplicado'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Recargar el acta
        _loadActa();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _acta?.numeroActa ?? 'Cargando...',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF39A900),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadActa,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF39A900),
              ),
            )
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadActa,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildInfoBasica(),
                        _buildContenido(),
                        _buildParticipantes(),
                        _buildCompromisos(),
                        _buildArchivosAdjuntos(),
                        _buildBotonesAccion(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _acta != null && _acta!.permisosUsuario.puedeFirmar
          ? FloatingActionButton.extended(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                // Buscar la firma pendiente de este usuario para esta acta
                try {
                  final firmasPendientes =
                      await FirmasService.getActasPendientesFirma();
                  final firmaPendiente = firmasPendientes.firstWhere(
                    (f) => f.acta.id == widget.actaId,
                  );

                  if (!mounted) return;

                  // Navegar a firmar
                  final resultado = await navigator.push(
                    MaterialPageRoute(
                      builder: (context) =>
                          FirmarActaScreen(firmaPendiente: firmaPendiente),
                    ),
                  );

                  // Si firmó, recargar
                  if (resultado == true && mounted) {
                    _loadActa();
                  }
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Firmar'),
              backgroundColor: const Color(0xFF39A900),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    if (_acta == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _acta!.estadoColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _acta!.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _acta!.estadoTexto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_acta!.generadaConIa)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Generada con IA',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBasica() {
    if (_acta == null) return const SizedBox();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
          const Text(
            'Información General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 20),
          _buildInfoRow(Icons.calendar_today, 'Fecha de reunión',
              dateFormat.format(_acta!.fechaReunion)),
          _buildInfoRow(Icons.location_on, 'Lugar', _acta!.lugarReunion),
          _buildInfoRow(Icons.category, 'Tipo', _acta!.tipoReunionTexto),
          _buildInfoRow(
            _acta!.modalidad == 'presencial'
                ? Icons.people
                : _acta!.modalidad == 'virtual'
                    ? Icons.videocam
                    : Icons.location_city,
            'Modalidad',
            _acta!.modalidadTexto,
          ),
          _buildInfoRow(Icons.person, 'Creador', _acta!.creador.nombreCompleto),
          _buildInfoRow(Icons.access_time, 'Creada',
              dateFormat.format(_acta!.fechaCreacion)),

          // Progreso de firmas
          const SizedBox(height: 16),
          const Text(
            'Progreso de Firmas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_acta!.estadisticasFirmas.completadas} de ${_acta!.estadisticasFirmas.total} firmas',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '${_acta!.estadisticasFirmas.porcentaje.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _acta!.estadisticasFirmas.porcentaje / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _acta!.estadisticasFirmas.porcentaje == 100
                  ? Colors.green
                  : const Color(0xFF39A900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF39A900)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_acta == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          const Text(
            'Contenido del Acta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 20),

          // Orden del día
          const Text(
            'Orden del Día',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF39A900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _acta!.ordenDia.isEmpty ? 'Sin orden del día' : _acta!.ordenDia,
            style: TextStyle(
              fontSize: 14,
              color: _acta!.ordenDia.isEmpty ? Colors.grey : Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          // Desarrollo
          const Text(
            'Desarrollo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF39A900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _acta!.desarrollo.isEmpty ? 'Sin desarrollo' : _acta!.desarrollo,
            style: TextStyle(
              fontSize: 14,
              color: _acta!.desarrollo.isEmpty ? Colors.grey : Colors.black87,
            ),
          ),

          // Observaciones si existen
          if (_acta!.observaciones.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Observaciones',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF39A900),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _acta!.observaciones,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantes() {
    if (_acta == null || _acta!.participantes.isEmpty) {
      return _buildEmptySection('Participantes', Icons.people);
    }

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
              const Icon(Icons.people, color: Color(0xFF39A900)),
              const SizedBox(width: 8),
              const Text(
                'Participantes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_acta!.participantes.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF39A900),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...(_acta!.participantes.map((participante) {
            return _buildParticipanteCard(participante);
          })),
        ],
      ),
    );
  }

  Widget _buildParticipanteCard(Participante participante) {
    final haFirmado = participante.firma?.firmado ?? false;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: haFirmado ? Colors.green : Colors.grey,
          child: Icon(
            haFirmado ? Icons.check : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          participante.usuario.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(participante.usuario.email,
                style: const TextStyle(fontSize: 12)),
            if (participante.rolEnReunion.isNotEmpty)
              Text(
                participante.rolEnReunion,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (haFirmado && participante.firma!.fechaFirma != null)
              Text(
                'Firmado: ${dateFormat.format(participante.firma!.fechaFirma!)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Icon(
          haFirmado ? Icons.check_circle : Icons.pending,
          color: haFirmado ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildCompromisos() {
    if (_acta == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              const Icon(Icons.assignment, color: Color(0xFF39A900)),
              const SizedBox(width: 8),
              const Text(
                'Compromisos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_acta!.compromisos.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF39A900),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Lista de compromisos
          if (_acta!.compromisos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay compromisos registrados',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...(_acta!.compromisos.map((compromiso) {
              return _buildCompromisoCard(compromiso);
            })),
        ],
      ),
    );
  }

  Widget _buildCompromisoCard(Compromiso compromiso) {
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
                    compromiso.descripcion,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: compromiso.estadoColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    compromiso.estadoTexto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  compromiso.responsable.nombreCompleto,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  compromiso.estaVencido ? Icons.error : Icons.calendar_today,
                  size: 14,
                  color: compromiso.estadoColor,
                ),
                const SizedBox(width: 4),
                Text(
                  compromiso.estaVencido
                      ? 'Vencido hace ${-compromiso.diasRestantes} días'
                      : 'Vence: ${dateFormat.format(compromiso.fechaLimite)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: compromiso.estadoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: compromiso.porcentajeAvance / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(compromiso.estadoColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${compromiso.porcentajeAvance}% completado',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivosAdjuntos() {
    if (_acta == null) return const SizedBox();

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
              const Icon(Icons.attach_file, color: Color(0xFF39A900)),
              const SizedBox(width: 8),
              const Text(
                'Archivos Adjuntos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_adjuntos.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF39A900),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Loading o contenido
          if (_cargandoAdjuntos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_adjuntos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay archivos adjuntos',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            // Lista de archivos
            ..._adjuntos.map((adjunto) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(adjunto.icono, color: adjunto.colorIcono, size: 32),
                  title: Text(
                    adjunto.nombreOriginal,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adjunto.tamanoFormateado,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (adjunto.descripcion != null &&
                          adjunto.descripcion!.isNotEmpty)
                        Text(
                          adjunto.descripcion!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF39A900)),
                    onPressed: () => _descargarAdjunto(adjunto),
                    tooltip: 'Descargar',
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
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
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Sin $title',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    if (_acta == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botón: Descargar PDF (disponible para todos)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _descargarPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Descargar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botón: Editar Acta (solo si está en borrador y tiene permisos)
          if (_acta!.estado == 'borrador' &&
              _acta!.permisosUsuario.puedeEditar) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditarActaScreen(acta: _acta!),
                          ),
                        );

                        // Si se guardaron cambios, recargar el acta
                        if (resultado == true && mounted) {
                          _loadActa();
                        }
                      },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Acta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botón: Enviar a Revisión (solo si está en borrador)
          if (_acta!.estado == 'borrador') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : () => _cambiarEstado('en_revision'),
                icon: const Icon(Icons.send),
                label: const Text('Enviar a Revisión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botón: Aplicar Silencio Administrativo (solo si cumple condiciones)
          if (_acta!.estado == 'en_revision' &&
              _acta!.puedeAplicarSilencio) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El plazo de firmas ha vencido. Puedes aplicar silencio administrativo.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading ? null : _aplicarSilencioAdministrativo,
                      icon: const Icon(Icons.gavel),
                      label: const Text('Aplicar Silencio Administrativo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botón: Archivar (solo si está finalizada)
          if (_acta!.estado == 'finalizada') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _isLoading ? null : () => _cambiarEstado('archivada'),
                icon: const Icon(Icons.archive),
                label: const Text('Archivar Acta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
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
              'Error al cargar acta',
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
              onPressed: _loadActa,
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

  Future<void> _descargarPdf() async {
    setState(() => _isLoading = true);

    try {
      // Mostrar diálogo de descarga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Descargando PDF...'),
            ],
          ),
        ),
      );

      // Descargar PDF
      final filePath = await PdfService.descargarPdfActa(_acta!.id);

      // Cerrar diálogo de descarga
      if (mounted) Navigator.pop(context);

      setState(() => _isLoading = false);

      // Mostrar diálogo de éxito
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('PDF Descargado'),
              ],
            ),
            content: Text('El PDF se guardó en:\n$filePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await OpenFile.open(filePath);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de descarga si está abierto
      if (mounted) Navigator.pop(context);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
