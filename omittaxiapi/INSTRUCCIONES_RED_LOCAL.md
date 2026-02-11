# 🌐 Configuración para Red Local

## Tu IP Local: **10.1.7.106**

## ✅ Configuración Aplicada

### 1. App Flutter
- ✅ Archivo creado: `lib/config/api_config.dart`
- ✅ URL del API: `http://10.1.7.106:3000/api`
- ✅ WebSocket URL: `http://10.1.7.106:3000`

### 2. Servidor API
- ✅ CORS habilitado para todas las conexiones
- ✅ WebSocket configurado para aceptar conexiones externas
- ✅ Puerto: 3000

## 🚀 Pasos para Iniciar

### Paso 1: Iniciar MongoDB

```powershell
# Verificar que MongoDB esté corriendo
net start MongoDB
```

Si no tienes MongoDB instalado:
1. Descarga: https://www.mongodb.com/try/download/community
2. Instala con configuración predeterminada
3. Se iniciará automáticamente como servicio

### Paso 2: Iniciar el Servidor API

```powershell
cd c:\MX\OmitTaxi\omittaxiapi
npm start
```

Deberías ver:
```
✅ Conectado a MongoDB
🚀 Servidor corriendo en puerto 3000
📡 WebSocket habilitado para tracking en tiempo real
🌐 URL: http://localhost:3000
```

**IMPORTANTE:** El servidor debe estar corriendo en tu PC con IP **10.1.7.106**

### Paso 3: Verificar Firewall de Windows

El firewall puede bloquear las conexiones. Permite el puerto 3000:

```powershell
# Ejecutar como Administrador en PowerShell:
New-NetFirewallRule -DisplayName "Angeles API" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

O manualmente:
1. Panel de Control → Sistema y Seguridad → Firewall de Windows
2. Configuración avanzada → Reglas de entrada
3. Nueva regla → Puerto → TCP → Puerto 3000 → Permitir conexión

### Paso 4: Probar Conexión desde el Celular

**Opción A: Desde el navegador del celular**
1. Abre el navegador en tu celular
2. Ve a: `http://10.1.7.106:3000`
3. Deberías ver:
   ```json
   {
     "message": "🏍️ Angeles Mototaxi API",
     "version": "1.0.0",
     "status": "running"
   }
   ```

**Opción B: Hacer ping desde tu celular**
- Instala una app de "Network Tools" o "Ping"
- Haz ping a: `10.1.7.106`
- Debe responder

### Paso 5: Ejecutar la App Flutter

```powershell
cd c:\MX\OmitTaxi\omittaxi
flutter run -d JND0219A25000465
```

## ⚠️ Requisitos Importantes

### ✅ Checklist antes de correr la app:

- [ ] PC y celular conectados a la **misma red WiFi**
- [ ] MongoDB corriendo en tu PC
- [ ] Servidor API corriendo (`npm start`)
- [ ] Firewall permite puerto 3000
- [ ] IP 10.1.7.106 es la correcta (verifica con `ipconfig`)

### Verificar tu IP actual:

```powershell
ipconfig
```

Busca la sección de tu adaptador WiFi y verifica que diga:
```
Dirección IPv4: 10.1.7.106
```

Si cambió, actualiza `lib/config/api_config.dart` con la nueva IP.

## 🧪 Probar el API

### 1. Registrar Usuario de Prueba

Desde tu celular o PC, usa Postman/Insomnia o curl:

```bash
curl -X POST http://10.1.7.106:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"test@test.com\",\"phone\":\"+525512345678\",\"password\":\"test123\",\"userType\":\"passenger\"}"
```

### 2. Hacer Login

```bash
curl -X POST http://10.1.7.106:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@test.com\",\"password\":\"test123\"}"
```

Copia el `token` que te devuelve.

### 3. Obtener Perfil

```bash
curl -X GET http://10.1.7.106:3000/api/users/profile \
  -H "Authorization: Bearer TU_TOKEN_AQUI"
```

## 🔧 Solución de Problemas

### Error: "Failed to connect"

**Causa 1: Firewall bloqueando**
- Solución: Permite el puerto 3000 (ver Paso 3)

**Causa 2: Diferentes redes WiFi**
- Solución: Conecta PC y celular a la misma red

**Causa 3: IP cambió**
- Solución: Verifica con `ipconfig` y actualiza la IP

### Error: "Cannot connect to MongoDB"

```powershell
# Iniciar MongoDB
net start MongoDB

# Si no funciona, reinstalar MongoDB
```

### Error: "Port 3000 already in use"

```powershell
# Ver qué proceso usa el puerto 3000
netstat -ano | findstr :3000

# Matar el proceso (reemplaza PID con el número que aparece)
taskkill /PID [PID] /F
```

### Servidor API no responde

```powershell
# Detener servidor (Ctrl+C en la terminal)
# Reiniciar
cd c:\MX\OmitTaxi\omittaxiapi
npm start
```

## 📱 Usar la App

Una vez todo configurado:

1. **Iniciar MongoDB** en tu PC
2. **Iniciar API** en tu PC: `npm start`
3. **Ejecutar app** en tu celular: `flutter run -d JND0219A25000465`

La app se conectará automáticamente a `http://10.1.7.106:3000/api`

## 🎯 URLs Configuradas

| Servicio | URL |
|----------|-----|
| API REST | `http://10.1.7.106:3000/api` |
| WebSocket | `http://10.1.7.106:3000` |
| Health Check | `http://10.1.7.106:3000` |
| Login | `http://10.1.7.106:3000/api/auth/login` |
| Register | `http://10.1.7.106:3000/api/auth/register` |

## ✨ Todo Listo!

Ahora tu app Flutter en el celular se conectará al servidor API en tu PC usando la red local.

**Siguiente paso:** Iniciar MongoDB + API Server + Flutter App 🚀
