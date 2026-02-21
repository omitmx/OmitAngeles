import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../models/ride_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../config/api_config.dart';

class DriverNavigationScreen extends StatefulWidget {
  final RideModel ride;

  const DriverNavigationScreen({super.key, required this.ride});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  StreamSubscription<Position>? _positionSubscription;
  double? _distanceToPickup;
  int? _estimatedTime;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
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
            cancelledBy == 'passenger' 
              ? 'El pasajero canceló el viaje' 
              : 'El viaje fue cancelado',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    SocketService.socket?.off('ride:cancelled');
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      // Obtener ubicación actual
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo obtener tu ubicación')),
          );
        }
        return;
      }

      setState(() {
        _currentPosition = location;
      });

      // Configurar marcadores
      _setupMarkers();

      // Trazar ruta
      await _drawRoute();

      // Iniciar seguimiento de ubicación
      _startLocationTracking();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error inicializando navegación: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupMarkers() {
    final pickupLocation = widget.ride.pickupLocation;

    _markers = {
      // Marcador del conductor
      if (_currentPosition != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      // Marcador del punto de recogida
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Punto de recogida',
          snippet: widget.ride.pickupAddress,
        ),
      ),
    };
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null) return;

    final pickupLocation = widget.ride.pickupLocation;

    try {
      debugPrint('🗺️ Trazando ruta desde (${_currentPosition!.latitude}, ${_currentPosition!.longitude}) hasta (${pickupLocation.latitude}, ${pickupLocation.longitude})');
      
      final polylinePoints = PolylinePoints();
      
      // Usar Google Directions API
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: 'AIzaSyAfwKDVQH_w5_W2Fhtt-iNp0_KQfW-F95U',
        request: PolylineRequest(
          origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination: PointLatLng(pickupLocation.latitude, pickupLocation.longitude),
          mode: TravelMode.driving,
        ),
      );

      debugPrint('📍 Resultado de la ruta: ${result.status}');
      debugPrint('📍 Puntos obtenidos: ${result.points.length}');
      
      if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
        debugPrint('❌ Error en Directions API: ${result.errorMessage}');
      }

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        debugPrint('✅ Ruta trazada con ${polylineCoordinates.length} puntos');

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF2E7D32),
              width: 5,
              points: polylineCoordinates,
            ),
          };
        });

        // Calcular distancia y tiempo
        _calculateDistanceAndTime();

        // Ajustar la cámara para mostrar toda la ruta
        _fitRouteInView();
      } else {
        // Si no hay puntos, dibujar línea recta como fallback
        debugPrint('⚠️ No se obtuvieron puntos de la ruta, dibujando línea recta');
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFFFF9800), // Color naranja para indicar ruta aproximada
              width: 5,
              points: [_currentPosition!, pickupLocation],
              patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Línea punteada
            ),
          };
        });
        _calculateDistanceAndTime();
        _fitRouteInView();
      }
    } catch (e) {
      debugPrint('❌ Error trazando ruta: $e');
      // Fallback: dibujar línea recta
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFFFF9800), // Color naranja para indicar ruta aproximada
            width: 5,
            points: [_currentPosition!, pickupLocation],
            patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Línea punteada
          ),
        };
      });
      _calculateDistanceAndTime();
      _fitRouteInView();
    }
  }

  void _calculateDistanceAndTime() {
    if (_currentPosition == null) return;

    final pickupLocation = widget.ride.pickupLocation;

    // Calcular distancia en kilómetros
    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      pickupLocation.latitude,
      pickupLocation.longitude,
    );

    setState(() {
      _distanceToPickup = distanceInMeters / 1000;
      // Estimar tiempo (asumiendo velocidad promedio de 30 km/h en ciudad)
      _estimatedTime = ((distanceInMeters / 1000) * 2).round(); // minutos
    });
  }

  void _fitRouteInView() {
    if (_mapController == null || _currentPosition == null) return;

    final pickupLocation = widget.ride.pickupLocation;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        _currentPosition!.latitude < pickupLocation.latitude
            ? _currentPosition!.latitude
            : pickupLocation.latitude,
        _currentPosition!.longitude < pickupLocation.longitude
            ? _currentPosition!.longitude
            : pickupLocation.longitude,
      ),
      northeast: LatLng(
        _currentPosition!.latitude > pickupLocation.latitude
            ? _currentPosition!.latitude
            : pickupLocation.latitude,
        _currentPosition!.longitude > pickupLocation.longitude
            ? _currentPosition!.longitude
            : pickupLocation.longitude,
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _startLocationTracking() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.id;
    final token = userProvider.token;

    if (userId == null || token == null) return;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final newPosition = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = newPosition;
        _setupMarkers();
      });

      _calculateDistanceAndTime();

      // Actualizar ubicación en el servidor vía WebSocket
      SocketService.updateDriverLocation(
        userId,
        {
          'lat': newPosition.latitude,
          'lng': newPosition.longitude,
        },
      );
    });
  }

  Future<void> _markArrived() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/rides/${widget.ride.id}/arrive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (data['success']) {
        // Actualizar el currentRide en el provider
        if (data['data'] != null) {
          final updatedRide = RideModel.fromJson(data['data']);
          rideProvider.setCurrentRide(updatedRide);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Llegada confirmada. El pasajero ha sido notificado.'),
            backgroundColor: Colors.green,
          ),
        );

        // Mostrar diálogo de espera
        _showWaitingForPassenger();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error al confirmar llegada'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _showWaitingForPassenger() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Esperando al pasajero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Has llegado al punto de recogida.\nEsperando a ${widget.ride.passenger?.name ?? "el pasajero"}...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _cancelRide(),
            child: const Text('Cancelar viaje', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('¿Estás seguro de que deseas cancelar este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    try {
      final result = await rideProvider.cancelRide(reason: 'Cancelado por el conductor');

      if (!mounted) return;

      // Navegar de vuelta a la pantalla de inicio del conductor
      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Viaje cancelado'),
          backgroundColor: result['success'] ? Colors.orange : Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error cancelando viaje: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navegando al pasajero'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Mapa
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(0, 0),
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitRouteInView();
                  },
                ),

                // Panel de información compacto
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Color(0xFF2E7D32)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.ride.passenger?.name ?? 'Pasajero',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.ride.pickupAddress,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_distanceToPickup != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_distanceToPickup!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (_estimatedTime != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '$_estimatedTime min',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botones de acción
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón "He llegado"
                      ElevatedButton(
                        onPressed: _markArrived,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle),
                            SizedBox(width: 8),
                            Text(
                              'He llegado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Botón "Cancelar"
                      OutlinedButton(
                        onPressed: _cancelRide,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Cancelar viaje',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
