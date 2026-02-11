# 🔧 Comandos Útiles - OmitTaxi

## 📱 Comandos Básicos

### Instalar dependencias
```bash
flutter pub get
```

### Ejecutar la aplicación
```bash
flutter run
```

### Ejecutar en dispositivo específico
```bash
flutter devices                    # Ver dispositivos disponibles
flutter run -d <device-id>         # Ejecutar en dispositivo específico
flutter run -d chrome              # Ejecutar en navegador
flutter run -d windows             # Ejecutar en Windows
```

### Hot Reload y Hot Restart
```bash
# Durante ejecución en terminal:
r     # Hot reload (mantiene el estado)
R     # Hot restart (resetea el estado)
q     # Salir
```

## 🧹 Limpieza y Mantenimiento

### Limpiar build
```bash
flutter clean
flutter pub get
```

### Limpiar cache de Gradle (Android)
```bash
cd android
./gradlew clean
cd ..
```

### Limpiar todo completamente
```bash
flutter clean
rm -rf pubspec.lock
rm -rf .dart_tool
flutter pub get
```

## 🔍 Análisis y Debugging

### Analizar código
```bash
flutter analyze
```

### Ver logs en tiempo real
```bash
flutter logs
```

### Modo verbose
```bash
flutter run -v
```

### Ver rendimiento
```bash
flutter run --profile
```

## 🏗️ Build y Compilación

### Android APK (Debug)
```bash
flutter build apk
```

### Android APK (Release)
```bash
flutter build apk --release
```

### Android App Bundle (Para Play Store)
```bash
flutter build appbundle --release
```

### iOS (requiere Mac)
```bash
flutter build ios --release
```

### Windows Desktop
```bash
flutter build windows
```

## 📦 Gestión de Dependencias

### Agregar nueva dependencia
```bash
flutter pub add <package_name>
```

### Agregar dependencia dev
```bash
flutter pub add dev:<package_name>
```

### Actualizar dependencias
```bash
flutter pub upgrade
```

### Ver dependencias desactualizadas
```bash
flutter pub outdated
```

### Remover dependencia
```bash
flutter pub remove <package_name>
```

## 🧪 Testing

### Ejecutar tests
```bash
flutter test
```

### Ejecutar tests con cobertura
```bash
flutter test --coverage
```

### Ver reporte de cobertura
```bash
# En Windows (requiere genhtml)
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

## 🔧 Formato y Linting

### Formatear código
```bash
dart format lib/
```

### Formatear archivo específico
```bash
dart format lib/screens/splash_screen.dart
```

### Fix automático de lints
```bash
dart fix --apply
```

## 📊 Información del Proyecto

### Ver información de Flutter
```bash
flutter doctor
flutter doctor -v          # Versión detallada
```

### Ver versión de Flutter
```bash
flutter --version
```

### Ver canales disponibles
```bash
flutter channel
```

### Cambiar canal
```bash
flutter channel stable
flutter upgrade
```

## 🚀 Utilidades Específicas del Proyecto

### Ver estructura del proyecto
```bash
tree /F /A lib
```

### Contar líneas de código
```bash
# PowerShell
(Get-ChildItem -Path lib -Recurse -Include *.dart | Get-Content | Measure-Object -Line).Lines
```

### Buscar en código
```bash
# PowerShell
Get-ChildItem -Path lib -Recurse -Include *.dart | Select-String "SearchTerm"
```

## 🗺️ Google Maps

### Validar configuración de Maps (Android)
```bash
# Verificar AndroidManifest.xml
cat android/app/src/main/AndroidManifest.xml | grep API_KEY
```

### Validar configuración de Maps (iOS)
```bash
# Verificar AppDelegate.swift
cat ios/Runner/AppDelegate.swift | grep GMSServices
```

## 🔑 Variables de Entorno (Futuro)

### Crear archivo .env
```bash
echo API_KEY=your_api_key_here > .env
```

### Usar flutter_dotenv
```bash
flutter pub add flutter_dotenv
```

## 📱 Generación de Assets

### Generar iconos de app
```bash
flutter pub add flutter_launcher_icons
flutter pub run flutter_launcher_icons
```

### Generar splash screens nativos
```bash
flutter pub add flutter_native_splash
flutter pub run flutter_native_splash:create
```

## 🐛 Debugging Avanzado

### Modo debug con inspector
```bash
flutter run --debug
# Luego presiona 'w' para abrir DevTools en navegador
```

### Ver árbol de widgets
```bash
# Durante ejecución:
w     # Abrir DevTools
```

### Performance overlay
```bash
# Durante ejecución:
P     # Toggle performance overlay
```

## 🔄 Git (Control de Versiones)

### Inicializar repositorio
```bash
git init
git add .
git commit -m "Initial commit: OmitTaxi base project"
```

### Crear .gitignore (ya existe)
```bash
# El archivo .gitignore ya está creado
```

### Commits recomendados
```bash
git commit -m "feat: Add splash screen with animations"
git commit -m "feat: Implement passenger home screen"
git commit -m "feat: Add ride request functionality"
git commit -m "fix: Resolve map controller warnings"
git commit -m "docs: Update README with setup instructions"
```

## 🔥 Firebase (Para futuras implementaciones)

### Instalar Firebase CLI
```bash
npm install -g firebase-tools
```

### Login a Firebase
```bash
firebase login
```

### Inicializar Firebase
```bash
flutter pub add firebase_core
flutterfire configure
```

## 📊 Análisis de Tamaño

### Ver tamaño del APK
```bash
flutter build apk --analyze-size
```

### Análisis detallado
```bash
flutter build apk --tree-shake-icons --split-debug-info=./debug-info
```

## 🎯 Atajos de Desarrollo

### Reinicio rápido completo
```bash
flutter clean && flutter pub get && flutter run
```

### Análisis completo
```bash
flutter analyze && flutter test
```

### Build y deploy rápido (Android)
```bash
flutter build apk --release && adb install build/app/outputs/flutter-apk/app-release.apk
```

## 📝 Notas

- Todos los comandos deben ejecutarse desde: `c:\MX\OmitTaxi\omittaxi`
- Algunos comandos requieren dispositivo conectado o emulador activo
- Para iOS se requiere Mac con Xcode instalado
- Usar PowerShell o CMD en Windows

## 🆘 Solución de Problemas Comunes

### "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### "Could not resolve dependencies"
```bash
flutter pub cache repair
flutter pub get
```

### "No devices found"
```bash
# Android
flutter emulators              # Ver emuladores
flutter emulators --launch <emulator_id>

# O conectar dispositivo físico con USB debugging
```

### "MissingPluginException"
```bash
flutter clean
flutter pub get
# Detener app
flutter run
```

---

💡 **Tip:** Guarda este archivo para referencia rápida durante el desarrollo!

🚀 **¡Listo para desarrollar!** Usa estos comandos para optimizar tu flujo de trabajo.
