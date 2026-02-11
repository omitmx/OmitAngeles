# 🎯 CONFIGURACIÓN COMPLETA - IP LOCAL: 10.1.7.106

## ✅ Archivos Configurados

### 1. Flutter App
- **Archivo:** `c:\MX\OmitTaxi\omittaxi\lib\config\api_config.dart`
- **API URL:** `http://10.1.7.106:3000/api`
- **Socket URL:** `http://10.1.7.106:3000`

### 2. Scripts de PowerShell Creados
- **`setup-firewall.ps1`** - Configura firewall (ejecutar como Admin)
- **`check-setup.ps1`** - Verifica toda la configuración
- **`start.ps1`** - Inicia MongoDB + API Server automáticamente

---

## 🚀 INICIO RÁPIDO (3 Pasos)

### Paso 1: Configurar Firewall (Solo 1 vez)
```powershell
# Click derecho en PowerShell → "Ejecutar como Administrador"
cd c:\MX\OmitTaxi\omittaxiapi
.\setup-firewall.ps1
```

### Paso 2: Iniciar el Servidor
```powershell
cd c:\MX\OmitTaxi\omittaxiapi
.\start.ps1
```
O manualmente:
```powershell
npm start
```

### Paso 3: Ejecutar la App en tu Celular
```powershell
cd c:\MX\OmitTaxi\omittaxi
flutter run -d JND0219A25000465
```

---

## 🔧 CONFIGURACIÓN DETALLADA

### A. Primera Vez - Instalar MongoDB

1. **Descargar MongoDB:**
   - https://www.mongodb.com/try/download/community
   - Selecciona "Windows" y "MSI"
   - Instala con configuración por defecto

2. **Verificar instalación:**
   ```powershell
   mongod --version
   net start MongoDB
   ```

### B. Primera Vez - Configurar Firewall

```powershell
# Como Administrador:
cd c:\MX\OmitTaxi\omittaxiapi
.\setup-firewall.ps1
```

Esto permite conexiones al puerto 3000.

### C. Verificar Configuración

```powershell
cd c:\MX\OmitTaxi\omittaxiapi
.\check-setup.ps1
```

Esto verifica:
- ✅ IP local
- ✅ MongoDB
- ✅ Puerto 3000
- ✅ Firewall
- ✅ Node.js
- ✅ Dependencias npm

---

## 📡 URLs CONFIGURADAS

| Servicio | URL |
|----------|-----|
| **Health Check** | http://10.1.7.106:3000 |
| **API Base** | http://10.1.7.106:3000/api |
| **Login** | http://10.1.7.106:3000/api/auth/login |
| **Register** | http://10.1.7.106:3000/api/auth/register |
| **WebSocket** | http://10.1.7.106:3000 |

---

## 🧪 PROBAR LA CONEXIÓN

### Desde el Navegador del Celular

Abre el navegador en tu celular y ve a:
```
http://10.1.7.106:3000
```

Deberías ver:
```json
{
  "message": "🏍️ Angeles Mototaxi API",
  "version": "1.0.0",
  "status": "running"
}
```

### Desde PowerShell (en tu PC)

```powershell
# Probar health check
curl http://10.1.7.106:3000

# Registrar usuario
curl -X POST http://10.1.7.106:3000/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{"name":"Test","email":"test@test.com","phone":"+525512345678","password":"test123","userType":"passenger"}'
```

---

## 📱 EJECUTAR APP FLUTTER

### Opción 1: Con Flutter CLI
```powershell
cd c:\MX\OmitTaxi\omittaxi
flutter run -d JND0219A25000465
```

### Opción 2: Con VS Code
1. Abre VS Code en `c:\MX\OmitTaxi\omittaxi`
2. Selecciona tu dispositivo "ELE L04" en la barra inferior
3. Presiona F5 o el botón "Run"

---

## ⚠️ CHECKLIST ANTES DE EJECUTAR

