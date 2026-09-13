# 📸 ImmichGo iCloud Uploader (macOS)

Eine native, moderne macOS-App (SwiftUI) zum **Filtern**, **Vorschauen**, **lokalen Sichern** und **Hochladen** von Apple Fotos & iCloud-Medien auf eine selbstgehostete [Immich](https://immich.app)-Instanz oder auf beliebige lokale Datenträger (Festplatte, USB, NAS).

---

## ✨ Highlights & Funktionen

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
