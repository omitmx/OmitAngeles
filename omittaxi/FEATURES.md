# 🎯 Características Implementadas - OmitTaxi

## 📱 Arquitectura de la Aplicación

### Patrón de Arquitectura: MVC con Provider

```
┌─────────────────────────────────────────────┐
│              VISTA (UI)                      │
│  - Screens (Flutter Widgets)                │
│  - Componentes reutilizables                │
└─────────────┬───────────────────────────────┘
              │
              │ Notifica cambios
              ▼
┌─────────────────────────────────────────────┐
│         CONTROLADOR (Provider)               │
│  - UserProvider                              │
│  - RideProvider                              │
└─────────────┬───────────────────────────────┘
              │
              │ Manipula
              ▼
┌─────────────────────────────────────────────┐
│          MODELO (Data)                       │
│  - UserModel                                 │
│  - RideModel                                 │
└─────────────────────────────────────────────┘
```

## 🏗️ Estructura de Archivos

```
omittaxi/
│
├── lib/
│   ├── main.dart                      # Punto de entrada
│   │
│   ├── models/                        # Modelos de datos
│   │   ├── user_model.dart            # Usuario (Pasajero/Conductor)
│   │   └── ride_model.dart            # Viaje con ubicaciones
│   │
│   ├── providers/                     # Gestión de estado
│   │   ├── user_provider.dart         # Estado de autenticación
│   │   └── ride_provider.dart         # Estado de viajes
│   │
│   └── screens/                       # Pantallas UI
│       ├── splash_screen.dart         # Pantalla inicial
│       ├── welcome_screen.dart        # Selección de rol
│       ├── profile_screen.dart        # Perfil de usuario
│       ├── ride_history_screen.dart   # Historial
│       │
│       ├── passenger/                 # Módulo de pasajero
│       │   ├── passenger_home_screen.dart
│       │   └── request_ride_screen.dart
│       │
│       └── driver/                    # Módulo de conductor
│           └── driver_home_screen.dart
│
├── android/                           # Configuración Android
├── ios/                               # Configuración iOS
├── pubspec.yaml                       # Dependencias
├── README.md                          # Documentación principal
├── QUICKSTART.md                      # Guía rápida
├── SETUP_MAPS.md                      # Configuración de Maps
└── TODO.md                            # Lista de tareas
```

## 🔄 Flujo de la Aplicación

### Flujo de Pasajero

```
[Splash Screen]
      ↓
[Welcome Screen] → Seleccionar "Soy Pasajero"
      ↓
[Passenger Home] → Mapa con ubicación actual
      ↓
[Request Ride] → Seleccionar origen y destino
      ↓
[Buscar Conductor] → Simulación de búsqueda
      ↓
[Viaje Aceptado] → Mostrar conductor asignado
      ↓
[Viaje Completado] → Opción de calificar
      ↓
[History] → Ver historial de viajes
```

### Flujo de Conductor

```
[Splash Screen]
      ↓
[Welcome Screen] → Seleccionar "Soy Conductor"
      ↓
[Driver Home] → Dashboard con estadísticas
      ↓
[Conectar] → Estado en línea
      ↓
[Recibir Solicitud] → Notificación de viaje
      ↓
[Aceptar/Rechazar] → Decisión del conductor
      ↓
[Viaje en Progreso] → Navegación al destino
      ↓
[Completar Viaje] → Confirmar finalización
      ↓
[Actualizar Stats] → Ver ganancias y viajes
```

## 📊 Modelos de Datos

### UserModel
```dart
{
  id: String,              // Identificador único
  name: String,            // Nombre del usuario
  email: String,           // Correo electrónico
  phone: String,           // Teléfono
  userType: String,        // 'passenger' o 'driver'
  photoUrl: String?,       // URL de foto de perfil
  rating: double,          // Calificación promedio (0-5)
  totalRides: int          // Total de viajes realizados
}
```

### RideModel
```dart
{
  id: String,                     // ID único del viaje
  passengerId: String,            // ID del pasajero
  driverId: String?,              // ID del conductor (opcional)
  pickupLocation: LatLng,         // Coordenadas de origen
  dropoffLocation: LatLng,        // Coordenadas de destino
  pickupAddress: String,          // Dirección de origen
  dropoffAddress: String,         // Dirección de destino
  requestTime: DateTime,          // Hora de solicitud
  pickupTime: DateTime?,          // Hora de recogida
  dropoffTime: DateTime?,         // Hora de llegada
  status: String,                 // Estado del viaje
  fare: double,                   // Tarifa calculada
  distance: double,               // Distancia en km
  rating: int?,                   // Calificación (1-5)
  review: String?                 // Comentario
}
```

