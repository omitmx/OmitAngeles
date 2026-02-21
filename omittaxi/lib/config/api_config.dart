/// Configuración del API Backend
class ApiConfig {
  // URL base del API (usar IP local para dispositivos físicos)
  static const String baseUrl = 'http://192.168.50.126:3000/api';

  // URL para WebSocket (tiempo real)
  static const String socketUrl = 'http://192.168.50.126:3000';

  // Configuración de tarifas
  static const double baseFare = 20.0;
  static const double farePerKm = 8.0;

  // Timeouts
  static const int connectionTimeout = 30; // segundos
  static const int receiveTimeout = 30; // segundos

  // Headers comunes
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers con autenticación
  static Map<String, String> headersWithAuth(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
