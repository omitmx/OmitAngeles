import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'socket_service.dart';
import '../config/api_config.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentLocation;
  String? _userToken;

  LatLng? get currentLocation => _currentLocation;

  /// Obtener ubicación actual
  Future<LatLng?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permisos de ubicación denegados permanentemente');
        return null;
      }

      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Permisos de ubicación denegados');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      debugPrint('📍 Ubicación actual: ${position.latitude}, ${position.longitude}');
      
      return _currentLocation;
    } catch (e) {
      debugPrint('❌ Error al obtener ubicación: $e');
      return null;
    }
  }

  /// Verificar si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Iniciar tracking de ubicación en tiempo real para conductores
  void startLocationTracking(String userId, {bool isDriver = false, String? token}) {
    debugPrint('🔄 Iniciando tracking de ubicación para usuario: $userId');
    _userToken = token;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      _currentLocation = LatLng(position.latitude, position.longitude);
      
      if (isDriver) {
        // Enviar ubicación del conductor via WebSocket
        SocketService.updateDriverLocation(
          userId,
          {
            'lat': position.latitude,
            'lng': position.longitude,
          },
        );
        
        // TAMBIÉN enviar via HTTP para que nearby-drivers pueda encontrarlo
        if (_userToken != null) {
          try {
            await http.post(
              Uri.parse('${ApiConfig.baseUrl}/location/update'),
              headers: ApiConfig.headersWithAuth(_userToken!),
              body: json.encode({
                'lat': position.latitude,
                'lng': position.longitude,
              }),
            );
            debugPrint('📡 Ubicación del conductor actualizada vía HTTP+WebSocket');
          } catch (e) {
            debugPrint('⚠️ Error al actualizar ubicación vía HTTP: $e');
          }
        }
      }
    }, onError: (error) {
      debugPrint('❌ Error en tracking de ubicación: $error');
    });
  }

  /// Detener tracking de ubicación
  void stopLocationTracking() {
    debugPrint('🛑 Deteniendo tracking de ubicación');
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Calcular distancia entre dos puntos
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Formatear distancia en km o metros
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Limpiar recursos
  void dispose() {
    stopLocationTracking();
  }
}
