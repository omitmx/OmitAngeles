# 🏍️ Angeles - App de Mototaxi Estilo Uber

Aplicación móvil completa de servicio de mototaxi con funcionalidades tipo Uber, incluyendo tracking en tiempo real, calificaciones, y gestión de viajes para pasajeros y conductores.

## 🎨 Características

- ✅ **Dual Mode**: Modo Pasajero y Modo Conductor
- ✅ **Autenticación**: Sistema completo de login/registro con JWT
- ✅ **Mapas en Tiempo Real**: Integración con Google Maps
- ✅ **Tracking en Vivo**: WebSocket para seguimiento de conductores
- ✅ **Sistema de Calificaciones**: Pasajeros y conductores pueden calificarse
- ✅ **Historial de Viajes**: Registro completo de todos los viajes
- ✅ **Cálculo de Tarifas**: Sistema automático de cálculo de precios
- ✅ **Diseño Moderno**: Material Design 3 con colores personalizados

## 🎨 Paleta de Colores

- **Azul Rey**: `#0047AB` - Color principal
- **Azul Cielo**: `#87CEEB` - Color secundario
- **Blanco**: Para fondos y textos

## 📁 Estructura del Proyecto

```
OmitTaxi/
├── omittaxi/              # App Flutter
│   ├── lib/
│   │   ├── config/        # Configuración (API, colores)
│   │   ├── models/        # Modelos de datos
│   │   ├── providers/     # State management (Provider)
│   │   ├── screens/       # Pantallas de la app
│   │   ├── services/      # Servicios (Auth, Ride, Driver, Socket)
│   │   └── widgets/       # Componentes reutilizables
│   └── pubspec.yaml
│
├── omittaxiapi/           # Backend API (Node.js + Express)
│   ├── models/            # Modelos de MongoDB
│   ├── routes/            # Rutas del API
│   ├── middleware/        # Middleware de autenticación
│   ├── server.js          # Servidor principal
│   ├── seed.js            # Datos de prueba
│   └── package.json
│
└── README.md              # Este archivo
```

## 🚀 Tecnologías Utilizadas

### Frontend (Flutter)
- **Flutter**: 3.38.4
- **Dart**: Latest
- **Provider**: 6.1.5+1 (State Management)
- **Google Maps Flutter**: 2.14.0
- **Geolocator**: 14.0.2
- **HTTP**: 1.1.0
- **Socket.IO Client**: 2.0.3+1
- **Shared Preferences**: 2.2.2

### Backend (Node.js)
- **Express**: 4.21.2
- **MongoDB**: 8.2.5 + Mongoose 8.9.3
- **Socket.IO**: 4.8.1 (WebSocket)
- **JWT**: jsonwebtoken 9.0.2
- **Bcrypt**: 5.1.1
- **CORS**: 2.8.5
- **Dotenv**: 16.4.7

## 📋 Requisitos Previos

- **Flutter SDK**: 3.38.4 o superior
- **Node.js**: v16 o superior
- **MongoDB**: 8.0 o superior
- **Android Studio** / **Xcode** (para desarrollo móvil)
- **Google Maps API Key**

## 🔧 Instalación

### 1. Clonar el Repositorio

```bash
git clone <tu-repo-url>
cd OmitTaxi
```

### 2. Configurar Backend

```bash
cd omittaxiapi
npm install
```

Crear archivo `.env`:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/angeles_mototaxi
JWT_SECRET=tu_clave_secreta_aqui
GOOGLE_MAPS_API_KEY=tu_api_key_aqui
BASE_FARE=20
FARE_PER_KM=8
```

Iniciar MongoDB:
```bash
net start MongoDB  # Windows
# o
mongod  # Linux/Mac
```

Poblar base de datos con datos de prueba:
```bash
node seed.js
```

Iniciar servidor:
```bash
npm start
```

El servidor estará disponible en:
- Local: `http://localhost:3000`
- Red: `http://10.1.7.106:3000`

### 3. Configurar Flutter App

```bash
cd omittaxi
flutter pub get
```

