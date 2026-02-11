import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/ride_provider.dart';
import 'dart:math';

class RequestRideScreen extends StatefulWidget {
  final LatLng currentLocation;

  const RequestRideScreen({super.key, required this.currentLocation});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Polyline? _route;

  @override
  void initState() {
    super.initState();
    _pickupLocation = widget.currentLocation;
    _pickupController.text = 'Tu ubicación actual';
    _updateMarkers();
  }

  void _updateMarkers() {
    _markers = {};

    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Punto de recogida'),
        ),
      );
    }

    if (_destinationLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destino'),
        ),
      );

      // Simular ruta
      _createRoute();
    }

    setState(() {});
  }

  void _createRoute() {
    if (_pickupLocation != null && _destinationLocation != null) {
      _route = Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupLocation!, _destinationLocation!],
        color: const Color(0xFF2E7D32),
        width: 5,
      );
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // km

    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLon = _degreesToRadians(end.longitude - start.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _selectDestination() {
    // En una app real, esto abriría un buscador de lugares
    // Por ahora, usamos una ubicación de ejemplo
    setState(() {
      _destinationLocation = LatLng(
        widget.currentLocation.latitude + 0.01,
        widget.currentLocation.longitude + 0.01,
      );
      _destinationController.text = 'Destino seleccionado';
      _updateMarkers();

      // Animar la cámara para mostrar ambos puntos
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                min(_pickupLocation!.latitude, _destinationLocation!.latitude),
                min(
                  _pickupLocation!.longitude,
                  _destinationLocation!.longitude,
                ),
              ),
              northeast: LatLng(
                max(_pickupLocation!.latitude, _destinationLocation!.latitude),
                max(
                  _pickupLocation!.longitude,
                  _destinationLocation!.longitude,
                ),
              ),
            ),
            100,
          ),
        );
      }
    });
  }

  void _requestRide() {
    if (_destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un destino')),
      );
      return;
    }

    final distance = _calculateDistance(
      _pickupLocation!,
      _destinationLocation!,
    );
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    rideProvider.requestRide(
      passengerId: userProvider.currentUser!.id,
      pickupLocation: _pickupLocation!,
      dropoffLocation: _destinationLocation!,
      pickupAddress: _pickupController.text,
      dropoffAddress: _destinationController.text,
      distance: distance,
    );

    Navigator.pop(context);

    _showRideRequestedDialog();
  }

  void _showRideRequestedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Buscando conductor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Estamos buscando un conductor cerca de ti...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Provider.of<RideProvider>(context, listen: false).cancelRide();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fare = _destinationLocation != null
        ? 20 + (_calculateDistance(_pickupLocation!, _destinationLocation!) * 8)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Viaje')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _route != null ? {_route!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildLocationCard(
                  icon: Icons.my_location,
                  controller: _pickupController,
                  hint: 'Punto de recogida',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildLocationCard(
                  icon: Icons.location_on,
                  controller: _destinationController,
                  hint: 'Selecciona tu destino',
                  onTap: _selectDestination,
                ),
              ],
            ),
          ),

          if (_destinationLocation != null)
            Positioned(
              bottom: 16,
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mototaxi Express',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '3-5 min',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.two_wheeler, size: 40),
                              const SizedBox(width: 8),
                              Text(
                                '\$${fare.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _requestRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
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

  Widget _buildLocationCard({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                ),
                readOnly: true,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}
