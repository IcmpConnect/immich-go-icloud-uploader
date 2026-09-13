import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case de = "de"
    case en = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .de: return "🇩🇪 Deutsch"
        case .en: return "🇬🇧 English"
        }
    }
    
    var shortName: String {
        switch self {
        case .de: return "DE"
        case .en: return "EN"
        }
    }
    
    static var defaultLanguage: AppLanguage {
        if let lang = Locale.current.language.languageCode?.identifier, lang.hasPrefix("de") {
            return .de
        }
        return .en
    }
}

struct L10n {
    // MARK: - Toolbar & System Checks
    static func photosAccess(_ lang: AppLanguage) -> String {
        lang == .de ? "Fotos-Zugriff" : "Photos Access"
    }
    static func authorized(_ lang: AppLanguage) -> String {
        lang == .de ? "Berechtigt" : "Authorized"
    }
    static func limited(_ lang: AppLanguage) -> String {
        lang == .de ? "Eingeschränkt" : "Limited"
    }
    static func notAuthorized(_ lang: AppLanguage) -> String {
        lang == .de ? "Kein Zugriff" : "No Access"
    }
    static func serverReady(_ lang: AppLanguage) -> String {
        lang == .de ? "Server bereit" : "Server Ready"
    }
    static func serverCheck(_ lang: AppLanguage) -> String {
        lang == .de ? "Server prüfen" : "Check Server"
    }
    static func immichGoReady(_ lang: AppLanguage) -> String {
        lang == .de ? "immich-go bereit" : "immich-go Ready"
    }
    static func immichGoMissing(_ lang: AppLanguage) -> String {
        lang == .de ? "immich-go fehlt" : "immich-go Missing"
    }
    static func helpAndGuide(_ lang: AppLanguage) -> String {
        lang == .de ? "Hilfe & Anleitung" : "Help & Guide"
    }
    static func close(_ lang: AppLanguage) -> String {
        lang == .de ? "Schließen" : "Close"
    }
    static func topics(_ lang: AppLanguage) -> String {
        lang == .de ? "Themen" : "Topics"
    }
    
    // MARK: - Step 0: Dependency Checks
    static func dependencyWarningTitle(_ lang: AppLanguage) -> String {
        lang == .de ? "Voraussetzung fehlt: immich-go nicht gefunden" : "Prerequisite Missing: immich-go not found"
    }
    static func dependencyWarningLocalNote(_ lang: AppLanguage) -> String {
        lang == .de ? "(Hinweis: Für den reinen Export in einen lokalen Ordner ist immich-go nicht erforderlich)." : "(Note: immich-go is not required for exporting to a local folder)."
    }
    static func installImmichGo(_ lang: AppLanguage) -> String {
        lang == .de ? "immich-go automatisch installieren" : "Install immich-go automatically"
    }
    static func installHomebrew(_ lang: AppLanguage) -> String {
        lang == .de ? "Homebrew installieren" : "Install Homebrew"
    }
    static func checkAgain(_ lang: AppLanguage) -> String {
        lang == .de ? "Erneut prüfen" : "Check Again"
    }
    static func installingImmichGo(_ lang: AppLanguage) -> String {
        lang == .de ? "Installiere immich-go..." : "Installing immich-go..."
    }
    static func pleaseWait(_ lang: AppLanguage) -> String {
        lang == .de ? "Bitte warten, dies kann einen Moment dauern." : "Please wait, this may take a moment."
    }
    static func installationFailed(_ lang: AppLanguage) -> String {
        lang == .de ? "Installation fehlgeschlagen" : "Installation Failed"
    }
    
