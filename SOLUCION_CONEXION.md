# 🔧 Solución de Problemas de Conexión

## ✅ Estado Actual del Sistema

### Servicios Activos:
- ✅ **MongoDB**: Corriendo en puerto 27017
- ✅ **API Server**: Corriendo en puerto 3000
- ✅ **Flutter App**: Corriendo en dispositivo ELE L04
- ✅ **Firewall**: Configurado para puerto 3000

### Configuración de Red:
- **IP del servidor**: 10.1.7.106
- **Puerto API**: 3000
- **URL API**: http://10.1.7.106:3000/api

---

## 🧪 PRUEBAS DE CONEXIÓN

### Paso 1: Verificar desde el navegador del celular

1. Abre el navegador (Chrome/Firefox) en tu celular ELE L04
2. Navega a: **`http://10.1.7.106:3000/api/auth/login`**
3. Deberías ver un mensaje de error JSON (es normal, solo estamos probando la conexión)

**Si NO se carga la página:**
- Tu celular y tu PC no están en la misma red WiFi
- El firewall está bloqueando la conexión
- Verifica que ambos dispositivos estén conectados a la misma red WiFi

**Si SÍ se carga (aunque sea un error):**
- ¡La conexión funciona! El problema está en la app

---

### Paso 2: Verificar que ambos dispositivos están en la misma red

**En la PC:**
```powershell
ipconfig | findstr IPv4
```
Debería mostrar: `10.1.7.106`

**En el celular:**
1. Ve a Configuración → WiFi
2. Toca la red conectada
3. Verifica que la IP empiece con `10.1.7.xxx`

---

### Paso 3: Probar el login desde el navegador del celular

Abre el navegador en tu celular y pega esta URL (cambia los datos si quieres):

```
http://10.1.7.106:3000/api/auth/login
```

Usando una herramienta como Postman o directamente en la consola del navegador:

```javascript
fetch('http://10.1.7.106:3000/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'ana@test.com',
    password: 'password123'
  })
})
.then(r => r.json())
.then(console.log)
```

---

## 🔍 Diagnóstico de Problemas Comunes

### Problema 1: "No se puede conectar al servidor"

**Causa**: El celular no puede alcanzar la IP 10.1.7.106

**Soluciones**:
1. Verifica que ambos estén en la misma red WiFi
2. Desactiva temporalmente el firewall de Windows:
   ```powershell
   netsh advfirewall set allprofiles state off
   ```
   (Reactívalo después con `state on`)

3. Verifica que el servidor esté escuchando:
   ```powershell
   netstat -ano | findstr :3000
   ```

### Problema 2: "Timeout" o se queda cargando

**Causa**: Firewall bloqueando o servidor no escuchando en 0.0.0.0

**Solución**: Ya configuramos esto en `server.js` con `HOST = '0.0.0.0'`

### Problema 3: El login no responde en la app

**Causa**: Error en la implementación del AuthService

**Solución**: Revisa los logs de la app Flutter:
- En VSCode, mira la consola de Debug
- Busca errores de conexión HTTP

---

## 📱 Usuarios de Prueba

Una vez que la conexión funcione:

### PASAJEROS:
```
Email: ana@test.com
Password: password123
```

### CONDUCTORES:
```
Email: carlos@test.com
Password: password123
```

---

## ⚡ Comando Rápido para Reiniciar Todo

```powershell
# 1. Detener servidor (Ctrl+C en la terminal)
# 2. Verificar MongoDB
net start MongoDB

# 3. Iniciar API
cd c:\MX\OmitTaxi\omittaxiapi
node server.js

# 4. En otra terminal - Iniciar app
cd c:\MX\OmitTaxi\omittaxi
flutter run -d JND0219A25000465
```

---

## 🆘 Si Nada Funciona

**Opción alternativa**: Usa el emulador de Android

```powershell
# Iniciar emulador
flutter emulators --launch <ID_EMULADOR>

# Ejecutar app
flutter run -d emulator-5554
```

En el emulador, la IP `10.0.2.2` equivale a `localhost` de tu PC:
- Cambiar en `api_config.dart`: `http://10.0.2.2:3000/api`

---

## 📞 Siguiente Acción

1. **Abre el navegador de tu celular**
2. **Navega a: `http://10.1.7.106:3000`**
3. **Dime qué ves** (error, página en blanco, mensaje de conexión rechazada, etc.)
