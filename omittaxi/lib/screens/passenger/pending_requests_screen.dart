import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../providers/ride_provider.dart';
import 'package:intl/intl.dart';

class PendingRequestsScreen extends StatefulWidget {
  final bool autoCheckActive;
  
  const PendingRequestsScreen({super.key, this.autoCheckActive = false});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final RideService _rideService = RideService();
  List<RideModel> _pendingRides = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener todos los viajes del usuario (sin filtro de status)
      final result = await _rideService.getMyRides(
        limit: 50,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Filtrar solo viajes activos (requested, accepted, arrived, in_progress)
        final allRides = result['rides'] as List<RideModel>;
        final activeRides = allRides.where((ride) {
          return ['requested', 'accepted', 'arrived', 'in_progress'].contains(ride.status);
        }).toList();
        
        setState(() {
          _pendingRides = activeRides;
          _isLoading = false;
        });
        
        // Si autoCheckActive es true y no hay solicitudes pendientes, buscar viaje activo
        if (widget.autoCheckActive && _pendingRides.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkActiveRide();
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Error al cargar solicitudes';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRide(RideModel ride) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta solicitud de viaje?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    // Temporalmente establecer el viaje actual para poder cancelarlo
    rideProvider.setCurrentRide(ride);
    final result = await rideProvider.cancelRide(
      reason: 'Cancelado por el pasajero desde lista de solicitudes',
    );
    
    if (!mounted) return;
    
    // Cerrar diálogo de carga
    Navigator.pop(context);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud cancelada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Recargar lista
      _loadPendingRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al cancelar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'requested':
        return 'Buscando conductor';
      case 'accepted':
        return 'Aceptado';
      case 'in_progress':
        return 'En progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelAllPendingRides() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Todas'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar TODAS tus solicitudes pendientes? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sí, cancelar todas'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int canceledCount = 0;
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    for (var ride in _pendingRides) {
      rideProvider.setCurrentRide(ride);
      final result = await rideProvider.cancelRide(reason: 'Cancelación masiva por limpieza');
      if (result['success'] == true) {
        canceledCount++;
      }
    }

    if (!mounted) return;
    
    Navigator.pop(context); // Cerrar diálogo de carga

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$canceledCount solicitud(es) cancelada(s)'),
        backgroundColor: Colors.green,
      ),
    );

    _loadPendingRequests();
  }

  Future<void> _checkActiveRide() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _rideService.checkActiveRide();
    
    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (result['success'] == true) {
      if (result['hasActiveRide'] == true) {
        final ride = result['ride'];
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Viaje Activo Encontrado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado: ${ride.status}'),
                const SizedBox(height: 8),
                Text('Origen: ${ride.pickupAddress}'),
                const SizedBox(height: 8),
                Text('Creado: ${DateFormat('dd/MM/yyyy HH:mm').format(ride.requestTime)}'),
                const SizedBox(height: 16),
                const Text(
                  'Este viaje está en tu cuenta pero no aparece en la lista. ¿Deseas cancelarlo?',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final rideProvider = Provider.of<RideProvider>(context, listen: false);
                  rideProvider.setCurrentRide(ride);
                  final cancelResult = await rideProvider.cancelRide(reason: 'Limpieza de viaje fantasma');
                  
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(cancelResult['message'] ?? 'Viaje cancelado'),
                      backgroundColor: cancelResult['success'] ? Colors.green : Colors.red,
                    ),
                  );
                  
                  if (cancelResult['success']) {
                    _loadPendingRequests();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Cancelar Viaje'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ No hay viajes activos en el servidor'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al verificar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'cancel_all') {
                _cancelAllPendingRides();
              } else if (value == 'check_active') {
                _checkActiveRide();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'check_active',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Buscar viaje activo'),
                  ],
                ),
              ),
              if (_pendingRides.isNotEmpty)
                const PopupMenuItem(
                  value: 'cancel_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancelar todas'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadPendingRequests,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _pendingRides.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes viajes activos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tus solicitudes y viajes en curso aparecerán aquí',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Si el sistema indica que tienes una solicitud activa\\npero no la ves aquí, presiona el botón actualizar ↻',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingRides.length,
                        itemBuilder: (context, index) {
                          final ride = _pendingRides[index];
                          return _buildRideCard(ride);
                        },
                      ),
                    ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado y fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: _getStatusColor(ride.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(ride.status),
                        style: TextStyle(
                          color: _getStatusColor(ride.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(ride.requestTime),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Punto de recogida
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Punto de recogida',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.pickupAddress,
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

            const SizedBox(height: 12),

            // Destino
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.flag,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destino',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.dropoffAddress,
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

            const SizedBox(height: 16),

            // Tarifa eliminada - sin costos
            // Row(
            //   children: [
            //     const Icon(
            //       Icons.attach_money,
            //       color: Color(0xFF2E7D32),
            //       size: 20,
            //     ),
            //     const SizedBox(width: 4),
            //     Text(
            //       '\$${ride.fare.toStringAsFixed(2)}',
            //       style: const TextStyle(
            //         fontSize: 18,
            //         fontWeight: FontWeight.bold,
            //         color: Color(0xFF2E7D32),
            //       ),
            //     ),
            //   ],
            // ),

            const SizedBox(height: 16),

            // Botón cancelar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _cancelRide(ride),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar solicitud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
