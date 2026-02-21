import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../providers/user_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../config/api_config.dart';
import '../../models/ride_model.dart';
import '../profile_screen.dart';
import 'driver_navigation_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;
  int _selectedIndex = 0;
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isOnline = false;
  final LocationService _locationService = LocationService();
  int _totalTripsToday = 0;
  double _earningsToday = 0.0;
  List<RideModel> _availableRides = [];
  Timer? _ridesTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    SocketService.connect();
  }

  @override
  void dispose() {
    if (_isOnline) {
      _toggleOnlineStatus(); // Desconectar si está online
    }
    _ridesTimer?.cancel();
    _locationService.dispose();
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
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15),
        );
      } else {
        // Ubicación por defecto (Ciudad de México)
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

  void _toggleOnlineStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.id;
    final token = userProvider.token;

    if (userId == null || token == null) return;

    setState(() => _isOnline = !_isOnline);

    if (_isOnline) {
      // Conductor se conecta
      debugPrint('🟢 Conductor conectándose...');
      
      // Iniciar tracking de ubicación
      _locationService.startLocationTracking(userId, isDriver: true, token: token);
      
      // Notificar al servidor via WebSocket
      if (_currentPosition != null) {
        SocketService.driverGoOnline(userId, {
          'lat': _currentPosition!.latitude,
          'lng': _currentPosition!.longitude,
        });
      }

      // Cargar solicitudes disponibles
      _loadAvailableRides();
      
      // Actualizar cada 10 segundos
      _ridesTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _loadAvailableRides(),
      );

      // Escuchar nuevas solicitudes de viaje
      SocketService.onNewRideRequest((data) {
        debugPrint('📞 Nueva solicitud de viaje recibida: $data');
        _loadAvailableRides(); // Recargar lista
        _showNewRideDialog(data);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🟢 Ahora estás en línea'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Conductor se desconecta
      debugPrint('🔴 Conductor desconectándose...');
      
      // Detener tracking
      _locationService.stopLocationTracking();
      
      // Detener timer
      _ridesTimer?.cancel();
      
      // Limpiar solicitudes
      setState(() => _availableRides.clear());
      
      // Notificar al servidor
      SocketService.driverGoOffline(userId);
      SocketService.removeListener('ride:new-request');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔴 Ahora estás fuera de línea'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadAvailableRides() async {
    if (!_isOnline) {
      debugPrint('⚠️ No se cargan solicitudes porque conductor está offline');
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.token;

      if (token == null) {
        debugPrint('❌ No hay token disponible');
        return;
      }

      debugPrint('🔄 Cargando solicitudes disponibles...');
      final url = '${ApiConfig.baseUrl}/rides/available';
      debugPrint('📡 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.headersWithAuth(token),
      );

      debugPrint('📥 Respuesta HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ridesData = data['data'] as List?;

        if (ridesData != null) {
          setState(() {
            _availableRides = ridesData
                .map((ride) => RideModel.fromJson(ride))
                .toList();
          });
          debugPrint('📋 ${_availableRides.length} solicitudes disponibles');
        } else {
          debugPrint('⚠️ No hay datos de solicitudes en la respuesta');
        }
      } else {
        debugPrint('❌ Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error al cargar solicitudes: $e');
    }
  }

  Future<void> _acceptRide(String rideId) async {
    try {
      print('🔄 Intentando aceptar viaje: $rideId');
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.token;

      if (token == null) {
        print('❌ No hay token disponible');
        return;
      }

      print('📡 Enviando petición a: ${ApiConfig.baseUrl}/rides/$rideId/accept');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/rides/$rideId/accept'),
        headers: ApiConfig.headersWithAuth(token),
      );

      print('📨 Respuesta recibida: ${response.statusCode}');
      print('📨 Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Viaje aceptado exitosamente');
          
          if (!mounted) return;
          
          final rideProvider = Provider.of<RideProvider>(context, listen: false);
          final acceptedRide = RideModel.fromJson(data['data']);
          rideProvider.setCurrentRide(acceptedRide);
          
          setState(() {
            _availableRides.removeWhere((r) => r.id == rideId);
          });

          // Navegar a la pantalla de navegación con mapa y ruta
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverNavigationScreen(ride: acceptedRide),
              ),
            );
          }
        }
      } else {
        print('⚠️ Error del servidor: ${response.statusCode}');
        // Manejar errores del servidor (ej: ya tiene un viaje activo)
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error al aceptar el viaje'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error al aceptar viaje: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final rideProvider = Provider.of<RideProvider>(context);

    if (_selectedIndex == 1) {
      return const ProfileScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Angeles - Conductor'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOnline ? 'En línea' : 'Fuera de línea',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
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
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Estadísticas del conductor
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Viajes hoy', _totalTripsToday.toString()),
                        // Ganancia eliminada - sin tarifas
                        // _buildStat('Ganancia', '\$${_earningsToday.toStringAsFixed(0)}'),
                        _buildStat('Calificación', '4.8 ⭐'),
                        _buildStat('Estado', _isOnline ? '🟢 En línea' : '⚫ Fuera de línea'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de solicitudes disponibles
          if (_isOnline)
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🚨 Solicitudes Disponibles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_availableRides.length}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _availableRides.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  '👂 Esperando solicitudes...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _availableRides.length,
                              itemBuilder: (context, index) {
                                final ride = _availableRides[index];
                                return _buildRideCard(ride);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

          // Botón de estado
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _toggleOnlineStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOnline
                    ? Colors.red
                    : const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isOnline ? Icons.pause_circle : Icons.play_circle),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline ? 'DESCONECTAR' : 'CONECTAR',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showNewRideDialog(dynamic rideData) {
    if (!_isOnline || !mounted) return;

    // Extraer datos del viaje
    final pickup = rideData['pickup'] ?? 'Ubicación de recogida';
    final dropoff = rideData['dropoff'] ?? 'Destino';
    final distance = rideData['distance'] ?? '3.5 km';
    final fare = rideData['fare'] ?? '\$48.00';
    final rideId = rideData['rideId'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.notifications_active, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('¡Nuevo viaje!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.location_on, 'Recogida', pickup.toString()),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.flag, 'Destino', dropoff.toString()),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.straighten, 'Distancia', distance.toString()),
            // Tarifa eliminada - sin costos
            // const SizedBox(height: 8),
            // _buildInfoRow(Icons.attach_money, 'Tarifa', fare.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (rideId.isNotEmpty) {
                // Llamar al método HTTP que actualiza el estado correctamente
                await _acceptRide(rideId);
                if (mounted) {
                  setState(() {
                    _totalTripsToday++;
                  });
                }
                // La navegación a DriverNavigationScreen ya se hace dentro de _acceptRide
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showRideInProgress() {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final currentRide = rideProvider.currentRide;
    
    if (currentRide == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(currentRide.status == 'accepted' 
          ? 'Viaje aceptado' 
          : currentRide.status == 'arrived' 
            ? 'Esperando confirmación' 
            : 'Viaje en progreso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentRide.status == 'accepted' 
                ? Icons.navigation 
                : currentRide.status == 'arrived'
                  ? Icons.check_circle_outline
                  : Icons.two_wheeler, 
              size: 60, 
              color: const Color(0xFF2E7D32)
            ),
            const SizedBox(height: 16),
            Text(currentRide.status == 'accepted' 
              ? 'Dirigiéndote al punto de recogida...' 
              : currentRide.status == 'arrived'
                ? 'Esperando que el pasajero confirme tu llegada'
                : 'En viaje'),
            const SizedBox(height: 24),
            // Botón principal según estado
            if (currentRide.status == 'accepted')
              ElevatedButton(
                onPressed: () async {
                  await _markArrived();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('He llegado'),
              )
            else if (currentRide.status == 'arrived')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                // Confirmar cancelación
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Sí, cancelar'),
                      ),
                    ],
                  ),
                );
                
                if (shouldCancel != true) return;
                
                // Cancelar el viaje
                if (rideProvider.currentRide != null) {
                  final result = await rideProvider.cancelRide(reason: 'Cancelado por el conductor');
                  
                  if (!mounted) return;
                  
                  Navigator.pop(context); // Cerrar diálogo de viaje en progreso
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Viaje cancelado'),
                      backgroundColor: result['success'] ? Colors.orange : Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Cancelar viaje',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markArrived() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (rideProvider.currentRide == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/rides/${rideProvider.currentRide!.id}/arrive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userProvider.token}',
        },
      );

      final data = json.decode(response.body);

      if (data['success']) {
        // Actualizar el currentRide en el provider con los datos del response
        if (data['data'] != null) {
          final updatedRide = RideModel.fromJson(data['data']);
          rideProvider.setCurrentRide(updatedRide);
        }
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marcado como llegado. Esperando confirmación del pasajero.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error al marcar llegada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al marcar llegada: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRideCard(RideModel ride) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            ride.passenger?.name?.substring(0, 1).toUpperCase() ?? 'P',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          ride.passenger?.name ?? 'Pasajero',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${ride.pickupAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('🎯 ${ride.dropoffAddress}', maxLines: 1, overflow: TextOverflow.ellipsis),
            // Tarifa eliminada - sin costos
            // Text('💰 \$${ride.fare.toStringAsFixed(2)} • ${ride.distance.toStringAsFixed(1)} km'),
            Text('📏 ${ride.distance.toStringAsFixed(1)} km'),
          ],
        ),
        isThreeLine: true,
        trailing: ElevatedButton(
          onPressed: () => _acceptRide(ride.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Aceptar'),
        ),
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
              userProvider.currentUser?.name ?? 'Conductor',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userProvider.currentUser?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Mis Estadísticas'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Ganancias'),
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
}
