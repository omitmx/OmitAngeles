import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride_model.dart';
import 'package:uuid/uuid.dart';

class RideProvider with ChangeNotifier {
  RideModel? _currentRide;
  List<RideModel> _rideHistory = [];
  LatLng? _currentLocation;
  final List<RideModel> _availableRides = [];

  RideModel? get currentRide => _currentRide;
  List<RideModel> get rideHistory => _rideHistory;
  LatLng? get currentLocation => _currentLocation;
  List<RideModel> get availableRides => _availableRides;

  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
    notifyListeners();
  }

  void requestRide({
    required String passengerId,
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
    required String pickupAddress,
    required String dropoffAddress,
    required double distance,
  }) {
    // Calcular tarifa base: $20 + $8 por km
    final fare = 20 + (distance * 8);

    final ride = RideModel(
      id: const Uuid().v4(),
      passengerId: passengerId,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      requestTime: DateTime.now(),
      status: 'pending',
      fare: fare,
      distance: distance,
    );

    _currentRide = ride;
    _availableRides.add(ride);
    notifyListeners();
  }

  void acceptRide(String driverId, String rideId) {
    if (_currentRide?.id == rideId) {
      _currentRide = _currentRide!.copyWith(
        driverId: driverId,
        status: 'accepted',
        pickupTime: DateTime.now(),
      );
      notifyListeners();
    }

    // Actualizar en la lista de viajes disponibles
    final index = _availableRides.indexWhere((r) => r.id == rideId);
    if (index != -1) {
      _availableRides[index] = _availableRides[index].copyWith(
        driverId: driverId,
        status: 'accepted',
        pickupTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void startRide() {
    if (_currentRide != null) {
      _currentRide = _currentRide!.copyWith(status: 'in_progress');
      notifyListeners();
    }
  }

  void completeRide() {
    if (_currentRide != null) {
      _currentRide = _currentRide!.copyWith(
        status: 'completed',
        dropoffTime: DateTime.now(),
      );
      _rideHistory.insert(0, _currentRide!);
      notifyListeners();
    }
  }

  void cancelRide() {
    if (_currentRide != null) {
      _currentRide = _currentRide!.copyWith(status: 'cancelled');
      _rideHistory.insert(0, _currentRide!);
      _currentRide = null;
      notifyListeners();
    }
  }

  void rateRide(int rating, String review) {
    if (_currentRide != null) {
      // Determinar si calificar como pasajero o conductor
      final ratedRide = _currentRide!.copyWith(
        passengerRating: rating,
        passengerComment: review,
      );

      // Actualizar en el historial
      final index = _rideHistory.indexWhere((r) => r.id == _currentRide!.id);
      if (index != -1) {
        _rideHistory[index] = ratedRide;
      }

      _currentRide = null;
      notifyListeners();
    }
  }

  void clearCurrentRide() {
    _currentRide = null;
    notifyListeners();
  }

  // Simulación de viajes disponibles para conductores
  void loadAvailableRides() {
    // En una app real, esto cargaría desde un servidor
    _availableRides.clear();
    notifyListeners();
  }
}