## 💰 Sistema de Tarifas

```
Tarifa = Base + (Distancia × Tarifa por KM)

Base: $20.00 MXN
Tarifa por KM: $8.00 MXN

Ejemplos:
- 1 km  = $20 + ($8 × 1)  = $28.00
- 3 km  = $20 + ($8 × 3)  = $44.00
- 5 km  = $20 + ($8 × 5)  = $60.00
- 10 km = $20 + ($8 × 10) = $100.00
```

## 🎨 Sistema de Diseño

### Paleta de Colores

```
┌────────────────────────────────┐
│  PRIMARY: #2E7D32 (Verde)      │  → Botones principales, AppBar
│  SECONDARY: #FFB300 (Amarillo) │  → Acentos, highlights
│  ACCENT: #1B5E20 (Verde oscuro)│  → Gradientes, sombras
│  ERROR: #D32F2F (Rojo)         │  → Errores, cancelaciones
│  SUCCESS: #388E3C (Verde)      │  → Completados, confirmaciones
└────────────────────────────────┘
```

### Tipografía

- **Títulos grandes**: 32px, Bold
- **Títulos**: 24px, Bold
- **Subtítulos**: 18px, Medium
- **Cuerpo**: 16px, Regular
- **Caption**: 12px, Regular

### Espaciado

- **Pequeño**: 8px
- **Mediano**: 16px
- **Grande**: 24px
- **Extra grande**: 32px

## 🔔 Estados de Viaje

```
PENDING     → Esperando conductor
ACCEPTED    → Conductor asignado
IN_PROGRESS → Viaje en curso
COMPLETED   → Viaje finalizado
CANCELLED   → Viaje cancelado
```

## 📍 Permisos Necesarios

### Android
- `ACCESS_FINE_LOCATION` - Ubicación precisa
- `ACCESS_COARSE_LOCATION` - Ubicación aproximada
- `INTERNET` - Conexión a internet

### iOS
- `NSLocationWhenInUseUsageDescription` - Ubicación en uso
- `NSLocationAlwaysUsageDescription` - Ubicación siempre
- `NSLocationAlwaysAndWhenInUseUsageDescription` - Ambos modos

## 🔌 APIs y Servicios

### Integrados
- ✅ Google Maps Flutter - Mapas interactivos
- ✅ Geolocator - Servicios de ubicación
- ✅ Provider - Gestión de estado
- ✅ Flutter Rating Bar - Calificaciones
- ✅ Intl - Formato de fechas y números
- ✅ UUID - Generación de IDs

### Por Implementar
- ⏳ Firebase Auth - Autenticación
- ⏳ Cloud Firestore - Base de datos
- ⏳ Firebase Cloud Messaging - Notificaciones push
- ⏳ Google Places API - Búsqueda de lugares
- ⏳ Stripe/PayPal - Pagos

## 📈 Métricas y Analytics

### Para Pasajeros
- Total de viajes realizados
- Dinero gastado total
- Calificación promedio dada
- Lugares frecuentes

### Para Conductores
- Viajes completados (día/semana/mes)
- Ganancias (día/semana/mes)
- Calificación promedio recibida
- Horas en línea
- Tasa de aceptación

## 🔒 Seguridad

### Implementado
- Validación de tipos de usuario
- Estados de sesión
- Navegación protegida

### Por Implementar
- Encriptación de datos sensibles
- Autenticación de dos factores
- Verificación de identidad
- Reporte de problemas
- Botón de emergencia

## 🌐 Internacionalización

### Idiomas Soportados (Futuro)
- 🇲🇽 Español (México) - Por defecto
- 🇺🇸 Inglés
- 🇫🇷 Francés
- 🇩🇪 Alemán
- 🇵🇹 Portugués

## 📱 Compatibilidad

### Versiones Mínimas
- Android: 6.0 (API 23)
- iOS: 12.0
- Flutter: 3.10.0
- Dart: 3.0.0

### Dispositivos Probados
- [ ] Android Physical Device
- [ ] Android Emulator
- [ ] iOS Physical Device
- [ ] iOS Simulator
- [ ] Tablet Android
- [ ] iPad

---

**Última actualización:** Enero 30, 2026
**Versión:** 1.0.0
