import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .defaultLanguage
    @State private var selectedTopic: HelpTopic = .quickstart
    
    enum HelpTopic: String, CaseIterable, Identifiable {
        case quickstart = "quickstart"
        case localExport = "localExport"
        case immichSetup = "immichSetup"
        case filtering = "filtering"
        case troubleshooting = "troubleshooting"
        
        var id: String { rawValue }
        
        func title(for lang: AppLanguage) -> String {
            switch self {
            case .quickstart: return lang == .de ? "Schnellstart" : "Quick Start"
            case .localExport: return lang == .de ? "iCloud lokal sichern" : "Backup iCloud Locally"
            case .immichSetup: return lang == .de ? "Immich-Server verbinden" : "Connect Immich Server"
            case .filtering: return lang == .de ? "Filter & Zeiträume" : "Filters & Date Ranges"
            case .troubleshooting: return lang == .de ? "Fehlerbehebung & Tipps" : "Troubleshooting & Tips"
            }
        }
        
        var icon: String {
            switch self {
            case .quickstart: return "bolt.fill"
            case .localExport: return "externaldrive.fill"
            case .immichSetup: return "server.rack"
            case .filtering: return "line.3.horizontal.decrease.circle"
            case .troubleshooting: return "wrench.and.screwdriver"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(HelpTopic.allCases, selection: $selectedTopic) { topic in
                NavigationLink(value: topic) {
                    Label(topic.title(for: appLanguage), systemImage: topic.icon)
                }
            }
            .navigationTitle(L10n.topics(appLanguage))
            .frame(minWidth: 220)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topicContent(for: selectedTopic)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(selectedTopic.title(for: appLanguage))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.close(appLanguage)) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    @ViewBuilder
    private func topicContent(for topic: HelpTopic) -> some View {
        if appLanguage == .de {
            germanContent(for: topic)
        } else {
            englishContent(for: topic)
        }
    }
    
    // MARK: - German Content
    @ViewBuilder
    private func germanContent(for topic: HelpTopic) -> some View {
        switch topic {
        case .quickstart:
            Group {
                Text("Willkommen beim Immich Go iCloud Uploader!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Die App führt dich in drei einfachen Schritten durch den Prozess:")
                
                VStack(alignment: .leading, spacing: 12) {
                    StepRow(number: "1", title: "Medien filtern", description: "Wähle aus, welche Medien verarbeitet werden sollen: Alle Medien, nur Fotos oder nur Videos. Du kannst den Zeitraum auf die gesamte Mediathek, einen bestimmten Monat (z.B. November 2022) oder ein exaktes Datumsintervall einschränken. Eine Live-Vorschau zeigt dir direkt die gefundenen Bilder an.")
                    StepRow(number: "2", title: "Ziel auswählen", description: "Entscheide, wohin deine Medien kopiert werden sollen: Entweder direkt in einen lokalen Ordner (z.B. auf einer externen Festplatte oder einem NAS) ODER auf deinen Immich-Server.")
                    StepRow(number: "3", title: "Vorgang starten", description: "Ein Klick auf den Start-Button startet den parallelen Download der Originale aus der iCloud mit automatischem Fehlerschutz und Fortschrittsanzeige.")
                }
            }
            
        case .localExport:
            Group {
                Text("iCloud-Fotos in einen lokalen Ordner herunterladen")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Mit dieser Funktion kannst du deine vollständigen Originale (inklusive hochauflösenden Videos und Live-Photos) aus der Apple iCloud auf deine Festplatte, eine externe USB-Festplatte oder ein NAS exportieren.")
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureBullet(title: "Kein Server erforderlich", text: "Für den lokalen Export wird weder ein Immich-Server noch das Tool 'immich-go' benötigt.")
                    FeatureBullet(title: "Automatische Ordnerstruktur", text: "Alle Dateien werden sauber in Unterordnern nach 'Jahr/Monat/Tag' (z.B. 2023/11/05/) abgelegt.")
                    FeatureBullet(title: "Live-Photos bleiben erhalten", text: "Sowohl das Standbild als auch das verknüpfte Video (.mov) werden zusammen in voller Qualität im selben Tagesordner gesichert.")
                    FeatureBullet(title: "Schutz vor Überschreiben", text: "Vorhandene Dateien werden geschützt. Bei Namensdopplungen nummeriert das Programm automatisch durch (_1, _2).")
                    FeatureBullet(title: "Fortsetzen möglich", text: "Bereits exportierte Dateien werden vermerkt. Brichst du ab und startest später erneut, werden nur noch fehlende Dateien geladen.")
                }
            }
            
        case .immichSetup:
            Group {
                Text("Verbindung zum Immich-Server")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Um Fotos direkt in deine selbst gehostete Immich-Instanz zu laden, benötigst du:")
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureBullet(title: "Server IP / Adresse", text: "Die Adresse deines Servers, z.B. 'http://192.168.178.93' oder eine HTTPS-Domain (z.B. 'https://immich.mein-netzwerk.de'). Das 'http://' wird bei Bedarf automatisch ergänzt.")
                    FeatureBullet(title: "Port", text: "Der Standard-Port von Immich ist '2283'. Bei HTTPS-Verbindungen (Reverse Proxy) wird meist Port '443' genutzt.")
                    FeatureBullet(title: "API-Key generieren", text: "Öffne die Immich-Weboberfläche im Browser > Klicke oben rechts auf dein Profilbild > 'Account Settings' > 'API Keys' > 'New API Key'. Kopiere den Schlüssel und füge ihn in das Feld ein.")
                    FeatureBullet(title: "immich-go CLI", text: "Wird beim ersten Start automatisch geprüft. Falls es fehlt, kann es mit einem Klick über Homebrew installiert werden.")
                }
            }
            
        case .filtering:
            Group {
                Text("Filter & Zeiträume gezielt nutzen")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Große iCloud-Mediatheken mit zehntausenden Fotos lassen sich am besten schrittweise sichern:")
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureBullet(title: "Monat & Jahr", text: "Ideal für eine geordnete Migration: Wähle z.B. 'November 2022', um gezielt alle Aufnahmen dieses Monats zu sichern.")
                    FeatureBullet(title: "Nur Videos", text: "Videos verbrauchen den meisten Speicherplatz. Mit dem Filter 'Nur Videos' kannst du zuerst die großen Videodateien sichern.")
                    FeatureBullet(title: "Live-Zähler", text: "Sobald du einen Filter veränderst, zeigt dir die App sofort an, wie viele Fotos und Videos darauf zutreffen.")
                }
            }
            
        case .troubleshooting:
            Group {
                Text("Tipps & Fehlerbehebung")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureBullet(title: "Server-Timeouts vermeiden", text: "Wenn dein Immich-Server unter hoher Last langsamer wird, reduziere die 'Parallelen Downloads' im Formular auf 2 oder 3. Das schont die Prozessorleistung deines Servers.")
                    FeatureBullet(title: "Automatische Wiederholung (Retry)", text: "Bei kurzen WLAN- oder Internetabbrüchen probiert die App den Download bzw. Upload bis zu 3-mal automatisch erneut, bevor ein Element übersprungen wird.")
                    FeatureBullet(title: "Verlauf zurücksetzen", text: "Möchtest du Medien erneut importieren oder exportieren, klicke im Bereich 'Erweiterte Einstellungen' auf 'Zurücksetzen'.")
                    FeatureBullet(title: "Berechtigungen in macOS", text: "Beim ersten Start fragt macOS nach dem Zugriff auf 'Fotos'. Dieser muss mit 'Voller Zugriff' oder 'Zulassen' bestätigt werden.")
                }
            }
        }
    }
    
    // MARK: - English Content
    @ViewBuilder
    private func englishContent(for topic: HelpTopic) -> some View {
        switch topic {
        case .quickstart:
            Group {
                Text("Welcome to Immich Go iCloud Uploader!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("The app guides you through the process in three simple steps:")
                
                VStack(alignment: .leading, spacing: 12) {
                    StepRow(number: "1", title: "Filter Media", description: "Choose which media to process: All Media, Photos only, or Videos only. You can restrict the range to your entire library, a specific month (e.g. November 2022), or an exact date range. A live preview immediately displays the found media.")
                    StepRow(number: "2", title: "Select Destination", description: "Decide where to transfer your media: Either directly into a local folder (e.g. on an external hard drive, USB drive, or NAS) OR upload to your Immich server.")
                    StepRow(number: "3", title: "Start Transfer", description: "Click the start button to download full-resolution originals from iCloud with automatic retry protection and live progress feedback.")
                }
            }
            
        case .localExport:
            Group {
                Text("Export iCloud Photos to a Local Folder")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This feature allows you to export complete original media (including high-resolution videos and Live Photos) from Apple iCloud onto your internal disk, an external USB hard drive, or a NAS share.")
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureBullet(title: "No Server Required", text: "Local export operates completely independently without requiring an Immich server or the 'immich-go' command-line tool.")
                    FeatureBullet(title: "Automatic Folder Hierarchy", text: "All files are organized into structured subfolders by 'Year/Month/Day' (e.g. 2023/11/05/).")
                    FeatureBullet(title: "Live Photos Preserved", text: "Both the still picture and the paired motion video (.mov) are saved together in full quality in the same day folder.")
                    FeatureBullet(title: "Overwrite Protection", text: "Existing files on disk are protected. If multiple photos share identical names, the app automatically numbers them (_1, _2).")
                    FeatureBullet(title: "Resume Support", text: "Exported assets are tracked. If you pause or cancel and restart later, already exported files are immediately skipped.")
                }
            }
            
        case .immichSetup:
            Group {
                Text("Connecting to Immich Server")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("To upload media directly to your self-hosted Immich instance, you will need:")
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureBullet(title: "Server IP / Address", text: "Your server address, e.g. 'http://192.168.1.100' or an HTTPS domain (e.g. 'https://immich.myhome.net'). The 'http://' prefix is automatically added if omitted.")
                    FeatureBullet(title: "Port", text: "The default Immich port is '2283'. For reverse-proxy HTTPS setups, port '443' is typically used.")
                    FeatureBullet(title: "Generate API Key", text: "Open the Immich web interface in your browser > Click your profile icon at the top right > 'Account Settings' > 'API Keys' > 'New API Key'. Copy the key and paste it into the field.")
                    FeatureBullet(title: "immich-go CLI", text: "Checked automatically on launch. If missing, it can be installed with a single click via Homebrew.")
                }
            }
            
        case .filtering:
            Group {
                Text("Using Filters & Date Ranges Effectively")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Large iCloud libraries with tens of thousands of items are easiest to migrate incrementally:")
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureBullet(title: "Month & Year", text: "Great for structured migrations: Choose e.g. 'November 2022' to backup all shots from that month in a clean batch.")
                    FeatureBullet(title: "Videos Only", text: "Videos take up the most storage. Use the 'Videos only' filter to verify and migrate large files first.")
                    FeatureBullet(title: "Live Counter", text: "Whenever you change a filter, the counter updates instantly with the exact count of photos and videos.")
                }
            }
            
        case .troubleshooting:
            Group {
                Text("Tips & Troubleshooting")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureBullet(title: "Avoid Server Overload", text: "If your Immich server slows down under load, reduce 'Parallel Downloads' in Advanced Settings to 2 or 3 to ease server CPU load.")
                    FeatureBullet(title: "Automatic Retries", text: "During temporary Wi-Fi or internet interruptions, the app retries up to 3 times with exponential backoff before skipping an asset.")
                    FeatureBullet(title: "Reset History", text: "To re-export or re-upload media, click 'Reset' in the 'Advanced Settings & History' section.")
                    FeatureBullet(title: "macOS Photos Permission", text: "On first launch, macOS requests permission to access 'Photos'. Make sure to grant 'Full Access'.")
                }
            }
        }
    }
}

private struct StepRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)
                Text(number)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct FeatureBullet: View {
    let title: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text(title)
                    .fontWeight(.semibold)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 22)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}