Verifica que TODO esté ✅:

- [ ] PC y celular en la misma red WiFi
- [ ] IP local es 10.1.7.106 (verificar con `ipconfig`)
- [ ] MongoDB instalado y corriendo
- [ ] Firewall configurado (puerto 3000 abierto)
- [ ] API Server corriendo (`npm start`)
- [ ] Servidor muestra: "✅ Conectado a MongoDB"
- [ ] Celular puede acceder a http://10.1.7.106:3000

---

## 🔍 VERIFICAR IP ACTUAL

```powershell
ipconfig
```

Busca tu adaptador WiFi:
```
Adaptador de LAN inalámbrica Wi-Fi:
   ...
   Dirección IPv4. . . . . . . . . . . . . : 10.1.7.106
```

**Si la IP cambió:**
1. Actualiza `lib/config/api_config.dart`
2. Cambia `10.1.7.106` por la nueva IP
3. Reinicia la app Flutter

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### ❌ "Cannot connect to API"

**Solución 1: Verificar servidor**
```powershell
cd c:\MX\OmitTaxi\omittaxiapi
.\check-setup.ps1
```

**Solución 2: Verificar desde celular**
- Abre navegador en celular
- Ve a: `http://10.1.7.106:3000`
- Debe mostrar el mensaje del API

**Solución 3: Reiniciar firewall**
```powershell
# Como Administrador:
.\setup-firewall.ps1
```

### ❌ "MongoDB connection failed"

```powershell
# Iniciar MongoDB
net start MongoDB

# Si no funciona, reiniciar PC e intentar de nuevo
```

### ❌ "Port 3000 already in use"

```powershell
# Ver qué usa el puerto
netstat -ano | findstr :3000

# Matar el proceso (reemplaza [PID])
taskkill /PID [PID] /F
```

### ❌ IP cambió

```powershell
# Ver IP actual
ipconfig

# Actualizar en Flutter
# Edita: lib/config/api_config.dart
# Cambia la IP a la nueva
```

---

## 📊 DATOS DE PRUEBA

### Crear Datos de Prueba (Opcional)

```powershell
cd c:\MX\OmitTaxi\omittaxiapi
node seed.js
```

Esto crea:
- 3 pasajeros
- 3 conductores
- 3 viajes de ejemplo

**Credenciales:**
```
Pasajero: ana@test.com / password123
Conductor: carlos@test.com / password123
```

---

## 🎯 FLUJO COMPLETO

### En tu PC:
```powershell
# 1. Iniciar servidor (deja esta terminal abierta)
cd c:\MX\OmitTaxi\omittaxiapi
.\start.ps1
```

### En otra terminal:
```powershell
# 2. Ejecutar app en celular
cd c:\MX\OmitTaxi\omittaxi
flutter run -d JND0219A25000465
```

### En tu celular:
- La app se abrirá automáticamente
- Verás el splash screen "Angeles"
- Podrás registrarte o usar datos de prueba

---

## 📝 COMANDOS ÚTILES

```powershell
# Verificar todo
cd c:\MX\OmitTaxi\omittaxiapi
.\check-setup.ps1

# Iniciar servidor
.\start.ps1

# Ver logs en tiempo real
npm run dev

# Poblar base de datos
node seed.js

# Ver dispositivos Flutter
flutter devices

# Ejecutar app
flutter run -d JND0219A25000465
```

---

## ✅ RESUMEN

**IP Configurada:** 10.1.7.106  
**Puerto API:** 3000  
**App Flutter:** Configurada con `lib/config/api_config.dart`  
**Scripts:** setup-firewall.ps1, check-setup.ps1, start.ps1  

**Todo listo para:**
1. Iniciar servidor: `.\start.ps1`
2. Ejecutar app: `flutter run -d JND0219A25000465`
3. ¡Usar la app Angeles! 🏍️

---

**¿Problemas?** Ejecuta `.\check-setup.ps1` para diagnosticar.
