# 🧪 Manual de Pruebas - OmitTaxi

## 🎯 Objetivo

Este documento te guiará a través de todas las funcionalidades de la aplicación para que puedas probarlas completamente.

## 📋 Checklist de Pruebas

### ✅ Inicio de Aplicación

- [ ] **Splash Screen**
  - Aparece el logo de mototaxi
  - Animación de fade in y scale
  - Transición automática después de 3 segundos
  - Se muestra "OmitTaxi" y "Tu Mototaxi Express"

### ✅ Pantalla de Bienvenida

- [ ] **UI**
  - Gradiente verde visible
  - Icono de mototaxi centrado
  - Dos tarjetas: "Soy Pasajero" y "Soy Conductor"
  - Tarjetas tienen efecto de toque (ripple)
  
- [ ] **Funcionalidad**
  - Tocar "Soy Pasajero" navega a pantalla de pasajero
  - Tocar "Soy Conductor" navega a pantalla de conductor
  - Los datos de demo se cargan correctamente

---

## 🧑 Modo Pasajero

### Pantalla Principal

- [ ] **Mapa**
  - Se carga el mapa de Google Maps
  - Se solicita permiso de ubicación
  - Marcador verde en ubicación actual
  - Botones de zoom funcionan
  - Botón "Mi ubicación" funciona

- [ ] **Card Superior**
  - Muestra saludo con nombre del usuario
  - Muestra "¿A dónde quieres ir hoy?"

