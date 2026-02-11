# 🏍️ OmitTaxi - Aplicación de Mototaxi

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" />
</div>

## 📱 Descripción

**OmitTaxi** es una aplicación móvil tipo Uber diseñada específicamente para servicios de mototaxi. La aplicación permite a los usuarios solicitar viajes rápidos y seguros en motocicleta, mientras que los conductores pueden aceptar solicitudes y gestionar sus servicios.

## ✨ Características Principales

### Para Pasajeros 🧑
- ✅ Solicitud de viajes con mapa interactivo
- ✅ Selección de origen y destino
- ✅ Cálculo automático de tarifas (Base: $20 + $8/km)
- ✅ Seguimiento en tiempo real
- ✅ Historial de viajes
- ✅ Sistema de calificación de conductores
- ✅ Perfil de usuario personalizado

### Para Conductores 🏍️
- ✅ Sistema de conexión/desconexión
- ✅ Recepción de solicitudes de viaje
- ✅ Panel de estadísticas (viajes diarios, ganancias)
- ✅ Navegación GPS integrada
- ✅ Gestión de perfil
- ✅ Historial de viajes realizados

## 🛠️ Tecnologías Utilizadas

- **Flutter 3.10+** - Framework de desarrollo multiplataforma
- **Provider** - Gestión de estado
- **Google Maps Flutter** - Mapas interactivos
- **Geolocator** - Servicios de geolocalización
- **Flutter Rating Bar** - Sistema de calificaciones
- **Intl** - Internacionalización y formato de fechas
- **UUID** - Generación de identificadores únicos

## 📦 Dependencias

```yaml
dependencies:
  flutter_rating_bar: ^4.0.1
  geolocator: ^14.0.2
  google_maps_flutter: ^2.14.0
  intl: ^0.20.2
  provider: ^6.1.5+1
  uuid: ^4.5.2
```

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK 3.10 o superior
- Android Studio o Xcode (para desarrollo iOS)
- Cuenta de Google Cloud Platform (para Google Maps API)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <url-del-repositorio>
   cd omittaxi
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Google Maps API**
   
   Ver el archivo [SETUP_MAPS.md](SETUP_MAPS.md) para instrucciones detalladas.

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📱 Capturas de Pantalla

### Flujo de Usuario

1. **Splash Screen** - Pantalla de bienvenida con animaciones
2. **Selección de Rol** - Elegir entre Pasajero o Conductor
3. **Mapa Principal** - Vista de mapa interactivo
4. **Solicitud de Viaje** - Selección de origen y destino
5. **Búsqueda de Conductor** - Espera mientras se busca conductor
6. **Viaje en Progreso** - Seguimiento en tiempo real
7. **Historial** - Lista de viajes anteriores
8. **Perfil** - Información del usuario

## 🎨 Paleta de Colores

- **Principal**: `#2E7D32` (Verde oscuro) - Representa eco-movilidad
- **Secundario**: `#FFB300` (Amarillo dorado) - Energía y velocidad
- **Acento**: `#1B5E20` (Verde muy oscuro)

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/                   # Modelos de datos
│   ├── user_model.dart       # Modelo de usuario
│   └── ride_model.dart       # Modelo de viaje
├── providers/                # Gestión de estado (Provider)
│   ├── user_provider.dart    # Estado del usuario
│   └── ride_provider.dart    # Estado de viajes
└── screens/                  # Pantallas de la aplicación
    ├── splash_screen.dart    # Pantalla de inicio
    ├── welcome_screen.dart   # Selección de rol
    ├── profile_screen.dart   # Perfil de usuario
    ├── ride_history_screen.dart # Historial de viajes
    ├── passenger/            # Pantallas de pasajero
    │   ├── passenger_home_screen.dart
    │   └── request_ride_screen.dart
    └── driver/               # Pantallas de conductor
        └── driver_home_screen.dart
```

## 🔧 Configuración Adicional

### Habilitar Compilación para Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🌟 Características Futuras (Roadmap)

- [ ] Integración con Firebase para autenticación real
- [ ] Sistema de pagos integrado (Stripe, PayPal)
- [ ] Notificaciones push en tiempo real
- [ ] Chat entre conductor y pasajero
- [ ] Modo nocturno
- [ ] Soporte multiidioma
- [ ] Compartir ubicación en tiempo real
- [ ] Sistema de propinas
- [ ] Historial de rutas guardadas
- [ ] Estimación de tiempo de llegada (ETA)

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu característica (`git checkout -b feature/NuevaCaracteristica`)
3. Commit tus cambios (`git commit -m 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/NuevaCaracteristica`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 👥 Autores

- **Tu Nombre** - Desarrollo inicial

## 📞 Soporte

Para soporte, envía un email a soporte@omittaxi.com o abre un issue en el repositorio.

## 🙏 Agradecimientos

- Comunidad de Flutter
- Google Maps Platform
- Iconos de Material Design

---

<div align="center">
  Hecho con ❤️ y Flutter
</div>
