import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic: HelpTopic = .quickstart
    
    enum HelpTopic: String, CaseIterable, Identifiable {
        case quickstart = "Schnellstart"
        case localExport = "iCloud lokal sichern"
        case immichSetup = "Immich-Server verbinden"
        case filtering = "Filter & Zeiträume"
        case troubleshooting = "Fehlerbehebung & Tipps"
        
        var id: String { rawValue }
        
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
                    Label(topic.rawValue, systemImage: topic.icon)
                }
            }
            .navigationTitle("Themen")
            .frame(minWidth: 200)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topicContent(for: selectedTopic)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(selectedTopic.rawValue)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 680, minHeight: 480)
    }
    
    @ViewBuilder
    private func topicContent(for topic: HelpTopic) -> some View {
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
                    FeatureBullet(title: "Live-Photos bleiben erhalten", text: "Sowohl das Standbild als auch das verknüpfte Video (.mov) werden zusammen in voller Qualität gesichert.")
                    FeatureBullet(title: "Schutz vor Überschreiben", text: "Sollten mehrere Fotos denselben Dateinamen tragen (z.B. IMG_0001.JPG), nummeriert das Programm diese automatisch durch.")
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
                    FeatureBullet(title: "Verlauf zurücksetzen", text: "Möchtest du Medien erneut importieren oder exportieren, klicke im Bereich 'Verlauf & Cache' auf 'Upload-Verlauf zurücksetzen' bzw. 'Export-Verlauf zurücksetzen'.")
                    FeatureBullet(title: "Berechtigungen in macOS", text: "Beim ersten Start fragt macOS nach dem Zugriff auf 'Fotos'. Dieser muss mit 'Voller Zugriff' oder 'Zulassen' bestätigt werden.")
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
