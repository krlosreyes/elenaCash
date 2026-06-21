#!/bin/bash
# Script de build para iOS y Android
# Ejecutar desde: elenacash_app/

set -e
echo "=== ElenaCash Release Build ==="

# 1. Dependencias
echo "[1/5] flutter pub get..."
flutter pub get

# 2. Generar código Riverpod
echo "[2/5] build_runner..."
dart run build_runner build --delete-conflicting-outputs

# 3. Íconos y splash
echo "[3/5] Generando íconos y splash..."
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# 4. Android APK / AAB
echo "[4/5] Build Android (AAB para Play Store)..."
flutter build appbundle --release --obfuscate --split-debug-info=build/debug_info/android
# Para APK directo (testing):
# flutter build apk --release --split-per-abi

# 5. iOS
echo "[5/5] Build iOS..."
# Requiere Mac con Xcode y certificados configurados
# cd ios && pod install && cd ..
# flutter build ipa --release --obfuscate --split-debug-info=build/debug_info/ios

echo ""
echo "=== Build completado ==="
echo "AAB Android: build/app/outputs/bundle/release/app-release.aab"
echo "IPA iOS:     build/ios/ipa/*.ipa"