- [ ] **Botón Principal**
  - Botón "Solicitar Mototaxi" visible
  - Tiene icono de mototaxi
  - Color verde (#2E7D32)
  - Al tocar navega a pantalla de solicitud

### Solicitud de Viaje

- [ ] **Mapa de Ruta**
  - Muestra mapa con ubicación actual
  - Marcador verde en punto de recogida
  - Al seleccionar destino aparece marcador rojo

- [ ] **Campos de Ubicación**
  - Campo "Punto de recogida" lleno automáticamente
  - Campo "Destino" permite selección
  - Al tocar destino se simula selección

- [ ] **Card de Tarifa**
  - Aparece solo cuando hay destino seleccionado
  - Muestra "Mototaxi Express"
  - Muestra tiempo estimado "3-5 min"
  - Calcula y muestra tarifa correctamente
  - Formato: $XX.XX

- [ ] **Botón Solicitar**
  - Se habilita solo con destino
  - Al tocar muestra diálogo "Buscando conductor"
  - Spinner de carga visible
  - Botón "Cancelar" funciona

### Navigation Bar

- [ ] **Inicio**
  - Muestra pantalla de mapa
  - Icono resaltado en verde

- [ ] **Historial**
  - Navega a pantalla de historial
  - Si no hay viajes, muestra mensaje vacío
  - Si hay viajes, muestra lista

- [ ] **Perfil**
  - Navega a pantalla de perfil
  - Muestra información del usuario

### Menú Lateral (Drawer)

- [ ] **Header**
  - Avatar circular
  - Nombre del usuario
  - Email del usuario
  - Fondo verde

- [ ] **Opciones**
  - "Mis Viajes" navega a historial
  - "Métodos de Pago" (preparado para futuro)
  - "Ayuda" (preparado para futuro)
  - "Configuración" (preparado para futuro)
  - "Cerrar Sesión" cierra sesión

### Historial de Viajes

- [ ] **Lista Vacía**
  - Icono de historial grande
  - Mensaje "No tienes viajes registrados"

- [ ] **Lista con Viajes** (después de solicitar)
  - Muestra fecha y hora
  - Chip de estado con color
  - Dirección de origen con pin verde
  - Dirección de destino con bandera roja
  - Distancia en km
  - Tarifa en pesos
  - Calificación (si existe)

- [ ] **Detalles de Viaje**
  - Al tocar viaje abre modal
  - Modal deslizable
  - Muestra todos los detalles
  - Calificación con estrellas
  - Comentario (si existe)

### Perfil de Usuario

- [ ] **Información**
  - Avatar grande circular
  - Nombre del usuario
  - Calificación con estrella dorada
  - Total de viajes
  - Email con icono
  - Teléfono con icono
  - Tipo de cuenta (Pasajero)

- [ ] **Botones**
  - "Editar Perfil" con icono
  - "Configuración" con borde

---

## 🏍️ Modo Conductor

### Pantalla Principal

- [ ] **Mapa**
  - Se carga el mapa
  - Muestra ubicación actual
  - Botones de navegación funcionan

- [ ] **AppBar**
  - Título "OmitTaxi - Conductor"
  - Chip de estado ("En línea" / "Fuera de línea")
  - Color verde si en línea, gris si no

- [ ] **Card de Estadísticas**
  - "Viajes hoy": número
  - "Ganancia": cantidad en pesos
  - "Calificación": número con estrella

- [ ] **Botón de Estado**
  - Botón grande inferior
  - Verde con texto "CONECTAR" cuando offline
  - Rojo con texto "DESCONECTAR" cuando online
  - Cambia estado al tocar

### Recepción de Viajes

- [ ] **Notificación de Viaje**
  - Aparece automáticamente 3s después de conectar
  - Modal con título "¡Nuevo viaje!"
  - Muestra dirección de recogida
  - Muestra dirección de destino
  - Muestra distancia
  - Muestra tarifa

- [ ] **Opciones de Respuesta**
  - Botón "Rechazar" cierra modal
  - Botón "Aceptar" verde acepta viaje

### Viaje en Progreso

- [ ] **Modal de Progreso**
  - Icono de mototaxi grande
  - Mensaje "Dirigiéndote al punto de recogida..."
  - Botón "Completar viaje"

- [ ] **Completar Viaje**
  - Al completar muestra SnackBar verde
  - Mensaje incluye ganancia (+$XX.XX)
  - Vuelve al estado en línea

### Perfil de Conductor

- [ ] **Información**
  - Avatar circular
  - Nombre del conductor
  - Calificación
  - Total de viajes
  - Email
  - Teléfono
  - Tipo: "Conductor"

### Menú Lateral

- [ ] **Opciones de Conductor**
  - "Mis Estadísticas"
  - "Ganancias"
  - "Ayuda"
  - "Configuración"
  - "Cerrar Sesión"

---

## 🔄 Flujos Completos

### Flujo 1: Solicitar Viaje como Pasajero

1. Abrir app → Splash Screen → Welcome
2. Seleccionar "Soy Pasajero"
3. Permitir permisos de ubicación
4. Esperar carga del mapa
5. Tocar "Solicitar Mototaxi"
6. Tocar campo "Destino"
7. Verificar cálculo de tarifa
8. Tocar "Solicitar Mototaxi"
9. Ver diálogo de búsqueda
10. Opcional: Cancelar viaje

**Resultado esperado:** ✅ Todos los pasos funcionan sin errores

### Flujo 2: Aceptar Viaje como Conductor

1. Abrir app → Splash Screen → Welcome
2. Seleccionar "Soy Conductor"
3. Permitir permisos de ubicación
4. Ver dashboard con estadísticas
5. Tocar "CONECTAR"
6. Esperar notificación de viaje (3s)
7. Revisar detalles del viaje
8. Tocar "Aceptar"
9. Ver modal de progreso
10. Tocar "Completar viaje"
11. Ver confirmación de ganancia

**Resultado esperado:** ✅ Todos los pasos funcionan sin errores

### Flujo 3: Ver Historial

1. Desde pantalla principal
2. Ir a tab "Historial"
3. Ver lista de viajes
4. Tocar un viaje
5. Ver modal con detalles
6. Deslizar para cerrar

**Resultado esperado:** ✅ Modal se abre y cierra correctamente

### Flujo 4: Cerrar Sesión

1. Abrir menú lateral
2. Tocar "Cerrar Sesión"
3. Volver a pantalla de bienvenida

**Resultado esperado:** ✅ Sesión se cierra correctamente

---

## 🐛 Casos de Prueba de Error

### Sin Permisos de Ubicación

- [ ] Denegar permisos
- [ ] App usa ubicación por defecto (CDMX)
- [ ] Muestra mensaje apropiado

### Sin Conexión a Internet

- [ ] Desactivar WiFi y datos
- [ ] Intentar cargar mapa
- [ ] Ver comportamiento de error

### Cancelar Solicitud de Viaje

- [ ] Solicitar viaje
- [ ] Durante búsqueda, tocar "Cancelar"
- [ ] Viaje se cancela correctamente
- [ ] Vuelve a pantalla principal

---

## 📊 Métricas de Rendimiento

### Tiempos de Carga

- [ ] Splash Screen → Welcome: < 3 segundos
- [ ] Welcome → Home: < 1 segundo
- [ ] Carga de mapa: < 2 segundos
- [ ] Transiciones: Fluidas (60 FPS)

### Uso de Memoria

- [ ] No hay memory leaks
- [ ] Uso de RAM estable
- [ ] Sin crashes por memoria

---

## ✅ Checklist Final

Antes de considerar una versión lista:

- [ ] Todas las pantallas probadas
- [ ] Ambos roles (Pasajero/Conductor) funcionan
- [ ] Navegación fluida
- [ ] Sin crashes
- [ ] Permisos funcionan correctamente
- [ ] UI responsiva
- [ ] Textos sin errores ortográficos
- [ ] Colores consistentes
- [ ] Iconos apropiados
- [ ] Botones con feedback visual

---

## 📝 Reportar Bugs

Si encuentras un bug durante las pruebas:

1. **Describe el problema**
   - ¿Qué esperabas?
   - ¿Qué obtuviste?

2. **Pasos para reproducir**
   - Enumera los pasos exactos

3. **Información del dispositivo**
   - Modelo
   - Versión de OS
   - Versión de la app

4. **Screenshots**
   - Capturas del problema

5. **Logs**
   - Copia los logs de Flutter

---

## 🎉 Pruebas Completadas

Una vez todas las pruebas pasen:

✅ **La app está lista para:**
- Testing beta con usuarios reales
- Optimizaciones de rendimiento
- Preparación para producción
- Configuración de Firebase
- Implementación de pagos
- Publicación en tiendas

---

**¡Felicidades por probar OmitTaxi!** 🏍️✨

¿Encontraste algún problema? Repórtalo en el issue tracker.
