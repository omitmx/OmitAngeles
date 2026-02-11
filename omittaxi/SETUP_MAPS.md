# Configuración de Google Maps API

## Pasos para obtener tu API Key

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las siguientes APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geolocation API
   - Places API (opcional, para búsqueda de direcciones)

4. Ve a "Credentials" y crea una API Key
5. Restringe la API Key (recomendado):
   - Para Android: Añade el package name y SHA-1 fingerprint
   - Para iOS: Añade el Bundle ID

## Configuración Android

Edita `android/app/src/main/AndroidManifest.xml` y agrega dentro de `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

## Configuración iOS

1. Edita `ios/Runner/AppDelegate.swift`
2. Importa GoogleMaps al inicio:
```swift
import GoogleMaps
```

3. Dentro del método `application`, antes del return, agrega:
```swift
GMSServices.provideAPIKey("TU_API_KEY_AQUI")
```

El archivo debería verse así:
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Permisos de Ubicación

### Android
Edita `android/app/src/main/AndroidManifest.xml` y agrega antes de `<application>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS
Edita `ios/Runner/Info.plist` y agrega:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>OmitTaxi necesita tu ubicación para mostrarte mototaxis cercanos y calcular rutas</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>OmitTaxi necesita tu ubicación para rastrear tu viaje en tiempo real</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>OmitTaxi necesita tu ubicación para rastrear tu viaje en tiempo real</string>
```

## Modo de Prueba (Sin API Key)

Para probar la app sin configurar Google Maps, puedes:

1. Comentar temporalmente el widget GoogleMap
2. Usar una vista simple con botones
3. La funcionalidad básica seguirá funcionando (Provider, navegación, etc.)

## Notas Importantes

- **NUNCA** subas tu API Key a repositorios públicos
- Usa variables de entorno o archivos de configuración ignorados por git
- Habilita la facturación en Google Cloud (tiene capa gratuita generosa)
- Restringe tu API Key por aplicación y tipo de API
