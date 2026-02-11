import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class DriverService {
  final AuthService _authService = AuthService();

  // Conectarse en línea
  Future<Map<String, dynamic>> goOnline(LatLng location) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/drivers/online'),
            headers: ApiConfig.headersWithAuth(token),
            body: jsonEncode({
              'latitude': location.latitude,
              'longitude': location.longitude,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'driver': UserModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al conectarse',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Desconectarse
  Future<Map<String, dynamic>> goOffline() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/drivers/offline'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'driver': UserModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al desconectarse',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Actualizar ubicación
  Future<Map<String, dynamic>> updateLocation(LatLng location) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/drivers/location'),
            headers: ApiConfig.headersWithAuth(token),
            body: jsonEncode({
              'latitude': location.latitude,
              'longitude': location.longitude,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'location': data['data']['location']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al actualizar ubicación',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Buscar conductores cercanos
  Future<Map<String, dynamic>> getNearbyDrivers(
    LatLng location, {
    int radius = 5000,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final queryParams = {
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'radius': radius.toString(),
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/drivers/nearby',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: ApiConfig.headersWithAuth(token))
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final drivers = (data['data'] as List)
            .map((driver) => UserModel.fromJson(driver))
            .toList();
        return {'success': true, 'drivers': drivers, 'count': data['count']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al buscar conductores',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
}
