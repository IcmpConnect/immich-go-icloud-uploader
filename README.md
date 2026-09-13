# 📸 ImmichGo iCloud Uploader (macOS)

[![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Version](https://img.shields.io/badge/version-v1.1.0-brightgreen.svg)](https://github.com/IcmpConnect/immich-go-icloud-uploader/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

🌐 **Language / Sprache**: [English](#english) | [Deutsch](#deutsch)

---

<a name="english"></a>
## 🇬🇧 English

A modern, native macOS SwiftUI application designed to **filter**, **preview**, **locally backup**, and **upload** Apple Photos & iCloud media to a self-hosted [Immich](https://immich.app) server or to any local/network destination (external SSD, USB drive, NAS share).

### ✨ Key Features

- **🌍 Fully Bilingual (v1.1.0)**:
  - Instant live language switching between **🇬🇧 English** and **🇩🇪 Deutsch** from the toolbar menu.
  - Automatic detection of your macOS system language on initial launch.
  - Real-time translated status messages, filter options, dialogs, and integrated guide.

- **🎯 Guided 3-Step Workflow**:
  1. **System Check**: Automatic validation of requirements (`immich-go` CLI & Photos Library permissions).
  2. **Filter & Live Preview**: Filter precisely by media type (*All*, *Photos only*, *Videos only*) and date range (*Entire Library*, *Year & Month*, or *Custom Date Range*).
  3. **Choose Destination & Run**: Pick between structured local disk export or direct Immich server upload.

- **🖼️ Fast Live Media Preview**:
  - Horizontal thumbnail carousel of matching media.
  - Smooth caching via `PHCachingImageManager`.
  - Badges for video durations and Live Photos.
  - Accurate counts for photos and videos.

- **📁 Local Export with Date Hierarchy (`Year / Month / Day`)**:
  - Exports originals directly to hard drives, external media, or NAS shares.
  - Organized chronologically: `[Destination]/YYYY/MM/DD/[Filename]` (e.g. `2023/11/05/IMG_1234.HEIC`).
  - **Live Photos paired**: Photo and companion video are always stored together with identical base names.
  - **Continuous parallel streaming**: High-throughput transfers without arbitrary batch pauses.
  - **Smart Overwrite Protection**: Existing files are never overwritten; identical file names receive safe suffixes (`_1`, `_2`).

- **☁️ Immich Server Upload**:
  - Seamless integration with the high-performance `immich-go` engine.
  - Parallel uploads and configurable batch sizes.
  - Prevents local disk filling by continuously clearing temporary download caches.

- **🛡️ Maximum Stability & Fault Tolerance**:
  - Automatic **3x retry with exponential backoff** for iCloud downloads.
  - Non-blocking: **Pause**, **Resume**, and **Cancel** at any moment.
  - Incremental history: Remembers transferred assets in JSON state files to skip duplicates upon restart.
  - Memory-safe bounded logging console to avoid performance leaks.

- **❓ Integrated Help System**:
  - Accessible directly inside the app via the toolbar or menu.
  - 5 comprehensive chapters covering quick start, local NAS backups, API keys, date filtering, and troubleshooting.

### 🚀 Download & Installation

Download the ready-to-run installation package:

👉 **[Download Latest Release (v1.1.0)](https://github.com/IcmpConnect/immich-go-icloud-uploader/releases)**

1. Open `ImmichGoUploader.dmg`.
2. Drag `ImmichGoUploader` into your **Applications** folder.
3. Launch the app and grant Apple Photos library permission when prompted.

---

<a name="deutsch"></a>
## 🇩🇪 Deutsch

Eine native, moderne macOS-App (SwiftUI) zum **Filtern**, **Vorschauen**, **lokalen Sichern** und **Hochladen** von Apple Fotos & iCloud-Medien auf eine selbstgehostete [Immich](https://immich.app)-Instanz oder auf beliebige lokale Datenträger (Festplatte, USB, NAS).

### ✨ Highlights & Funktionen

- **🌍 Vollständig Zweisprachig (v1.1.0)**:
  - Umschaltung in Echtzeit zwischen **🇩🇪 Deutsch** und **🇬🇧 English** über das Menü in der Symbolleiste.
  - Automatische Erkennung der macOS-Systemsprache beim ersten Start.
  - Statusanzeigen, Filter, Dialoge und Hilfesystem passen sich sofort ohne Neustart an.

- **🎯 Geführter 3-Schritte-Workflow**:
  1. **Prüfung**: Automatische Überprüfung der System-Voraussetzungen (`immich-go`, Fotos-Berechtigung).
  2. **Filter & Live-Vorschau**: Medien gezielt nach Format (Fotos, Videos, Alle) und Zeitraum (Gesamte Mediathek, Jahr & Monat, Freier Datumsbereich) filtern.
  3. **Ziel wählen & Starten**: Wahl zwischen lokalem Export und Immich-Server-Upload.

- **🖼️ Schnelle Live-Medienvorschau**:
  - Horizontales Miniaturbild-Karussell der gefilterten Medien.
  - Flüssiges Caching über `PHCachingImageManager`.
  - Badges für Video-Laufzeiten und Live-Photos.
  - Exakte Zählung von Fotos und Videos.

- **📁 Lokaler Export in Ordnerstruktur (`Jahr / Monat / Tag`)**:
  - Exportiert Originale direkt auf Festplatten, externe Datenträger oder NAS-Freigaben.
  - Automatische, chronologische Hierarchie: `[Zielordner]/YYYY/MM/DD/[Dateiname]` (z. B. `2023/11/05/IMG_1234.HEIC`).
  - **Live-Photos werden zusammengehalten**: Foto und Video landen mit identischem Namen im selben Tagesordner.
  - **Kein künstlicher Batchlauf**: Kontinuierlicher, paralleler Datenstrom.
  - **Zuverlässiger Überschreibschutz**: Bereits vorhandene Dateien werden geschützt und nicht überschrieben; bei Namensgleichheiten wird kollisionsfrei nummeriert (`_1`, `_2`).

- **☁️ Immich-Server Upload**:
  - Nahtlose Integration von `immich-go`.
  - Parallele Uploads und konfigurierbare Batch-Größen.
  - Verhindert das Vollaufen des lokalen Speichers durch automatisches Bereinigen temporärer Chunks.

- **🛡️ Maximale Stabilität & Fehlertoleranz**:
  - Automatischer 3x Retry mit exponentiellem Backoff bei iCloud- oder Netzwerkunterbrechungen.
  - Unterbrechungsfrei: Pausieren, Fortsetzen und Abbrechen zu jedem Zeitpunkt.
  - Inkrementell: Speichert den Status, sodass bei einem Neustart bereits übertragene Dateien übersprungen werden.
  - Bereinigtes Protokollfenster zur Vermeidung von Speicherlecks.

- **❓ Integriertes Hilfesystem**:
  - Direkt in der App über das Menü oder den `?`-Button erreichbar.
  - Ausführliche Erklärungen zu Schnellstart, NAS-Sicherung, API-Key-Erstellung und Fehlerbehebung.

---

## 🚀 Installation & Download

Laden Sie einfach das fertige Installationspaket herunter:

👉 **[Aktuelle Version herunterladen (Releases)](https://github.com/IcmpConnect/immich-go-icloud-uploader/releases)**

1. `ImmichGoUploader.dmg` öffnen.
2. `ImmichGoUploader` in den Ordner **Programme** ziehen.
3. App starten und beim ersten Aufruf den Zugriff auf die Fotos-Mediathek bestätigen.

---

## 🛠️ Aus Quellcode bauen

### Voraussetzungen
- macOS 14.0 (Sonoma) oder neuer
- Xcode 15+ oder Xcode Command Line Tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build & Paketierung
Klonen Sie das Repository und führen Sie das automatische Verpackungsskript aus:

```bash
git clone https://github.com/IcmpConnect/immich-go-icloud-uploader.git
cd immich-go-icloud-uploader
./package.sh
```

Das Skript generiert das Xcode-Projekt, baut die App in der Release-Konfiguration und erstellt im Projektordner:
- `ImmichGoUploader.dmg` (Installations-Image)
- `ImmichGoUploader.zip` (Portables Archiv)

---

## 📄 Lizenz

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert – siehe die Datei [LICENSE](LICENSE) für Details.

---

## 🤝 Danksagung
Besonderer Dank gilt dem Team von [Immich](https://immich.app) sowie den Entwicklern von [immich-go](https://github.com/simulot/immich-go) für ihre großartige Arbeit an selbstgehostetem Fotomanagement.
