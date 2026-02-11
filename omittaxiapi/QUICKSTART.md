# 🚀 Guía Rápida - Iniciar API Angeles

## Paso 1: Instalar MongoDB

### Opción A - MongoDB Local (Windows)

1. **Descargar MongoDB:**
   - Ve a: https://www.mongodb.com/try/download/community
   - Descarga "MongoDB Community Server" para Windows
   - Instala con configuración predeterminada

2. **Verificar instalación:**
   ```powershell
   mongod --version
   ```

3. **Iniciar MongoDB:**
   ```powershell
   # MongoDB se inicia automáticamente como servicio
   # Para verificar que está corriendo:
   net start MongoDB
   ```

### Opción B - MongoDB Atlas (Cloud - Gratis)

1. Crea cuenta en: https://www.mongodb.com/cloud/atlas
2. Crea un cluster gratuito (Free Tier)
3. Copia la URI de conexión
4. Edita `.env` y cambia `MONGODB_URI` a tu URI de Atlas

## Paso 2: Configurar el API

1. **Instalar dependencias** (ya hecho):
   ```powershell
   cd c:\MX\OmitTaxi\omittaxiapi
   npm install
   ```

2. **Verificar archivo .env:**
   - Archivo `.env` ya está creado
   - Verifica que `MONGODB_URI` apunte a tu MongoDB

## Paso 3: Poblar Base de Datos (Opcional)

Crea usuarios y viajes de prueba:

```powershell
cd c:\MX\OmitTaxi\omittaxiapi
node seed.js
```

Esto creará:
- 3 pasajeros de prueba
- 3 conductores de prueba  
- 3 viajes de ejemplo

**Credenciales de prueba:**
- Pasajero: `ana@test.com` / `password123`
- Conductor: `carlos@test.com` / `password123`

## Paso 4: Iniciar el Servidor

```powershell
cd c:\MX\OmitTaxi\omittaxiapi
npm run dev
```

Verás:
```
✅ Conectado a MongoDB
🚀 Servidor corriendo en puerto 3000
📡 WebSocket habilitado para tracking en tiempo real
🌐 URL: http://localhost:3000
```

## Paso 5: Probar el API

Abre tu navegador en: **http://localhost:3000**

Deberías ver:
```json
{
  "message": "🏍️ Angeles Mototaxi API",
  "version": "1.0.0",
  "status": "running"
}
```

## 🧪 Probar con Postman/Insomnia

### 1. Registrar usuario
```
POST http://localhost:3000/api/auth/register

Body (JSON):
{
  "name": "Test User",
  "email": "test@test.com",
  "phone": "+525512345678",
  "password": "test123",
  "userType": "passenger"
}
```

### 2. Login
```
POST http://localhost:3000/api/auth/login

Body (JSON):
{
  "email": "test@test.com",
  "password": "test123"
}
```

Copia el `token` de la respuesta.

### 3. Obtener perfil
```
GET http://localhost:3000/api/users/profile

Headers:
Authorization: Bearer TU_TOKEN_AQUI
```

## 📱 Conectar Flutter App

En tu app Flutter, crea un archivo `lib/services/api_service.dart`:

```dart
class ApiService {
  // Cambia por tu IP local si usas dispositivo físico
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';
  
  // Si usas dispositivo físico, usa tu IP:
  // static const String baseUrl = 'http://192.168.1.XXX:3000/api';
}
```

## 🔍 Comandos Útiles

**Ver logs en tiempo real:**
```powershell
npm run dev
```

**Ver base de datos (requiere MongoDB Compass):**
- Descargar: https://www.mongodb.com/try/download/compass
- Conectar a: `mongodb://localhost:27017`
- Base de datos: `angeles_mototaxi`

**Limpiar y repoblar base de datos:**
```powershell
node seed.js
```

## ⚠️ Solución de Problemas

### Error: "Cannot connect to MongoDB"
- Verifica que MongoDB esté corriendo:
  ```powershell
  net start MongoDB
  ```
- O cambia a MongoDB Atlas (cloud)

### Error: "Port 3000 already in use"
- Cambia el puerto en `.env`:
  ```
  PORT=3001
  ```

### App Flutter no conecta al API
- Si usas dispositivo físico, usa tu IP local en vez de `localhost`
- Verifica que estén en la misma red WiFi
- Ejemplo: `http://192.168.1.100:3000/api`

## ✅ Todo Listo!

Ahora tienes:
- ✅ API REST corriendo en `http://localhost:3000`
- ✅ WebSocket para tracking en tiempo real
- ✅ Base de datos MongoDB con usuarios de prueba
- ✅ Endpoints listos para la app Flutter

**Siguiente paso:** Conectar la app Flutter al API! 🚀
