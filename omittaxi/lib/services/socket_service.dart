import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  // Obtener instancia del socket
  static IO.Socket? get socket => _socket;
  static bool get isConnected => _isConnected;

  // Conectar al servidor WebSocket
  static Future<void> connect() async {
    if (_isConnected) {
      print('🔌 Socket ya está conectado');
      return;
    }

    try {
      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        _isConnected = true;
        print('✅ Socket conectado');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ Socket desconectado');
      });

      _socket!.onError((error) {
        print('❌ Error de socket: $error');
      });
    } catch (e) {
      print('❌ Error al conectar socket: $e');
    }
  }

  // Desconectar
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      print('🔌 Socket desconectado manualmente');
    }
  }

  // EVENTOS DE CONDUCTOR

  // Conductor se conecta en línea
  static void driverGoOnline(String driverId, Map<String, double> location) {
    if (_socket != null && _isConnected) {
      _socket!.emit('driver:online', {
        'driverId': driverId,
        'location': location,
      });
      print('🏍️ Conductor en línea');
    }
  }

  // Actualizar ubicación del conductor
  static void updateDriverLocation(
    String driverId,
    Map<String, double> location,
  ) {
    if (_socket != null && _isConnected) {
      _socket!.emit('driver:location', {
        'driverId': driverId,
        'location': location,
      });
    }
  }

  // Conductor se desconecta
  static void driverGoOffline(String driverId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('driver:offline', {'driverId': driverId});
      print('🏍️ Conductor fuera de línea');
    }
  }

  // EVENTOS DE PASAJERO

  // Solicitar viaje
  static void requestRide({
    required String rideId,
    required String passengerId,
    required Map<String, double> pickup,
    required Map<String, double> dropoff,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('ride:request', {
        'rideId': rideId,
        'passengerId': passengerId,
        'pickup': pickup,
        'dropoff': dropoff,
      });
      print('📞 Viaje solicitado');
    }
  }

  // EVENTOS DE VIAJE

  // Aceptar viaje
  static void acceptRide(String rideId, String driverId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('ride:accept', {'rideId': rideId, 'driverId': driverId});
      print('✅ Viaje aceptado');
    }
  }

  // Iniciar viaje
  static void startRide(String rideId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('ride:start', {'rideId': rideId});
      print('🚀 Viaje iniciado');
    }
  }

  // Completar viaje
  static void completeRide(String rideId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('ride:complete', {'rideId': rideId});
      print('🏁 Viaje completado');
    }
  }

  // LISTENERS

  // Escuchar nuevas solicitudes de viaje (para conductores)
  static void onNewRideRequest(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('ride:new-request', callback);
      print('👂 Escuchando nuevas solicitudes de viaje');
    }
  }

  // Escuchar cuando un viaje es aceptado (para pasajeros)
  static void onRideAccepted(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('ride:accepted', callback);
      print('👂 Escuchando aceptación de viajes');
    }
  }

  // Escuchar ubicación del conductor (para pasajeros en viaje)
  static void onDriverLocation(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('ride:driver-location', callback);
      print('👂 Escuchando ubicación del conductor');
    }
  }

  // Escuchar cuando el viaje inicia
  static void onRideStarted(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('ride:started', callback);
      print('👂 Escuchando inicio de viaje');
    }
  }

  // Escuchar cuando el viaje se completa
  static void onRideCompleted(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('ride:completed', callback);
      print('👂 Escuchando finalización de viaje');
    }
  }

  // Remover listeners
  static void removeListener(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  // Remover todos los listeners
  static void removeAllListeners() {
    if (_socket != null) {
      _socket!.clearListeners();
    }
  }
}
