import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/ride_model.dart';
import 'auth_service.dart';

class RideService {
  final AuthService _authService = AuthService();

  // Solicitar viaje
  Future<Map<String, dynamic>> requestRide({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
    required double distance,
    int? estimatedDuration,
    String paymentMethod = 'cash',
  }) async {
    try {
      print('🔐 Obteniendo token...');
      final token = await _authService.getToken();
      if (token == null) {
        print('❌ No hay token de sesión');
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      print('📡 Enviando POST a ${ApiConfig.baseUrl}/rides/request');
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/rides/request'),
            headers: ApiConfig.headersWithAuth(token),
            body: jsonEncode({
              'pickupAddress': pickupAddress,
              'pickupLat': pickupLat,
              'pickupLng': pickupLng,
              'dropoffAddress': dropoffAddress,
              'dropoffLat': dropoffLat,
              'dropoffLng': dropoffLng,
              'distance': distance,
              'estimatedDuration': estimatedDuration,
              'paymentMethod': paymentMethod,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      print('📨 Respuesta del API: statusCode=${response.statusCode}');
      print('📨 Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        print('✅ Parseando datos del viaje...');
        print('📄 Data del viaje: ${data['data']}');
        
        try {
          final rideModel = RideModel.fromJson(data['data']);
          print('✅ Modelo creado correctamente');
          return {'success': true, 'ride': rideModel};
        } catch (e, stackTrace) {
          print('❌ Error al parsear RideModel: $e');
          print('Stack: $stackTrace');
          return {
            'success': false,
            'message': 'Error al procesar datos del viaje: ${e.toString()}',
          };
        }
      } else {
        print('⚠️ Respuesta no exitosa del API');
        return {
          'success': false,
          'message': data['message'] ?? 'Error al solicitar viaje',
        };
      }
    } catch (e, stackTrace) {
      print('❌ Error en requestRide: $e');
      print('Stack: $stackTrace');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Aceptar viaje (conductor)
  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/rides/$rideId/accept'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'ride': RideModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al aceptar viaje',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Iniciar viaje (conductor)
  Future<Map<String, dynamic>> startRide(String rideId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/rides/$rideId/start'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'ride': RideModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al iniciar viaje',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Completar viaje (conductor)
  Future<Map<String, dynamic>> completeRide(String rideId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/rides/$rideId/complete'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'ride': RideModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al completar viaje',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Cancelar viaje
  Future<Map<String, dynamic>> cancelRide(String rideId, String reason) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/rides/$rideId/cancel'),
            headers: ApiConfig.headersWithAuth(token),
            body: jsonEncode({'reason': reason}),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'ride': RideModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al cancelar viaje',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Calificar viaje
  Future<Map<String, dynamic>> rateRide(
    String rideId,
    int rating,
    String? comment,
  ) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/rides/$rideId/rate'),
            headers: ApiConfig.headersWithAuth(token),
            body: jsonEncode({'rating': rating, 'comment': comment}),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'ride': RideModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al calificar viaje',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener mis viajes
  Future<Map<String, dynamic>> getMyRides({
    String? status,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final queryParams = {'limit': limit.toString(), 'page': page.toString()};
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/rides/my-rides',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: ApiConfig.headersWithAuth(token))
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final rides = (data['data'] as List)
            .map((ride) => RideModel.fromJson(ride))
            .toList();
        return {
          'success': true,
          'rides': rides,
          'total': data['total'],
          'page': data['page'],
          'pages': data['pages'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener viajes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener viajes disponibles (para conductores)
  Future<Map<String, dynamic>> getAvailableRides({
    double? latitude,
    double? longitude,
    int radius = 10000,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final queryParams = <String, String>{};
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      queryParams['radius'] = radius.toString();

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/rides/available/list',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: ApiConfig.headersWithAuth(token))
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final rides = (data['data'] as List)
            .map((ride) => RideModel.fromJson(ride))
            .toList();
        return {'success': true, 'rides': rides, 'count': data['count']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener viajes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener detalle de un viaje
  Future<Map<String, dynamic>> getRideDetails(String rideId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/rides/$rideId'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'ride': RideModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener viaje',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Verificar si hay un viaje activo
  Future<Map<String, dynamic>> checkActiveRide() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/rides/active/check'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['hasActiveRide'] == true && data['data'] != null) {
          return {
            'success': true,
            'hasActiveRide': true,
            'ride': RideModel.fromJson(data['data'])
          };
        } else {
          return {'success': true, 'hasActiveRide': false, 'ride': null};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al verificar viaje',
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
