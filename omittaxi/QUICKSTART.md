# 🚀 Guía de Inicio Rápido - OmitTaxi

Esta guía te ayudará a ejecutar la aplicación en minutos.

## ⚡ Inicio Rápido (Sin configurar Google Maps)

Si solo quieres probar la aplicación sin configurar Google Maps:

1. **Instalar dependencias**
   ```bash
   cd omittaxi
   flutter pub get
   ```

2. **Ejecutar en modo debug**
   ```bash
   flutter run
   ```

**Nota:** La aplicación funcionará pero las vistas de mapa mostrarán un error. Todas las demás funcionalidades (navegación, perfil, historial, etc.) funcionarán correctamente.

## 🗺️ Configuración Completa (Con Google Maps)

### Paso 1: Obtener API Key de Google Maps

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un proyecto nuevo
3. Habilita estas APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
4. En "Credentials", crea una API Key
5. Copia la API Key

### Paso 2: Configurar Android

Edita `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <application ...>
        <!-- Agrega esto dentro de <application> -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="PEGA_TU_API_KEY_AQUI"/>
    </application>
</manifest>
```

### Paso 3: Configurar iOS

Edita `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleMaps  // <- Agregar esta línea

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Agregar esta línea con tu API Key
    GMSServices.provideAPIKey("PEGA_TU_API_KEY_AQUI")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Paso 4: Ejecutar

```bash
flutter run
```

## 📱 Probando la Aplicación

### Como Pasajero:
1. En la pantalla de bienvenida, selecciona "Soy Pasajero"
2. Permite los permisos de ubicación
3. Toca "Solicitar Mototaxi"
4. Selecciona un destino tocando el campo
5. Revisa la tarifa estimada
6. Toca "Solicitar Mototaxi"

### Como Conductor:
1. En la pantalla de bienvenida, selecciona "Soy Conductor"
2. Toca el botón "CONECTAR" para ponerte en línea
3. Recibirás una solicitud de viaje simulada
4. Acepta el viaje
5. Completa el viaje

## 🎯 Funcionalidades Disponibles

✅ **Sin configurar Maps:**
- Navegación entre pantallas
- Gestión de estado (Provider)
- Perfil de usuario
- Historial de viajes
- Sistema de calificación
- Cálculo de tarifas

✅ **Con Maps configurado:**
- Todo lo anterior +
- Vista de mapa interactivo
- Ubicación en tiempo real
- Marcadores en el mapa
- Rutas visuales

## 🐛 Solución de Problemas

### Error: "MissingPluginException"
```bash
flutter clean
flutter pub get
flutter run
```

### Error: "Google Maps API Key not found"
- Verifica que agregaste la API Key en los archivos correctos
- Asegúrate de quitar las comillas y espacios extra

### Error de permisos de ubicación
- En Android: Verifica `AndroidManifest.xml`
- En iOS: Verifica `Info.plist`
- Acepta los permisos cuando la app los solicite

### La app no compila
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

## 💡 Consejos

1. **Usa un dispositivo real** para probar GPS y ubicación
2. **Hot Reload** funciona con `r` en la terminal
3. **Hot Restart** con `R` si hay cambios mayores
4. Revisa los logs con `flutter logs`

## 📚 Próximos Pasos

1. ✅ Ejecutar la aplicación
2. 📖 Leer el [README.md](README.md) completo
3. 🗺️ Configurar Google Maps con [SETUP_MAPS.md](SETUP_MAPS.md)
4. 🎨 Personalizar colores y estilos
5. 🔥 Agregar Firebase para datos reales
6. 🚀 ¡Publicar en las tiendas!

## 🆘 ¿Necesitas Ayuda?

- Revisa la [documentación de Flutter](https://docs.flutter.dev)
- Consulta [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- Abre un issue en el repositorio

---

¡Disfruta construyendo con OmitTaxi! 🏍️✨
