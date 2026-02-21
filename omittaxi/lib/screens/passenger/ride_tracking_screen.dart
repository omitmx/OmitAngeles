import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';
import '../../services/socket_service.dart';
import '../../utils/map_icon_helper.dart';
import 'dart:async';

class RideTrackingScreen extends StatefulWidget {
  final RideModel ride;

  const RideTrackingScreen({super.key, required this.ride});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _driverLocation;
  Set<Marker> _markers = {};
  bool _isCancelling = false;
  String _rideStatus = 'accepted';
  BitmapDescriptor? _mototaxiIcon;

  @override
  void initState() {
    super.initState();
    _loadMototaxiIcon();
    _setupMapMarkers();
    _setupSocketListeners();
    _rideStatus = widget.ride.status;
  }

  Future<void> _loadMototaxiIcon() async {
    _mototaxiIcon = await MapIconHelper.getMototaxiIcon();
    if (mounted) {
      setState(() {});
      _updateDriverMarker(); // Actualizar el marcador con el nuevo icono
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    SocketService.socket?.off('driver:location');
    SocketService.socket?.off('driver:arrived');
    SocketService.socket?.off('ride:cancelled');
    SocketService.socket?.off('ride:completed');
    super.dispose();
  }

  void _setupMapMarkers() {
    final markers = <Marker>{};

    // Marcador del punto de recogida (pasajero)
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.ride.pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Punto de recogida',
          snippet: widget.ride.pickupAddress,
        ),
      ),
    );

    // Marcador del destino
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.ride.dropoffLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destino',
          snippet: widget.ride.dropoffAddress,
        ),
      ),
    );

    setState(() {
      _markers = markers;
    });

    // Ajustar la cámara para mostrar ambos puntos
    if (_mapController != null) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.ride.pickupLocation.latitude < widget.ride.dropoffLocation.latitude
            ? widget.ride.pickupLocation.latitude
            : widget.ride.dropoffLocation.latitude,
        widget.ride.pickupLocation.longitude < widget.ride.dropoffLocation.longitude
            ? widget.ride.pickupLocation.longitude
            : widget.ride.dropoffLocation.longitude,
      ),
      northeast: LatLng(
        widget.ride.pickupLocation.latitude > widget.ride.dropoffLocation.latitude
            ? widget.ride.pickupLocation.latitude
            : widget.ride.dropoffLocation.latitude,
        widget.ride.pickupLocation.longitude > widget.ride.dropoffLocation.longitude
            ? widget.ride.pickupLocation.longitude
            : widget.ride.dropoffLocation.longitude,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _setupSocketListeners() {
    // Escuchar actualizaciones de ubicación del conductor
    SocketService.socket?.on('driver:location', (data) {
      if (!mounted) return;
      
      if (data['location'] != null) {
        final lat = data['location']['lat'];
        final lng = data['location']['lng'];
        
        setState(() {
          _driverLocation = LatLng(lat, lng);
          _updateDriverMarker();
        });
      }
    });

    // Escuchar cuando el conductor llega
    SocketService.socket?.on('driver:arrived', (data) {
      print('🚗 Conductor ha llegado: $data');
      
      if (!mounted) return;
      
      setState(() {
        _rideStatus = 'arrived';
      });
      
      _showDriverArrivedDialog(data);
    });

    // Escuchar si el viaje es cancelado
    SocketService.socket?.on('ride:cancelled', (data) {
      print('❌ Viaje cancelado: $data');
      
      if (!mounted) return;
      
      final cancelledBy = data['cancelledBy'] ?? 'otro usuario';
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      rideProvider.clearCurrentRide();
      
      // Volver a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelledBy == 'driver' 
              ? 'El conductor canceló el viaje' 
              : 'El viaje fue cancelado',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    // Escuchar si el viaje es completado
    SocketService.socket?.on('ride:completed', (data) {
      if (!mounted) return;
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Viaje completado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _updateDriverMarker() {
    if (_driverLocation == null) return;

    final updatedMarkers = Set<Marker>.from(_markers);
    
    // Remover marcador anterior del conductor si existe
    updatedMarkers.removeWhere((m) => m.markerId.value == 'driver');
    
    // Crear título del marcador con número económico si está disponible
    String markerTitle = 'Conductor';
    if (widget.ride.driver?.economicNumber != null) {
      markerTitle = 'Unidad #${widget.ride.driver!.economicNumber}';
    }
    
    String markerSnippet = widget.ride.driver?.name ?? 'En camino';
    
    // Agregar marcador actualizado del conductor
    updatedMarkers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation!,
        icon: _mototaxiIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: markerTitle,
          snippet: markerSnippet,
        ),
      ),
    );

    setState(() {
      _markers = updatedMarkers;
    });
  }

  void _showDriverArrivedDialog(dynamic data) {
    final driverName = data['driver']?['name'] ?? 'El conductor';
    final driverPhone = data['driver']?['phone'] ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 30),
            SizedBox(width: 8),
            Text('¡Conductor ha llegado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$driverName ha llegado a tu punto de recogida.',
              style: const TextStyle(fontSize: 16),
            ),
            if (driverPhone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Teléfono: $driverPhone',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '¿Confirmas que el conductor está en tu ubicación?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              await _cancelRide();
            },
            child: const Text(
              'Cancelar viaje',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              await _confirmArrival();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar llegada'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmArrival() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    try {
      final result = await rideProvider.completeRide(widget.ride.id);
      
      if (!mounted) return;
      
      if (result['success']) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Viaje completado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al confirmar llegada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al confirmar llegada: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRide() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('¿Estás seguro de que deseas cancelar el viaje?'),
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

    setState(() => _isCancelling = true);

    try {
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      final result = await rideProvider.cancelRide(reason: 'Cancelado por el pasajero');

      if (!mounted) return;

      if (result['success']) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje cancelado'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al cancelar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al cancelar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  String _getStatusText() {
    switch (_rideStatus) {
      case 'accepted':
        return 'Conductor en camino...';
      case 'arrived':
        return '¡Conductor ha llegado!';
      default:
        return 'Viaje en progreso';
    }
  }

  IconData _getStatusIcon() {
    switch (_rideStatus) {
      case 'accepted':
        return Icons.directions_car;
      case 'arrived':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreando viaje'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.ride.pickupLocation,
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
          ),

          // Panel de información del conductor
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _rideStatus == 'arrived' 
                              ? Colors.green 
                              : const Color(0xFF2E7D32),
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.ride.driver?.name != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (widget.ride.driver?.economicNumber != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '#${widget.ride.driver!.economicNumber}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        widget.ride.driver!.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (widget.ride.driver?.phone != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '📞 ${widget.ride.driver!.phone}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón cancelar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _isCancelling ? null : _cancelRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Cancelar viaje',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
