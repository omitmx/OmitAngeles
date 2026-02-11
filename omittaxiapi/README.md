# 🏍️ Angeles Mototaxi API

API REST backend para la aplicación Angeles - Mototaxi Express.

## 🚀 Características

- ✅ Autenticación JWT (Login/Registro)
- ✅ Gestión de usuarios (Pasajeros y Conductores)
- ✅ Solicitud y gestión de viajes
- ✅ Tracking en tiempo real con WebSocket
- ✅ Sistema de calificaciones
- ✅ Búsqueda de conductores cercanos
- ✅ Cálculo automático de tarifas
- ✅ Historial de viajes

## 📋 Requisitos

- Node.js v14 o superior
- MongoDB v4.4 o superior
- npm o yarn

## 🔧 Instalación

### 1. Instalar dependencias

```bash
cd c:\MX\OmitTaxi\omittaxiapi
npm install
```

### 2. Instalar MongoDB

**Opción A: MongoDB local**
- Descarga MongoDB desde: https://www.mongodb.com/try/download/community
- Instala y ejecuta MongoDB en tu máquina

**Opción B: MongoDB Atlas (Cloud - Gratis)**
- Crea una cuenta en: https://www.mongodb.com/cloud/atlas
- Crea un cluster gratuito
- Obtén la URI de conexión

### 3. Configurar variables de entorno

Copia el archivo de ejemplo:
```bash
copy .env.example .env
```

Edita `.env` y configura:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/angeles_mototaxi
JWT_SECRET=cambia_esto_por_una_clave_segura
GOOGLE_MAPS_API_KEY=tu_api_key_aqui
BASE_FARE=20
FARE_PER_KM=8
```

### 4. Iniciar el servidor

**Modo desarrollo (con auto-reload):**
```bash
npm run dev
```

**Modo producción:**
```bash
npm start
```

El servidor estará disponible en: `http://localhost:3000`

## 📡 Endpoints del API

### Autenticación

#### Registro
```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "Juan Pérez",
  "email": "juan@email.com",
  "phone": "+525512345678",
  "password": "password123",
  "userType": "passenger"
}
```

Para conductores:
```json
{
  "name": "Carlos Conductor",
  "email": "carlos@email.com",
  "phone": "+525587654321",
  "password": "password123",
  "userType": "driver",
  "licenseNumber": "ABC123456",
  "vehicleInfo": {
    "brand": "Honda",
    "model": "Wave",
    "year": 2022,
    "plate": "ABC-123",
    "color": "Rojo"
  }
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "juan@email.com",
  "password": "password123"
}
```

### Usuarios

#### Obtener perfil
```http
GET /api/users/profile
Authorization: Bearer {token}
```

#### Actualizar perfil
```http
PUT /api/users/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Juan Pérez Actualizado",
  "phone": "+525512345678"
}
```

### Conductores

#### Conectarse en línea
```http
PUT /api/drivers/online
Authorization: Bearer {token}
Content-Type: application/json

{
  "latitude": 19.4326,
  "longitude": -99.1332
}
```

#### Desconectarse
```http
PUT /api/drivers/offline
Authorization: Bearer {token}
```

#### Buscar conductores cercanos
```http
GET /api/drivers/nearby?latitude=19.4326&longitude=-99.1332&radius=5000
Authorization: Bearer {token}
```

### Viajes

#### Solicitar viaje (Pasajero)
```http
POST /api/rides/request
Authorization: Bearer {token}
Content-Type: application/json

{
  "pickupAddress": "Calle Principal 123",
  "pickupLat": 19.4326,
  "pickupLng": -99.1332,
  "dropoffAddress": "Avenida Central 456",
  "dropoffLat": 19.4420,
  "dropoffLng": -99.1450,
  "distance": 5.2,
  "estimatedDuration": 15,
  "paymentMethod": "cash"
}
```

#### Aceptar viaje (Conductor)
```http
PUT /api/rides/{rideId}/accept
Authorization: Bearer {token}
```

#### Iniciar viaje (Conductor)
```http
PUT /api/rides/{rideId}/start
Authorization: Bearer {token}
```

#### Completar viaje (Conductor)
```http
PUT /api/rides/{rideId}/complete
Authorization: Bearer {token}
```

#### Cancelar viaje
```http
PUT /api/rides/{rideId}/cancel
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Motivo de cancelación"
}
```

