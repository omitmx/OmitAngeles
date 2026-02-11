# 📱 Guía de Uso de la API en Flutter

## ✅ Integración Completada

La app Angeles ahora está completamente integrada con el backend API.

## 📁 Archivos Creados

### Servicios
- ✅ `lib/services/auth_service.dart` - Autenticación (login/registro)
- ✅ `lib/services/ride_service.dart` - Gestión de viajes
- ✅ `lib/services/driver_service.dart` - Funciones de conductores
- ✅ `lib/services/socket_service.dart` - WebSocket en tiempo real

### Configuración
- ✅ `lib/config/api_config.dart` - URLs y configuración del API

### Modelos Actualizados
- ✅ `lib/models/user_model.dart` - Compatible con API
- ✅ `lib/models/ride_model.dart` - Compatible con API

### Dependencias Agregadas
- ✅ `http: ^1.1.0` - Peticiones HTTP
- ✅ `socket_io_client: ^2.0.3+1` - WebSocket
- ✅ `shared_preferences: ^2.2.2` - Almacenamiento local

---

## 🚀 Cómo Usar los Servicios

### 1. Autenticación (AuthService)

```dart
import 'package:omittaxi/services/auth_service.dart';

final authService = AuthService();

// REGISTRO DE PASAJERO
final result = await authService.register(
  name: 'Juan Pérez',
  email: 'juan@example.com',
  phone: '+525512345678',
  password: 'password123',
  userType: 'passenger',
);

if (result['success']) {
  final user = result['user']; // UserModel
  final token = result['token'];
  print('Usuario registrado: ${user.name}');
} else {
  print('Error: ${result['message']}');
}

// REGISTRO DE CONDUCTOR
final driverResult = await authService.register(
  name: 'Carlos Conductor',
  email: 'carlos@example.com',
  phone: '+525587654321',
  password: 'password123',
  userType: 'driver',
  vehicleInfo: {
    'brand': 'Honda',
    'model': 'Wave',
    'year': 2022,
    'plate': 'ABC-123',
    'color': 'Rojo',
  },
  licenseNumber: 'LIC123456',
);

// LOGIN
final loginResult = await authService.login(
  email: 'juan@example.com',
  password: 'password123',
);

if (loginResult['success']) {
  final user = loginResult['user'];
  print('Bienvenido ${user.name}');
}

// OBTENER PERFIL
final profileResult = await authService.getProfile();
if (profileResult['success']) {
  final user = profileResult['user'];
}

// LOGOUT
await authService.logout();
```

### 2. Gestión de Viajes (RideService)

```dart
import 'package:omittaxi/services/ride_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final rideService = RideService();

// SOLICITAR VIAJE (Pasajero)
final requestResult = await rideService.requestRide(
  pickupAddress: 'Av. Reforma 123, CDMX',
  pickupLat: 19.4326,
  pickupLng: -99.1332,
  dropoffAddress: 'Polanco, CDMX',
  dropoffLat: 19.4400,
  dropoffLng: -99.1900,
  distance: 4.2,
  estimatedDuration: 12,
  paymentMethod: 'cash',
);

if (requestResult['success']) {
  final ride = requestResult['ride']; // RideModel
  print('Viaje solicitado. ID: ${ride.id}');
  print('Tarifa: \$${ride.fare}');
}

// ACEPTAR VIAJE (Conductor)
final acceptResult = await rideService.acceptRide(rideId);
if (acceptResult['success']) {
  final ride = acceptResult['ride'];
  print('Viaje aceptado');
}

// INICIAR VIAJE (Conductor)
await rideService.startRide(rideId);

// COMPLETAR VIAJE (Conductor)
await rideService.completeRide(rideId);

// CANCELAR VIAJE
await rideService.cancelRide(rideId, 'No encontré al pasajero');

// CALIFICAR VIAJE
await rideService.rateRide(
  rideId,
  5, // rating 1-5
  'Excelente servicio!', // comentario
);

// OBTENER MIS VIAJES
final myRidesResult = await rideService.getMyRides(
  status: 'completed', // opcional
  limit: 10,
  page: 1,
);

if (myRidesResult['success']) {
  final rides = myRidesResult['rides'] as List<RideModel>;
  for (var ride in rides) {
    print('Viaje: ${ride.pickupAddress} → ${ride.dropoffAddress}');
  }
}

// OBTENER VIAJES DISPONIBLES (Conductor)
final availableResult = await rideService.getAvailableRides(
  latitude: 19.4326,
  longitude: -99.1332,
  radius: 5000, // metros
);

if (availableResult['success']) {
  final rides = availableResult['rides'] as List<RideModel>;
  print('Viajes disponibles: ${rides.length}');
}
```

### 3. Funciones de Conductor (DriverService)

```dart
import 'package:omittaxi/services/driver_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final driverService = DriverService();

// CONECTARSE EN LÍNEA
final location = LatLng(19.4326, -99.1332);
final onlineResult = await driverService.goOnline(location);
if (onlineResult['success']) {
  print('Conductor en línea');
}

// ACTUALIZAR UBICACIÓN
await driverService.updateLocation(LatLng(19.4330, -99.1335));

// DESCONECTARSE
await driverService.goOffline();

// BUSCAR CONDUCTORES CERCANOS (Pasajero)
final nearbyResult = await driverService.getNearbyDrivers(
  LatLng(19.4326, -99.1332),
  radius: 5000,
);

if (nearbyResult['success']) {
  final drivers = nearbyResult['drivers'] as List<UserModel>;
  print('Conductores cercanos: ${drivers.length}');
}
```