    // MARK: - Step 1: Filters & Preview
    static func step1Title(_ lang: AppLanguage) -> String {
        lang == .de ? "1. Medien filtern & Vorschau" : "1. Filter Media & Preview"
    }
    static func mediaTypeLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Medientyp:" : "Media Type:"
    }
    static func dateRangeLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Zeitraum:" : "Date Range:"
    }
    static func monthAndYearLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Monat & Jahr:" : "Month & Year:"
    }
    static func monthLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Monat" : "Month"
    }
    static func yearLabel(_ lang: AppLanguage, year: Int) -> String {
        lang == .de ? "Jahr: \(year)" : "Year: \(year)"
    }
    static func fromDateLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Von:" : "From:"
    }
    static func toDateLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Bis:" : "To:"
    }
    static func loadingLibrary(_ lang: AppLanguage) -> String {
        lang == .de ? "Lade Mediathek..." : "Loading library..."
    }
    static func mediaFoundCount(_ lang: AppLanguage, total: Int, photos: Int, videos: Int) -> (main: String, sub: String) {
        if lang == .de {
            return ("\(total) Medien gefunden", "(\(photos) Fotos, \(videos) Videos)")
        } else {
            return ("\(total) media items found", "(\(photos) photos, \(videos) videos)")
        }
    }
    static func refresh(_ lang: AppLanguage) -> String {
        lang == .de ? "Aktualisieren" : "Refresh"
    }
    static func noMediaFound(_ lang: AppLanguage) -> String {
        lang == .de ? "Keine Medien für die gewählten Filter gefunden." : "No media found for the selected filters."
    }
    static func moreItems(_ lang: AppLanguage, count: Int) -> (number: String, text: String) {
        return ("+\(count)", lang == .de ? "weitere" : "more")
    }
    
    // MARK: - Step 2: Destination
    static func step2Title(_ lang: AppLanguage) -> String {
        lang == .de ? "2. Ziel auswählen" : "2. Select Destination"
    }
    static func targetDestinationQuestion(_ lang: AppLanguage) -> String {
        lang == .de ? "Wohin soll kopiert werden?" : "Where should files be saved?"
    }
    static func targetFolderOnDisk(_ lang: AppLanguage) -> String {
        lang == .de ? "Zielordner auf der Festplatte:" : "Target folder on disk:"
    }
    static func noTargetFolderSelected(_ lang: AppLanguage) -> String {
        lang == .de ? "Noch kein Zielordner ausgewählt" : "No target folder selected yet"
    }
    static func chooseTargetFolder(_ lang: AppLanguage) -> String {
        lang == .de ? "Zielordner wählen..." : "Choose Target Folder..."
    }
    static func folderHierarchyNotice(_ lang: AppLanguage) -> String {
        lang == .de 
            ? "Ablage erfolgt automatisch in Unterordnern Jahr/Monat/Tag (z. B. 2023/11/05/). Vorhandene Dateien werden geschützt und nicht überschrieben." 
            : "Files are automatically organized in Year/Month/Day subfolders (e.g. 2023/11/05/). Existing files are protected and never overwritten."
    }
    static func serverIPLabel(_ lang: AppLanguage) -> String {
        "Server IP:"
    }
    static func serverPortLabel(_ lang: AppLanguage) -> String {
        "Port:"
    }
    static func apiKeyLabel(_ lang: AppLanguage) -> String {
        "API Key:"
    }
    static func apiKeyPlaceholder(_ lang: AppLanguage) -> String {
        lang == .de ? "Dein Immich API-Schlüssel" : "Your Immich API Key"
    }
    static func uploadArbitraryFolder(_ lang: AppLanguage) -> String {
        lang == .de ? "Oder: Beliebigen bestehenden Ordner zu Immich hochladen..." : "Or: Upload any existing folder to Immich..."
    }
    
    // MARK: - Advanced Settings
    static func advancedSettingsTitle(_ lang: AppLanguage) -> String {
        lang == .de ? "Erweiterte Einstellungen & Verlauf" : "Advanced Settings & History"
    }
    static func parallelDownloads(_ lang: AppLanguage) -> String {
        lang == .de ? "Parallele Downloads:" : "Parallel Downloads:"
    }
    static func batchSizeImmichOnly(_ lang: AppLanguage) -> String {
        lang == .de ? "Batch (nur Immich):" : "Batch (Immich only):"
    }
    static func batchSize(_ lang: AppLanguage) -> String {
        lang == .de ? "Batch-Größe:" : "Batch Size:"
    }
    static func uploadHistory(_ lang: AppLanguage) -> String {
        lang == .de ? "Upload-Verlauf:" : "Upload History:"
    }
    static func exportHistory(_ lang: AppLanguage) -> String {
        lang == .de ? "Export-Verlauf:" : "Export History:"
    }
    static func itemsTracked(_ lang: AppLanguage, count: Int) -> String {
        lang == .de ? "\(count) erfasst" : "\(count) tracked"
    }
    static func reset(_ lang: AppLanguage) -> String {
        lang == .de ? "Zurücksetzen" : "Reset"
    }
    
    // MARK: - Step 3: Action & Controls
    static func pause(_ lang: AppLanguage) -> String {
        lang == .de ? "Pausieren" : "Pause"
    }
    static func resume(_ lang: AppLanguage) -> String {
        lang == .de ? "Fortsetzen" : "Resume"
    }
    static func cancel(_ lang: AppLanguage) -> String {
        lang == .de ? "Abbrechen" : "Cancel"
    }
    static func actionButtonExport(_ lang: AppLanguage, count: Int) -> String {
        lang == .de ? "iCloud-Fotos in lokalen Ordner exportieren (\(count) Elemente)" : "Export iCloud Photos to Local Folder (\(count) items)"
    }
    static func actionButtonUpload(_ lang: AppLanguage, count: Int) -> String {
        lang == .de ? "Ausgewählte Medien zu Immich hochladen (\(count) Elemente)" : "Upload Selected Media to Immich (\(count) items)"
    }
    static func statusLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Status:" : "Status:"
    }
    static func consoleLabel(_ lang: AppLanguage) -> String {
        lang == .de ? "Protokoll" : "Log Output"
    }
    static func copyLog(_ lang: AppLanguage) -> String {
        lang == .de ? "Kopieren" : "Copy"
    }
    static func clearLog(_ lang: AppLanguage) -> String {
        lang == .de ? "Löschen" : "Clear"
    }
    static func readyStatus(_ lang: AppLanguage) -> String {
        lang == .de ? "Bereit" : "Ready"
    }
}
