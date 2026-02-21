import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/ride_provider.dart';
import '../../services/ride_service.dart';
import 'waiting_driver_screen.dart';
import 'pending_requests_screen.dart';

class RequestRideScreen extends StatefulWidget {
  final LatLng currentLocation;

  const RequestRideScreen({super.key, required this.currentLocation});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final RideService _rideService = RideService();

  LatLng? _pickupLocation;
  GoogleMapController? _mapController;
  bool _isRequestingRide = false;
  bool _useCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    _pickupLocation = widget.currentLocation;
    _pickupController.text = 'Tu ubicación actual';
    
    // Limpiar cualquier viaje activo en caché para evitar errores fantasma
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      rideProvider.clearCurrentRide();
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickupLocation = position;
      _useCurrentLocation = false;
      _pickupController.text = 'Punto seleccionado en el mapa';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Punto de recogida actualizado'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _resetToCurrentLocation() {
    setState(() {
      _pickupLocation = widget.currentLocation;
      _useCurrentLocation = true;
      _pickupController.text = 'Tu ubicación actual';
    });
    
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLocation!, 15),
      );
    }
  }

  void _showActiveRideDialog(String message) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Buscar el viaje activo en el servidor
    final result = await _rideService.checkActiveRide();
    
    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (result['success'] == true && result['hasActiveRide'] == true) {
      final ride = result['ride'];
      
      // Mostrar diálogo con el viaje encontrado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Viaje Activo Encontrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tienes un viaje activo en el sistema:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('Estado: ${ride.status}'),
              const SizedBox(height: 8),
              Text('Origen: ${ride.pickupAddress}'),
              const SizedBox(height: 8),
              Text('Destino: ${ride.dropoffAddress}'),
              const SizedBox(height: 16),
              const Text(
                'Debes cancelar este viaje para poder solicitar uno nuevo.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Cerrar diálogo
                
                // Mostrar confirmación
                final shouldCancel = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancelar Viaje'),
                    content: const Text('¿Deseas cancelar este viaje?'),
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
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                final rideProvider = Provider.of<RideProvider>(context, listen: false);
                rideProvider.setCurrentRide(ride);
                final cancelResult = await rideProvider.cancelRide(reason: 'Cancelado para nueva solicitud');
                
                if (!mounted) return;
                Navigator.pop(context); // Cerrar loading
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(cancelResult['message'] ?? 'Viaje cancelado'),
                    backgroundColor: cancelResult['success'] ? Colors.green : Colors.red,
                  ),
                );
                
                if (cancelResult['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Ahora puedes solicitar un nuevo viaje'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancelar Viaje'),
            ),
          ],
        ),
      );
    } else {
      // No se encontró viaje activo, mostrar mensaje original
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Solicitud Activa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'No se pudo encontrar el viaje en el servidor. Verifica en solicitudes pendientes.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PendingRequestsScreen(autoCheckActive: true),
                  ),
                );
              },
              child: const Text('Ver Solicitudes'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _requestRide() async {
    print('🚕 Iniciando solicitud de viaje...');
    
    if (_pickupLocation == null) {
      print('❌ Error: No hay ubicación de recogida');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un punto de recogida')),
      );
      return;
    }

    print('📍 Ubicación de recogida: ${_pickupLocation!.latitude}, ${_pickupLocation!.longitude}');
    print('📝 Dirección: ${_pickupController.text}');

    setState(() {
      _isRequestingRide = true;
    });
    
    try {
      print('📡 Enviando solicitud al servidor...');
      final result = await _rideService.requestRide(
        pickupAddress: _pickupController.text,
        pickupLat: _pickupLocation!.latitude,
        pickupLng: _pickupLocation!.longitude,
        dropoffAddress: 'Por definir',
        dropoffLat: _pickupLocation!.latitude,
        dropoffLng: _pickupLocation!.longitude,
        distance: 0,
        estimatedDuration: 0,
        paymentMethod: 'cash',
      );

      print('✅ Respuesta recibida: $result');

      if (!mounted) return;

      setState(() {
        _isRequestingRide = false;
      });

      if (result['success'] == true) {
        print('✅ Solicitud exitosa, navegando a WaitingDriverScreen...');
        final rideProvider = Provider.of<RideProvider>(context, listen: false);
        rideProvider.setCurrentRide(result['ride']);
        
        // Navegar a la pantalla de espera
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingDriverScreen(ride: result['ride']),
          ),
        );
      } else {
        // Verificar si hay una solicitud activa
        final message = result['message'] ?? 'Error al solicitar viaje';
        print('⚠️ Error en solicitud: $message');
        if (message.contains('Ya tienes una solicitud') || message.contains('activa')) {
          _showActiveRideDialog(message);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error al solicitar viaje: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _isRequestingRide = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Viaje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: _pickupLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: _pickupLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                      infoWindow: const InfoWindow(title: 'Punto de recogida'),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Instrucciones superiores
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
                      children: [
                        const Icon(Icons.my_location, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pickupController.text,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_useCurrentLocation)
                      TextButton.icon(
                        onPressed: _resetToCurrentLocation,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('Usar mi ubicación actual'),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Instrucciones en el centro
          Positioned(
            bottom: 200,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📍 Toca el mapa para seleccionar dónde te recogerán\no usa tu ubicación actual',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Botón de solicitar viaje
          Positioned(
            bottom: 16,
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
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.two_wheeler, size: 40, color: Color(0xFF2E7D32)),
                        SizedBox(width: 12),
                        Text(
                          'Mototaxi Express',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isRequestingRide ? null : _requestRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isRequestingRide
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Solicitar Mototaxi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    super.dispose();
  }
}
