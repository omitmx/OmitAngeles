import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/user_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../config/api_config.dart';
import '../../utils/map_icon_helper.dart';
import 'request_ride_screen.dart';
import 'pending_requests_screen.dart';
import '../profile_screen.dart';
import '../ride_history_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  GoogleMapController? _mapController;
  int _selectedIndex = 0;
  LatLng? _currentPosition;
  bool _isLoading = true;
  final LocationService _locationService = LocationService();
  final Set<Marker> _markers = {};
  Timer? _nearbyDriversTimer;
  BitmapDescriptor? _mototaxiIcon;

  @override
  void initState() {
    super.initState();
    _loadMototaxiIcon();
    _initializeLocation();
    SocketService.connect();
  }

  Future<void> _loadMototaxiIcon() async {
    _mototaxiIcon = await MapIconHelper.getMototaxiIcon();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nearbyDriversTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _currentPosition = location;
          _isLoading = false;
        });
        
        if (mounted) {
          Provider.of<RideProvider>(context, listen: false)
              .setCurrentLocation(_currentPosition!);
        }

        // Cargar conductores cercanos
        _loadNearbyDrivers();
        
        // Actualizar conductores cada 10 segundos
        _nearbyDriversTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => _loadNearbyDrivers(),
        );
      } else {
        setState(() {
          _currentPosition = const LatLng(19.4326, -99.1332);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      setState(() {
        _currentPosition = const LatLng(19.4326, -99.1332);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearbyDrivers() async {
    if (_currentPosition == null) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.token;

      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/location/nearby-drivers?lat=${_currentPosition!.latitude}&lng=${_currentPosition!.longitude}&radius=5000',
        ),
        headers: ApiConfig.headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final drivers = data['drivers'] as List?;

        if (drivers != null && drivers.isNotEmpty) {
          setState(() {
            _markers.clear();
            
            // Agregar marcador de posición actual
            _markers.add(
              Marker(
                markerId: const MarkerId('current'),
                position: _currentPosition!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Tu ubicación'),
              ),
            );

            // Agregar marcadores de conductores cercanos
            for (var i = 0; i < drivers.length; i++) {
              final driver = drivers[i];
              final location = driver['location'];
              final driverName = driver['name'] ?? 'Conductor';
              final distance = driver['distance'] ?? 0;
              final rating = (driver['rating'] ?? 0.0).toDouble();
              
              _markers.add(
                Marker(
                  markerId: MarkerId('driver_${driver['driverId']}'),
                  position: LatLng(
                    location['lat'].toDouble(),
                    location['lng'].toDouble(),
                  ),
                  icon: _mototaxiIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: InfoWindow(
                    title: '$driverName',
                    snippet: '${distance}m • ⭐ ${rating.toStringAsFixed(1)}',
                  ),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar conductores cercanos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final rideProvider = Provider.of<RideProvider>(context);

    if (_selectedIndex == 1) {
      return const RideHistoryScreen();
    }

    if (_selectedIndex == 2) {
      return const ProfileScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Angeles - Pasajero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context, userProvider),
      body: Stack(
        children: [
          if (!_isLoading && _currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 15),
                  );
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              markers: _markers,
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Card de información
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${userProvider.currentUser?.name ?? 'Usuario'}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.two_wheeler, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${_markers.length > 0 ? _markers.length - 1 : 0} conductores cerca',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón de solicitar viaje
          // Botón de solicitar viaje
          if (rideProvider.currentRide == null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPosition != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RequestRideScreen(currentLocation: _currentPosition!),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.two_wheeler, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Solicitar Mototaxi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Card de viaje activo
          if (rideProvider.currentRide != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler, 
                            size: 40, 
                            color: Color(0xFF2E7D32)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getRideStatusText(rideProvider.currentRide!.status),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rideProvider.currentRide!.pickupAddress,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Ver detalles del viaje
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Ver Detalles'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showCancelDialog(rideProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserProvider userProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
            ),
            accountName: Text(
              userProvider.currentUser?.name ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userProvider.currentUser?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.two_wheeler),
            title: const Text('Mis Viajes'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions),
            title: const Text('Viajes Activos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingRequestsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Métodos de Pago'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ayuda'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              userProvider.logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  String _getRideStatusText(String status) {
    switch (status) {
      case 'pending':
      case 'requested':
        return '🔍 Buscando conductor...';
      case 'accepted':
        return '✅ Conductor en camino';
      case 'in_progress':
        return '🏍️ Viaje en progreso';
      case 'arrived':
        return '📍 Conductor ha llegado';
      default:
        return 'Viaje activo';
    }
  }

  void _showCancelDialog(RideProvider rideProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Viaje'),
        content: const Text('¿Estás seguro de que deseas cancelar este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final result = await rideProvider.cancelRide(
                reason: 'Cancelado por el pasajero',
              );
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Viaje cancelado'),
                  backgroundColor: result['success'] == true 
                      ? Colors.green 
                      : Colors.red,
                ),
              );
            },
            child: const Text('Sí, cancelar', 
              style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