Configurar Google Maps API Key:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
GMSServices.provideAPIKey("TU_API_KEY_AQUI")
```

Actualizar IP del servidor en `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://TU_IP:3000/api';
static const String socketUrl = 'http://TU_IP:3000';
```

### 4. Ejecutar la App

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device-id>

# Ejemplo:
flutter run -d JND0219A25000465  # Dispositivo físico
flutter run -d emulator-5554     # Emulador
```

## 👥 Usuarios de Prueba

Después de ejecutar `node seed.js`, tendrás estos usuarios:

### Pasajeros
| Email | Password | Nombre |
|-------|----------|--------|
| ana@test.com | password123 | Ana García |
| luis@test.com | password123 | Luis Martínez |
| maria@test.com | password123 | María Rodríguez |

### Conductores
| Email | Password | Nombre | Vehículo |
|-------|----------|--------|----------|
| carlos@test.com | password123 | Carlos Conductor | Honda Wave 2022 |
| roberto@test.com | password123 | Roberto Ramírez | Yamaha FZ 2021 |
| miguel@test.com | password123 | Miguel Torres | Suzuki Gixxer 2023 |

## 🔌 API Endpoints

### Autenticación
- `POST /api/auth/register` - Registro de usuarios
- `POST /api/auth/login` - Inicio de sesión

### Usuarios
- `GET /api/users/profile` - Obtener perfil
- `PUT /api/users/profile` - Actualizar perfil

### Viajes
- `POST /api/rides` - Solicitar viaje
- `GET /api/rides` - Obtener viajes (disponibles o propios)
- `PUT /api/rides/:id/accept` - Aceptar viaje (conductor)
- `PUT /api/rides/:id/start` - Iniciar viaje
- `PUT /api/rides/:id/complete` - Completar viaje
- `PUT /api/rides/:id/cancel` - Cancelar viaje
- `POST /api/rides/:id/rate` - Calificar viaje

### Conductores
- `POST /api/drivers/online` - Ponerse en línea
- `POST /api/drivers/offline` - Ponerse fuera de línea
- `PUT /api/drivers/location` - Actualizar ubicación
- `GET /api/drivers/nearby` - Obtener conductores cercanos

### WebSocket Events
- `driver:online` - Conductor en línea
- `driver:offline` - Conductor fuera de línea
- `driver:location` - Actualización de ubicación
- `ride:request` - Nueva solicitud de viaje
- `ride:accepted` - Viaje aceptado
- `ride:started` - Viaje iniciado
- `ride:completed` - Viaje completado

## 🎯 Funcionalidades Principales

### Para Pasajeros
1. Registrarse/Iniciar sesión
2. Ver mapa con ubicación actual
3. Solicitar viaje (origen → destino)
4. Ver conductores cercanos en tiempo real
5. Seguir el viaje en progreso
6. Calificar al conductor
7. Ver historial de viajes

### Para Conductores
1. Registrarse/Iniciar sesión con datos del vehículo
2. Activar/Desactivar disponibilidad
3. Recibir solicitudes de viajes
4. Aceptar/Rechazar viajes
5. Navegar hasta el pasajero
6. Iniciar y completar viajes
7. Calificar a pasajeros
8. Ver historial y ganancias

## 🐛 Solución de Problemas

### La app no conecta con el API
1. Verifica que MongoDB esté corriendo: `net start MongoDB`
2. Verifica que el servidor API esté corriendo
3. Asegúrate de que la IP en `api_config.dart` sea correcta
4. Verifica el firewall: `netsh advfirewall firewall add rule name="Angeles API" dir=in action=allow protocol=TCP localport=3000`
5. Prueba desde el navegador del celular: `http://TU_IP:3000`

### Errores de compilación en Flutter
```bash
flutter clean
flutter pub get
flutter run
```

### MongoDB no inicia
```bash
# Windows
net start MongoDB

# Linux/Mac
sudo systemctl start mongod
```

## 📱 Capturas de Pantalla

*(Pendiente: Agregar capturas de pantalla)*

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 👨‍💻 Autor

Desarrollado con ❤️ para Angeles Mototaxi

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Para soporte, revisa la documentación en:
- `GUIA_USO_API.md` - Guía completa del API
- `IMPLEMENTACION_API_COMPLETADA.md` - Detalles de implementación
- `SOLUCION_CONEXION.md` - Solución de problemas de conexión

---

**¡Gracias por usar Angeles! 🏍️💨**
