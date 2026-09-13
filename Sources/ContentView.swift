import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var uploadManager = UploadManager()
    
    // Einstellungen
    @AppStorage("serverIP") private var serverIP: String = ""
    @AppStorage("serverPort") private var serverPort: String = "2283"
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("concurrentDownloads") private var concurrentDownloads: Int = 3
    @AppStorage("batchSize") private var batchSize: Int = 50
    
    // Workflow State
    @State private var targetDestination: TargetDestination = .localFolder
    @State private var exportDestinationFolder: URL? = nil
    @State private var showingHelp: Bool = false
    @State private var isAdvancedSettingsExpanded: Bool = false
    
    private let months = [
        "Januar", "Februar", "März", "April", "Mai", "Juni",
        "Juli", "August", "September", "Oktober", "November", "Dezember"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header mit Hilfe-Button
                headerView
                
                // System-Check Banner (falls Immich gewählt und etwas fehlt)
                systemCheckBanner
                
                // Schritt 1: Medien filtern & Vorschau
                step1FilterAndPreviewView
                
                // Schritt 2: Ziel auswählen
                step2TargetSelectionView
                
                // Erweiterte Einstellungen & Cache (Aufklappbar)
                advancedSettingsView
                
                // Schritt 3: Aktion & Steuerung
                step3ActionView
                
                // Status & Log-Konsole
                statusAndConsoleView
            }
            .padding(18)
        }
        .frame(minWidth: 720, minHeight: 760)
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Image(systemName: "photo.stack.fill")
                .font(.title)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Immich Go iCloud Uploader")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Fotos aus iCloud herunterladen, filtern & zu Immich übertragen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingHelp = true }) {
                Label("Hilfe & Anleitung", systemImage: "questionmark.circle")
            }
            .buttonStyle(.bordered)
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - System Check
    @ViewBuilder
    private var systemCheckBanner: some View {
        if targetDestination == .immichServer {
            switch uploadManager.dependencyStatus {
            case .checking:
                HStack {
                    ProgressView().controlSize(.small)
                    Text("System-Check: Prüfe Abhängigkeiten (immich-go)...")
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
            case .missingImmichGo(let brewAvailable):
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text("System-Check: immich-go fehlt").font(.headline).foregroundColor(.orange)
                    }
                    Text(brewAvailable
                         ? "Homebrew ist vorhanden, aber 'immich-go' fehlt für den Server-Upload."
                         : "Homebrew und 'immich-go' wurden nicht gefunden.")
                        .font(.caption)
                    
                    HStack(spacing: 10) {
                        if brewAvailable {
                            Button("immich-go über Homebrew installieren") {
                                uploadManager.installImmichGo()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        } else {
                            Button("Homebrew im Terminal installieren") {
                                uploadManager.installHomebrew()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button("Erneut prüfen") {
                                uploadManager.checkDependencies()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
            case .installing:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Installiere immich-go via Homebrew...").font(.subheadline)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
            case .installationFailed(let errorMsg):
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                        Text("Installation fehlgeschlagen").font(.headline).foregroundColor(.red)
                    }
                    Text(errorMsg).font(.caption)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                
            case .ready:
                EmptyView()
            }
        }
    }
    
    // MARK: - Schritt 1: Filter & Vorschau
    private var step1FilterAndPreviewView: some View {
        GroupBox(label: Label("1. Medien filtern & Vorschau", systemImage: "line.3.horizontal.decrease.circle").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                // Medientyp & Zeitraum
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Medientyp:").font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $uploadManager.mediaTypeFilter) {
                            ForEach(MediaTypeFilter.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(uploadManager.isUploading)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zeitraum:").font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $uploadManager.dateFilterMode) {
                            ForEach(DateFilterMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(uploadManager.isUploading)
                    }
                }
                
                // Optionale Zeit-Details
                if uploadManager.dateFilterMode == .monthYear {
                    HStack(spacing: 16) {
                        Text("Monat & Jahr:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Monat", selection: $uploadManager.selectedMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(months[m - 1]).tag(m)
                            }
                        }
                        .frame(width: 130)
                        .disabled(uploadManager.isUploading)
                        
                        Stepper("Jahr: \(uploadManager.selectedYear)", value: $uploadManager.selectedYear, in: 2000...Calendar.current.component(.year, from: Date()))
                            .disabled(uploadManager.isUploading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                } else if uploadManager.dateFilterMode == .customRange {
                    HStack(spacing: 16) {
                        DatePicker("Von:", selection: $uploadManager.filterStartDate, displayedComponents: .date)
                            .disabled(uploadManager.isUploading)
                        
                        DatePicker("Bis:", selection: $uploadManager.filterEndDate, displayedComponents: .date)
                            .disabled(uploadManager.isUploading)
                    }
                    .padding(.vertical, 2)
                }
                
                Divider()
                
                // Zähler & Live-Vorschau
                HStack {
                    if uploadManager.isLoadingPreview {
                        ProgressView().controlSize(.small)
                        Text("Lade Mediathek...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                            Text("\(uploadManager.filteredAssets.count) Medien gefunden")
                                .font(.headline)
                            Text("(\(uploadManager.photoCount) Fotos, \(uploadManager.videoCount) Videos)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { uploadManager.refreshFilteredAssets() }) {
                        Label("Aktualisieren", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .disabled(uploadManager.isUploading)
                }
                
                // Thumbnail Galerie
                if uploadManager.filteredAssets.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("Keine Medien für die gewählten Filter gefunden.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 14)
                        Spacer()
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(uploadManager.filteredAssets.prefix(25), id: \.localIdentifier) { asset in
                                MediaThumbnailView(asset: asset)
                            }
                            if uploadManager.filteredAssets.count > 25 {
                                VStack {
                                    Text("+\(uploadManager.filteredAssets.count - 25)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("weitere")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 74, height: 74)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(height: 80)
                }
            }
            .padding(8)
        }
    }
    
    // MARK: - Schritt 2: Ziel auswählen
    private var step2TargetSelectionView: some View {
        GroupBox(label: Label("2. Ziel auswählen", systemImage: "arrow.right.circle").font(.headline)) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Wohin soll kopiert werden?", selection: $targetDestination) {
                    ForEach(TargetDestination.allCases) { dest in
                        Text(dest.rawValue).tag(dest)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(uploadManager.isUploading)
                
                if targetDestination == .localFolder {
                    // Lokaler Ordner Export
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zielordner auf der Festplatte:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let folder = exportDestinationFolder {
                                    Text(folder.path)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } else {
                                    Text("Noch kein Zielordner ausgewählt")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Zielordner wählen...") {
                                selectLocalDestinationFolder()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(uploadManager.isUploading)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.blue)
                            Text("Ablage erfolgt automatisch in Unterordnern Jahr/Monat/Tag (z. B. 2023/11/05/). Vorhandene Dateien werden geschützt und nicht überschrieben.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(8)
                } else {
                    // Immich Server Upload
                    VStack(spacing: 10) {
                        HStack {
                            Text("Server IP:")
                                .frame(width: 80, alignment: .leading)
                            TextField("z.B. http://192.168.1.100", text: $serverIP)
                                .textFieldStyle(.roundedBorder)
                            
                            Text("Port:")
                                .frame(width: 40, alignment: .leading)
                            TextField("2283", text: $serverPort)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("API Key:")
                                .frame(width: 80, alignment: .leading)
                            SecureField("Dein Immich API-Schlüssel", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Spacer()
                            Button("Oder: Beliebigen bestehenden Ordner zu Immich hochladen...") {
                                selectAndUploadArbitraryFolder()
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .disabled(uploadManager.isUploading || uploadManager.dependencyStatus != .ready || serverIP.isEmpty || apiKey.isEmpty)
                        }
                    }
                    .disabled(uploadManager.isUploading)
                }
            }
            .padding(8)
        }
    }
    
    // MARK: - Erweiterte Einstellungen
    private var advancedSettingsView: some View {
        DisclosureGroup(isExpanded: $isAdvancedSettingsExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 24) {
                    Stepper(value: $concurrentDownloads, in: 1...10) {
                        HStack {
                            Text("Parallele Downloads:")
                            Text("\(concurrentDownloads)").fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Stepper(value: $batchSize, in: 10...200, step: 10) {
                        HStack {
                            Text(targetDestination == .localFolder ? "Batch (nur Immich):" : "Batch-Größe:")
                            Text("\(batchSize)").fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(targetDestination == .localFolder)
                    .opacity(targetDestination == .localFolder ? 0.5 : 1.0)
                }
                
                Divider()
                
                HStack(spacing: 18) {
                    HStack {
                        Text("Upload-Verlauf:")
                            .font(.caption)
                        Text("\(uploadManager.uploadedCount) erfasst")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Zurücksetzen") {
                            uploadManager.resetUploadedAssets()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(uploadManager.isUploading)
                    }
                    
                    Divider().frame(height: 20)
                    
                    HStack {
                        Text("Export-Verlauf:")
                            .font(.caption)
                        Text("\(uploadManager.exportedCount) erfasst")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Zurücksetzen") {
                            uploadManager.resetExportedAssets()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(uploadManager.isUploading)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Erweiterte Einstellungen & Verlauf", systemImage: "gearshape")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Schritt 3: Aktion & Steuerung
    private var step3ActionView: some View {
        VStack(spacing: 12) {
            if uploadManager.isUploading {
                HStack(spacing: 16) {
                    Button(action: { uploadManager.togglePause() }) {
                        Label(uploadManager.isPaused ? "Fortsetzen" : "Pausieren", systemImage: uploadManager.isPaused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        uploadManager.isUploading = false
                        uploadManager.isPaused = false
                        uploadManager.statusMessage = "Abgebrochen"
                    }) {
                        Label("Abbrechen", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .foregroundColor(.red)
                }
            } else {
                Button(action: startProcess) {
                    HStack {
                        Image(systemName: targetDestination == .localFolder ? "square.and.arrow.down.fill" : "arrow.up.circle.fill")
                        Text(actionButtonTitle)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(targetDestination == .localFolder ? .blue : .purple)
                .controlSize(.large)
                .disabled(!canStartProcess)
            }
        }
    }
    
    private var actionButtonTitle: String {
        let count = uploadManager.filteredAssets.count
        if targetDestination == .localFolder {
            return "iCloud-Fotos in lokalen Ordner exportieren (\(count) Elemente)"
        } else {
            return "Ausgewählte Medien zu Immich hochladen (\(count) Elemente)"
        }
    }
    
    private var canStartProcess: Bool {
        if uploadManager.isUploading { return false }
        if uploadManager.filteredAssets.isEmpty { return false }
        
        if targetDestination == .localFolder {
            return true // Falls noch kein Ordner gewählt wurde, öffnet der Klick den Dialog
        } else {
            return uploadManager.dependencyStatus == .ready && !serverIP.isEmpty && !apiKey.isEmpty
        }
    }
    
    private func startProcess() {
        if targetDestination == .localFolder {
            if let folder = exportDestinationFolder {
                uploadManager.startPhotoLibraryExport(
                    destinationURL: folder,
                    concurrencyLimit: concurrentDownloads
                )
            } else {
                selectLocalDestinationFolder(andStartImmediately: true)
            }
        } else {
            uploadManager.startPhotoLibraryUpload(
                serverIP: serverIP,
                serverPort: serverPort,
                apiKey: apiKey,
                concurrencyLimit: concurrentDownloads,
                batchSize: batchSize
            )
        }
    }
    
    // MARK: - Status & Konsole
    private var statusAndConsoleView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Status:")
                    .fontWeight(.semibold)
                Text(uploadManager.statusMessage)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if uploadManager.isUploading {
                    ProgressView().controlSize(.small)
                }
            }
            .font(.subheadline)
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(uploadManager.logOutput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .id("logText")
                }
                .frame(height: 200)
                .background(Color.black.opacity(0.88))
                .cornerRadius(8)
                .foregroundColor(.green)
                .onChange(of: uploadManager.logOutput) {
                    withAnimation {
                        proxy.scrollTo("logText", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Dialoge
    private func selectLocalDestinationFolder(andStartImmediately: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.title = "Zielordner für Foto-Download wählen"
        panel.prompt = "Als Zielordner wählen"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                exportDestinationFolder = url
                if andStartImmediately {
                    uploadManager.startPhotoLibraryExport(
                        destinationURL: url,
                        concurrencyLimit: concurrentDownloads
                    )
                }
            }
        }
    }
    
    private func selectAndUploadArbitraryFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Ordner für Upload wählen"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                uploadManager.startFolderUpload(
                    serverIP: serverIP,
                    serverPort: serverPort,
                    apiKey: apiKey,
                    folderPath: url.path
                )
            }
        }
    }
}
