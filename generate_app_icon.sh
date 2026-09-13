#!/bin/bash
# generate_app_icon.sh
# Erstellt ein standardmäßiges macOS-AppIcon-Assetset aus dem generierten Bild

set -e

# Arbeitsverzeichnis wechseln
cd "$(dirname "$0")"

INPUT_IMAGE="/Users/jensschneider/.gemini/antigravity/brain/dbc19aa6-e836-464a-9b48-020f98fc27fa/app_icon_1787931001776.jpg"
ICONSET_DIR="Sources/Assets.xcassets/AppIcon.appiconset"

mkdir -p "$ICONSET_DIR"

echo "🎨 Generiere Symboldateien aus dem Bild..."

# Umwandeln und Skalieren mit macOS 'sips'
sips -z 16 16   -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32   -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32   -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64   -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128 -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256 -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256 -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512 -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512 -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 -s format png "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

echo "✍️  Schreibe Contents.json..."
cat << 'EOF' > "$ICONSET_DIR/Contents.json"
{
  "images" : [
    {
      "idiom" : "mac",
      "size" : "16x16",
      "scale" : "1x",
      "filename" : "icon_16x16.png"
    },
    {
      "idiom" : "mac",
      "size" : "16x16",
      "scale" : "2x",
      "filename" : "icon_16x16@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "32x32",
      "scale" : "1x",
      "filename" : "icon_32x32.png"
    },
    {
      "idiom" : "mac",
      "size" : "32x32",
      "scale" : "2x",
      "filename" : "icon_32x32@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "128x128",
      "scale" : "1x",
      "filename" : "icon_128x128.png"
    },
    {
      "idiom" : "mac",
      "size" : "128x128",
      "scale" : "2x",
      "filename" : "icon_128x128@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "256x256",
      "scale" : "1x",
      "filename" : "icon_256x256.png"
    },
    {
      "idiom" : "mac",
      "size" : "256x256",
      "scale" : "2x",
      "filename" : "icon_256x256@2x.png"
    },
    {
      "idiom" : "mac",
      "size" : "512x512",
      "scale" : "1x",
      "filename" : "icon_512x512.png"
    },
    {
      "idiom" : "mac",
      "size" : "512x512",
      "scale" : "2x",
      "filename" : "icon_512x512@2x.png"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

echo "✅ AppIcon-Struktur erfolgreich erstellt!"
