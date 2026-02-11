import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  // Guardar token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Obtener token guardado
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Limpiar token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Registrar usuario
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
    Map<String, dynamic>? vehicleInfo,
    String? licenseNumber,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'userType': userType,
      };

      // Si es conductor, agregar info del vehículo
      if (userType == 'driver') {
        if (vehicleInfo != null) body['vehicleInfo'] = vehicleInfo;
        if (licenseNumber != null) body['licenseNumber'] = licenseNumber;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: ApiConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Guardar token
        await _saveToken(data['data']['token']);
        return {
          'success': true,
          'user': UserModel.fromJson(data['data']),
          'token': data['data']['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al registrar usuario',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: ApiConfig.headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Guardar token
        await _saveToken(data['data']['token']);
        return {
          'success': true,
          'user': UserModel.fromJson(data['data']),
          'token': data['data']['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciales inválidas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await clearToken();
  }

  // Obtener perfil del usuario
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/profile'),
            headers: ApiConfig.headersWithAuth(token),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'user': UserModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al obtener perfil',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Actualizar perfil
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    Map<String, dynamic>? vehicleInfo,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No hay sesión activa'};
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (vehicleInfo != null) body['vehicleInfo'] = vehicleInfo;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/users/profile'),
            headers: ApiConfig.headersWithAuth(token),
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'user': UserModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al actualizar perfil',
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
