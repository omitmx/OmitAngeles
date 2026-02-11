# 🚨 ACCIÓN REQUERIDA: Instalar MongoDB

## ❌ Problema Detectado
El servidor API está corriendo pero **MongoDB no está instalado o no está iniciado**.

Error:
```
❌ Error de conexión a MongoDB: connect ECONNREFUSED ::1:27017
```

---

## ✅ SOLUCIÓN: Instalar MongoDB (5 minutos)

### Opción A: MongoDB Local (Recomendado para desarrollo)

#### Paso 1: Descargar
1. Ve a: **https://www.mongodb.com/try/download/community**
2. Selecciona:
   - **Version:** Latest (7.0 o superior)
   - **Platform:** Windows
   - **Package:** MSI
3. Click en **Download**

#### Paso 2: Instalar
1. Ejecuta el archivo descargado `.msi`
2. Click en "Next" → "Next"
3. **IMPORTANTE:** Marca la opción **"Install MongoDB as a Service"**
4. **IMPORTANTE:** Marca **"Run service as Network Service user"**
5. Click en "Next" hasta completar
6. Espera a que termine la instalación

#### Paso 3: Verificar
```powershell
# Verificar que MongoDB se instaló
mongod --version

# Verificar que el servicio está corriendo
net start MongoDB
```

Deberías ver:
```
El servicio MongoDB ya se ha iniciado.
```

O si no está corriendo:
```powershell
# Iniciar MongoDB
net start MongoDB
```

#### Paso 4: Reiniciar API Server
```powershell
cd c:\MX\OmitTaxi\omittaxiapi
npm start
```

Ahora deberías ver:
```
✅ Conectado a MongoDB
🚀 Servidor corriendo en puerto 3000
```

---

### Opción B: MongoDB Atlas (Cloud - Gratis, Sin Instalación)

Si no quieres instalar MongoDB localmente:

#### Paso 1: Crear cuenta
1. Ve a: **https://www.mongodb.com/cloud/atlas/register**
2. Regístrate con email o Google

#### Paso 2: Crear cluster
1. Selecciona **"Create a FREE cluster"**
2. Selecciona región más cercana
3. Click en **"Create Cluster"**
4. Espera 3-5 minutos

#### Paso 3: Crear usuario de base de datos
1. Click en **"Database Access"** (menú izquierdo)
2. Click en **"Add New Database User"**
3. Usuario: `angeles_admin`
4. Password: `Angeles2024!` (o la que prefieras)
5. Click en **"Add User"**

#### Paso 4: Permitir acceso desde cualquier IP
1. Click en **"Network Access"** (menú izquierdo)
2. Click en **"Add IP Address"**
3. Click en **"Allow Access from Anywhere"** (0.0.0.0/0)
4. Click en **"Confirm"**

#### Paso 5: Obtener URI de conexión
1. Click en **"Database"** (menú izquierdo)
2. Click en **"Connect"** en tu cluster
3. Selecciona **"Connect your application"**
4. Copia el **Connection String**
   ```
   mongodb+srv://angeles_admin:<password>@cluster0.xxxxx.mongodb.net/
   ```

#### Paso 6: Actualizar .env
Edita `c:\MX\OmitTaxi\omittaxiapi\.env`:

```env
MONGODB_URI=mongodb+srv://angeles_admin:Angeles2024!@cluster0.xxxxx.mongodb.net/angeles_mototaxi?retryWrites=true&w=majority
```

**IMPORTANTE:** Reemplaza:
- `<password>` con tu contraseña
- `cluster0.xxxxx` con tu URL real

#### Paso 7: Reiniciar API
```powershell
cd c:\MX\OmitTaxi\omittaxiapi
npm start
```

---

## 🎯 ¿Cuál Opción Elegir?

### MongoDB Local (Opción A)
- ✅ Más rápido (sin latencia de internet)
- ✅ Funciona offline
- ✅ Gratis ilimitado
- ❌ Requiere instalación

### MongoDB Atlas (Opción B)
- ✅ No requiere instalación
- ✅ Accesible desde cualquier lugar
- ✅ Backups automáticos
- ❌ Requiere internet
- ❌ Límite de 512 MB gratis

**Recomendación:** Usa **Opción A (Local)** para desarrollo.

---

## ⚡ INICIO RÁPIDO - Solo Comandos

### Si eliges MongoDB Local:
```powershell
# 1. Instalar MongoDB desde: 
#    https://www.mongodb.com/try/download/community

# 2. Verificar
net start MongoDB

# 3. Iniciar API
cd c:\MX\OmitTaxi\omittaxiapi
npm start

# 4. Ejecutar app
cd c:\MX\OmitTaxi\omittaxi
flutter run -d JND0219A25000465
```

### Si eliges MongoDB Atlas:
```powershell
# 1. Crear cluster en: 
#    https://www.mongodb.com/cloud/atlas

# 2. Actualizar .env con tu URI

# 3. Iniciar API
cd c:\MX\OmitTaxi\omittaxiapi
npm start

# 4. Ejecutar app
cd c:\MX\OmitTaxi\omittaxi
flutter run -d JND0219A25000465
```

---

## ✅ Verificar que Funciona

Después de instalar MongoDB, ejecuta:

```powershell
cd c:\MX\OmitTaxi\omittaxiapi
npm start
```

Debes ver:
```
✅ Conectado a MongoDB           ← ESTO DEBE APARECER
🚀 Servidor corriendo en puerto 3000
📡 WebSocket habilitado para tracking en tiempo real
🌐 URL: http://localhost:3000
```

Si ves ✅ **"Conectado a MongoDB"**, todo está bien!

---

## 🆘 Ayuda Rápida

### MongoDB Local no inicia
```powershell
# Intentar iniciar manualmente
net start MongoDB

# Si falla, reiniciar PC e intentar de nuevo
```

### Olvidé mi configuración de Atlas
- Ve a: https://cloud.mongodb.com
- Login → Database → Connect → Get connection string

### Cambiar de Local a Atlas (o viceversa)
Solo edita el archivo `.env` y cambia `MONGODB_URI`

---

**Siguiente paso:** Instala MongoDB usando cualquiera de las dos opciones y luego inicia el servidor! 🚀