#### Calificar viaje
```http
PUT /api/rides/{rideId}/rate
Authorization: Bearer {token}
Content-Type: application/json

{
  "rating": 5,
  "comment": "Excelente servicio!"
}
```

#### Obtener mis viajes
```http
GET /api/rides/my-rides?status=completed&limit=10&page=1
Authorization: Bearer {token}
```

#### Viajes disponibles (Conductor)
```http
GET /api/rides/available/list?latitude=19.4326&longitude=-99.1332
Authorization: Bearer {token}
```

## 🔌 WebSocket Events

### Conexión
```javascript
const socket = io('http://localhost:3000');
```

### Events del Conductor

**Conectarse en línea:**
```javascript
socket.emit('driver:online', {
  driverId: '507f1f77bcf86cd799439011',
  location: { lat: 19.4326, lng: -99.1332 }
});
```

**Actualizar ubicación:**
```javascript
socket.emit('driver:location', {
  driverId: '507f1f77bcf86cd799439011',
  location: { lat: 19.4326, lng: -99.1332 }
});
```

**Desconectarse:**
```javascript
socket.emit('driver:offline', {
  driverId: '507f1f77bcf86cd799439011'
});
```

### Events del Pasajero

**Solicitar viaje:**
```javascript
socket.emit('ride:request', {
  rideId: '507f1f77bcf86cd799439012',
  passengerId: '507f1f77bcf86cd799439013',
  pickup: { lat: 19.4326, lng: -99.1332 },
  dropoff: { lat: 19.4420, lng: -99.1450 }
});
```

### Events recibidos

**Nueva solicitud de viaje (Conductor):**
```javascript
socket.on('ride:new-request', (data) => {
  console.log('Nuevo viaje:', data);
});
```

**Viaje aceptado (Pasajero):**
```javascript
socket.on('ride:accepted', (data) => {
  console.log('Tu viaje fue aceptado:', data);
});
```

**Ubicación del conductor (Pasajero):**
```javascript
socket.on('ride:driver-location', (data) => {
  console.log('Ubicación del conductor:', data.location);
});
```

## 🗄️ Estructura de la Base de Datos

### Colección: users
```javascript
{
  _id: ObjectId,
  name: String,
  email: String (unique),
  phone: String (unique),
  password: String (hashed),
  userType: "passenger" | "driver",
  rating: Number,
  totalRides: Number,
  vehicleInfo: {
    brand: String,
    model: String,
    year: Number,
    plate: String,
    color: String
  },
  licenseNumber: String,
  isOnline: Boolean,
  currentLocation: {
    type: "Point",
    coordinates: [longitude, latitude]
  },
  createdAt: Date,
  updatedAt: Date
}
```

### Colección: rides
```javascript
{
  _id: ObjectId,
  passenger: ObjectId (ref: User),
  driver: ObjectId (ref: User),
  pickupLocation: {
    address: String,
    coordinates: { type: "Point", coordinates: [lng, lat] }
  },
  dropoffLocation: {
    address: String,
    coordinates: { type: "Point", coordinates: [lng, lat] }
  },
  distance: Number,
  fare: {
    baseFare: Number,
    distanceFare: Number,
    total: Number
  },
  status: "requested" | "accepted" | "in_progress" | "completed" | "cancelled",
  passengerRating: Number,
  driverRating: Number,
  requestedAt: Date,
  completedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

## 🧪 Probar el API

Usa Postman, Insomnia o cualquier cliente HTTP. También puedes usar curl:

```bash
# Registrar usuario
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"test@test.com\",\"phone\":\"+525512345678\",\"password\":\"test123\",\"userType\":\"passenger\"}"

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@test.com\",\"password\":\"test123\"}"
```

## 📱 Conectar con la App Flutter

En tu app Flutter, configura la URL del API:

```dart
const String API_BASE_URL = 'http://TU_IP_LOCAL:3000/api';
const String SOCKET_URL = 'http://TU_IP_LOCAL:3000';
```

**Nota:** Usa tu dirección IP local (ej: `192.168.1.100`) en vez de `localhost` cuando pruebes en dispositivos físicos.

## 🛡️ Seguridad

- Las contraseñas se encriptan con bcrypt
- Autenticación con JWT tokens
- Validación de datos en todas las rutas
- CORS habilitado para desarrollo

**⚠️ IMPORTANTE:** Cambia `JWT_SECRET` en producción por una clave segura.

## 📝 Licencia

ISC

## 🤝 Soporte

Para problemas o preguntas, contacta al equipo de desarrollo.
