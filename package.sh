#!/bin/bash
# package.sh
# Automatisches Kompilieren und Verpacken der Immich-Go macOS Uploader App

set -e

# Arbeitsverzeichnis wechseln
cd "$(dirname "$0")"

echo "🚀 Starte Verpackungsprozess für ImmichGoUploader..."

# 0. Finder-Metadaten bereinigen (verhindert Codesign-Fehler)
echo "🧹 Bereinige erweiterte Datei-Attribute..."
xattr -cr . || true

# 1. Projekt generieren
echo "⚙️  Generiere aktuelles Xcode-Projekt..."
xcodegen generate

# 2. Release Build in /tmp/ImmichDerivedData erstellen (vermeidet iCloud-Synchronisationsattribute & Sandbox-Rechteprobleme)
echo "🛠️  Kompiliere App in Release-Konfiguration..."
DERIVED_DATA="/tmp/ImmichDerivedData"
rm -rf "$DERIVED_DATA"
xcodebuild -project ImmichGoUploader.xcodeproj -scheme ImmichGoUploader -configuration Release -derivedDataPath "$DERIVED_DATA" clean build

# 2.1. Build-Pfad ermitteln und lokal kopieren
echo "📂 Kopiere fertiges App-Bundle..."
BUILT_PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Release"

rm -rf build
mkdir -p build/Release
cp -R "$BUILT_PRODUCTS_DIR/ImmichGoUploader.app" build/Release/

# 2.2. Datei-Attribute vom Kopieren bereinigen
xattr -cr build/Release/ImmichGoUploader.app

# 3. ZIP-Archiv erstellen
echo "📦 Erstelle ZIP-Archiv..."
cd build/Release
zip -q -r ../../ImmichGoUploader.zip ImmichGoUploader.app
cd ../..

# 4. DMG-Laufwerksimage erstellen
echo "💿 Erstelle DMG-Laufwerksimage..."
mkdir -p build/dmg
cp -R build/Release/ImmichGoUploader.app build/dmg/
# Verknüpfung zu /Applications hinzufügen, um das Drag-and-Drop zu erleichtern
ln -s /Applications build/dmg/Programme

hdiutil create -volname "ImmichGoUploader" -srcfolder build/dmg -ov -format UDZO ImmichGoUploader.dmg
rm -rf build/dmg
rm -rf "$DERIVED_DATA"

echo "=========================================================="
echo "✅ Verpackung erfolgreich abgeschlossen!"
echo "💾 Erstellte Dateien im Projektverzeichnis:"
echo "   - ZIP-Archiv: $(pwd)/ImmichGoUploader.zip (Schnelles Teilen)"
echo "   - DMG-Image:  $(pwd)/ImmichGoUploader.dmg (Professionelle Installation)"
echo "=========================================================="