### 4. WebSocket en Tiempo Real (SocketService)

```dart
import 'package:omittaxi/services/socket_service.dart';

// CONECTAR AL SOCKET
await SocketService.connect();

// CONDUCTOR: Conectarse en línea
SocketService.driverGoOnline(
  'userId123',
  {'lat': 19.4326, 'lng': -99.1332},
);

// CONDUCTOR: Actualizar ubicación periódicamente
Timer.periodic(Duration(seconds: 5), (timer) {
  SocketService.updateDriverLocation(
    'userId123',
    {'lat': 19.4326, 'lng': -99.1332},
  );
});

// CONDUCTOR: Escuchar nuevas solicitudes de viaje
SocketService.onNewRideRequest((data) {
  print('Nueva solicitud de viaje!');
  print('Pickup: ${data['pickup']}');
  print('Dropoff: ${data['dropoff']}');
  // Mostrar notificación al conductor
});

// PASAJERO: Solicitar viaje
SocketService.requestRide(
  rideId: 'ride123',
  passengerId: 'user456',
  pickup: {'lat': 19.4326, 'lng': -99.1332},
  dropoff: {'lat': 19.4400, 'lng': -99.1900},
);

// PASAJERO: Escuchar cuando el viaje es aceptado
SocketService.onRideAccepted((data) {
  print('¡Tu viaje fue aceptado!');
  print('Conductor ID: ${data['driverId']}');
  // Navegar a pantalla de tracking
});

// PASAJERO: Escuchar ubicación del conductor
SocketService.onDriverLocation((data) {
  final location = data['location'];
  print('Conductor en: ${location['lat']}, ${location['lng']}');
  // Actualizar marcador en el mapa
});

// CONDUCTOR: Aceptar viaje
SocketService.acceptRide('ride123', 'driver789');

// CONDUCTOR: Iniciar viaje
SocketService.startRide('ride123');

// CONDUCTOR: Completar viaje
SocketService.completeRide('ride123');

// DESCONECTAR
SocketService.disconnect();
```

---

## 💡 Ejemplo Completo: Flujo de Pasajero

```dart
import 'package:flutter/material.dart';
import 'package:omittaxi/services/auth_service.dart';
import 'package:omittaxi/services/ride_service.dart';
import 'package:omittaxi/services/socket_service.dart';

class PassengerFlow extends StatefulWidget {
  @override
  _PassengerFlowState createState() => _PassengerFlowState();
}

class _PassengerFlowState extends State<PassengerFlow> {
  final authService = AuthService();
  final rideService = RideService();
  
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Conectar WebSocket
    await SocketService.connect();
    
    // 2. Escuchar eventos
    SocketService.onRideAccepted((data) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Viaje aceptado!')),
      );
    });
  }

  Future<void> _login() async {
    final result = await authService.login(
      email: 'juan@test.com',
      password: 'password123',
    );
    
    if (result['success']) {
      final user = result['user'];
      print('Bienvenido ${user.name}');
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(result['message']),
        ),
      );
    }
  }

  Future<void> _requestRide() async {
    final result = await rideService.requestRide(
      pickupAddress: 'Mi ubicación',
      pickupLat: 19.4326,
      pickupLng: -99.1332,
      dropoffAddress: 'Mi destino',
      dropoffLat: 19.4400,
      dropoffLng: -99.1900,
      distance: 4.2,
    );

    if (result['success']) {
      final ride = result['ride'];
      
      // Emitir evento por WebSocket
      SocketService.requestRide(
        rideId: ride.id,
        passengerId: ride.passengerId,
        pickup: {'lat': 19.4326, 'lng': -99.1332},
        dropoff: {'lat': 19.4400, 'lng': -99.1900},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buscando conductor...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Angeles - Pasajero')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _login,
              child: Text('Iniciar Sesión'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestRide,
              child: Text('Solicitar Viaje'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }
}
```

---

## 📝 Notas Importantes

### 1. Manejo de Errores
Todos los servicios retornan un `Map<String, dynamic>` con:
- `'success'`: `true` o `false`
- `'message'`: mensaje de error (si `success` es `false`)
- Datos adicionales según el método

Siempre verifica `result['success']` antes de usar los datos.

### 2. Tokens de Autenticación
- El token se guarda automáticamente en SharedPreferences
- Se incluye automáticamente en las peticiones
- Persiste entre sesiones de la app

### 3. WebSocket
- Conecta una vez al iniciar la app
- Mantiene conexión activa
- Recuerda desconectar en `dispose()`

### 4. Ubicación en Tiempo Real
Para conductores, actualiza la ubicación cada 5-10 segundos:
```dart
Timer.periodic(Duration(seconds: 5), (timer) async {
  Position position = await Geolocator.getCurrentPosition();
  await driverService.updateLocation(
    LatLng(position.latitude, position.longitude),
  );
});
```

---

## ✅ Próximos Pasos

1. **Implementar pantallas de Login/Registro**
   - Usar `AuthService.login()` y `AuthService.register()`
   
2. **Integrar en PassengerHomeScreen**
   - Usar `RideService.requestRide()`
   - Conectar WebSocket para tracking

3. **Integrar en DriverHomeScreen**
   - Usar `DriverService.goOnline()`
   - Escuchar solicitudes con `SocketService.onNewRideRequest()`

4. **Actualizar RideHistoryScreen**
   - Usar `RideService.getMyRides()`

5. **Agregar sistema de calificaciones**
   - Usar `RideService.rateRide()`

---

**¡La integración del API está completa y lista para usar!** 🚀
