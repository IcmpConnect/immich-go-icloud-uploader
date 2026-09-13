import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var uploadManager = UploadManager()
    
    // Sprache & Einstellungen
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .defaultLanguage
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
    
    private var months: [String] {
        if appLanguage == .de {
            return [
                "Januar", "Februar", "März", "April", "Mai", "Juni",
                "Juli", "August", "September", "Oktober", "November", "Dezember"
            ]
        } else {
            return [
                "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"
            ]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header mit Sprachauswahl & Hilfe-Button
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
        .frame(minWidth: 720, minHeight: 780)
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
                Text(appLanguage == .de 
                     ? "Fotos aus iCloud filtern, sichern & zu Immich übertragen" 
                     : "Filter, export & upload iCloud photos to Immich or local disk")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sprachumschalter (🇩🇪 / 🇬🇧)
            Picker("", selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            
            // Hilfe-Button
            Button(action: { showingHelp = true }) {
                Label(L10n.helpAndGuide(appLanguage), systemImage: "questionmark.circle")
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
                    Text(appLanguage == .de 
                         ? "System-Check: Prüfe Abhängigkeiten (immich-go)..." 
                         : "System Check: Verifying dependencies (immich-go)...")
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
            case .missingImmichGo(let brewAvailable):
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(appLanguage == .de 
                             ? "System-Check: immich-go fehlt" 
                             : "System Check: immich-go missing")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Text(brewAvailable
                         ? (appLanguage == .de ? "Homebrew ist vorhanden, aber 'immich-go' fehlt für den Server-Upload." : "Homebrew is available, but 'immich-go' is missing for server upload.")
                         : (appLanguage == .de ? "Homebrew und 'immich-go' wurden nicht gefunden." : "Homebrew and 'immich-go' were not found."))
                        .font(.caption)
                    
                    HStack(spacing: 10) {
                        if brewAvailable {
                            Button(appLanguage == .de ? "immich-go über Homebrew installieren" : "Install immich-go via Homebrew") {
                                uploadManager.installImmichGo()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        } else {
                            Button(appLanguage == .de ? "Homebrew im Terminal installieren" : "Install Homebrew in Terminal") {
                                uploadManager.installHomebrew()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button(appLanguage == .de ? "Erneut prüfen" : "Check Again") {
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
                    Text(appLanguage == .de ? "Installiere immich-go via Homebrew..." : "Installing immich-go via Homebrew...").font(.subheadline)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
            case .installationFailed(let errorMsg):
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
                        Text(L10n.installationFailed(appLanguage)).font(.headline).foregroundColor(.red)
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
        GroupBox(label: Label(L10n.step1Title(appLanguage), systemImage: "line.3.horizontal.decrease.circle").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                // Medientyp & Zeitraum
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.mediaTypeLabel(appLanguage)).font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $uploadManager.mediaTypeFilter) {
                            ForEach(MediaTypeFilter.allCases) { type in
                                Text(type.title(for: appLanguage)).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(uploadManager.isUploading)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.dateRangeLabel(appLanguage)).font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $uploadManager.dateFilterMode) {
                            ForEach(DateFilterMode.allCases) { mode in
                                Text(mode.title(for: appLanguage)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(uploadManager.isUploading)
                    }
                }
                
                // Optionale Zeit-Details
                if uploadManager.dateFilterMode == .monthYear {
                    HStack(spacing: 16) {
                        Text(L10n.monthAndYearLabel(appLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker(L10n.monthLabel(appLanguage), selection: $uploadManager.selectedMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(months[m - 1]).tag(m)
                            }
                        }
                        .frame(width: 130)
                        .disabled(uploadManager.isUploading)
                        
                        Stepper(L10n.yearLabel(appLanguage, year: uploadManager.selectedYear), value: $uploadManager.selectedYear, in: 2000...Calendar.current.component(.year, from: Date()))
                            .disabled(uploadManager.isUploading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                } else if uploadManager.dateFilterMode == .customRange {
                    HStack(spacing: 16) {
                        DatePicker(L10n.fromDateLabel(appLanguage), selection: $uploadManager.filterStartDate, displayedComponents: .date)
                            .disabled(uploadManager.isUploading)
                        
                        DatePicker(L10n.toDateLabel(appLanguage), selection: $uploadManager.filterEndDate, displayedComponents: .date)
                            .disabled(uploadManager.isUploading)
                    }
                    .padding(.vertical, 2)
                }
                
                Divider()
                
                // Zähler & Live-Vorschau
                HStack {
                    if uploadManager.isLoadingPreview {
                        ProgressView().controlSize(.small)
                        Text(L10n.loadingLibrary(appLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        let countInfo = L10n.mediaFoundCount(appLanguage, total: uploadManager.filteredAssets.count, photos: uploadManager.photoCount, videos: uploadManager.videoCount)
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                            Text(countInfo.main)
                                .font(.headline)
                            Text(countInfo.sub)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { uploadManager.refreshFilteredAssets() }) {
                        Label(L10n.refresh(appLanguage), systemImage: "arrow.clockwise")
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
                            Text(L10n.noMediaFound(appLanguage))
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
                                let more = L10n.moreItems(appLanguage, count: uploadManager.filteredAssets.count - 25)
                                VStack {
                                    Text(more.number)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(more.text)
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
        GroupBox(label: Label(L10n.step2Title(appLanguage), systemImage: "arrow.right.circle").font(.headline)) {
            VStack(alignment: .leading, spacing: 14) {
                Picker(L10n.targetDestinationQuestion(appLanguage), selection: $targetDestination) {
                    ForEach(TargetDestination.allCases) { dest in
                        Text(dest.title(for: appLanguage)).tag(dest)
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
                                Text(L10n.targetFolderOnDisk(appLanguage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let folder = exportDestinationFolder {
                                    Text(folder.path)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } else {
                                    Text(L10n.noTargetFolderSelected(appLanguage))
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Spacer()
                            
                            Button(L10n.chooseTargetFolder(appLanguage)) {
                                selectLocalDestinationFolder()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(uploadManager.isUploading)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.blue)
                            Text(L10n.folderHierarchyNotice(appLanguage))
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
                            Text(L10n.serverIPLabel(appLanguage))
                                .frame(width: 80, alignment: .leading)
                            TextField("z.B. http://192.168.1.100", text: $serverIP)
                                .textFieldStyle(.roundedBorder)
                            
                            Text(L10n.serverPortLabel(appLanguage))
                                .frame(width: 40, alignment: .leading)
                            TextField("2283", text: $serverPort)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text(L10n.apiKeyLabel(appLanguage))
                                .frame(width: 80, alignment: .leading)
                            SecureField(L10n.apiKeyPlaceholder(appLanguage), text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Spacer()
                            Button(L10n.uploadArbitraryFolder(appLanguage)) {
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
                            Text(L10n.parallelDownloads(appLanguage))
                            Text("\(concurrentDownloads)").fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Stepper(value: $batchSize, in: 10...200, step: 10) {
                        HStack {
                            Text(targetDestination == .localFolder ? L10n.batchSizeImmichOnly(appLanguage) : L10n.batchSize(appLanguage))
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
                        Text(L10n.uploadHistory(appLanguage))
                            .font(.caption)
                        Text(L10n.itemsTracked(appLanguage, count: uploadManager.uploadedCount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(L10n.reset(appLanguage)) {
                            uploadManager.resetUploadedAssets()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(uploadManager.isUploading)
                    }
                    
                    Divider().frame(height: 20)
                    
                    HStack {
                        Text(L10n.exportHistory(appLanguage))
                            .font(.caption)
                        Text(L10n.itemsTracked(appLanguage, count: uploadManager.exportedCount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(L10n.reset(appLanguage)) {
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
            Label(L10n.advancedSettingsTitle(appLanguage), systemImage: "gearshape")
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
                        Label(uploadManager.isPaused ? L10n.resume(appLanguage) : L10n.pause(appLanguage), systemImage: uploadManager.isPaused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        uploadManager.isUploading = false
                        uploadManager.isPaused = false
                        uploadManager.statusMessage = L10n.cancel(appLanguage)
                    }) {
                        Label(L10n.cancel(appLanguage), systemImage: "xmark.circle")
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
            return L10n.actionButtonExport(appLanguage, count: count)
        } else {
            return L10n.actionButtonUpload(appLanguage, count: count)
        }
    }
    
    private var canStartProcess: Bool {
        if uploadManager.isUploading { return false }
        if uploadManager.filteredAssets.isEmpty { return false }
        
        if targetDestination == .localFolder {
            return true
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
                Text(L10n.statusLabel(appLanguage))
                    .fontWeight(.semibold)
                Text(uploadManager.statusMessage.isEmpty ? L10n.readyStatus(appLanguage) : uploadManager.statusMessage)
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
        panel.title = appLanguage == .de ? "Zielordner für Foto-Download wählen" : "Select Target Folder for Photo Download"
        panel.prompt = appLanguage == .de ? "Als Zielordner wählen" : "Select as Destination"
        
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
        panel.title = appLanguage == .de ? "Ordner für Upload wählen" : "Select Folder for Upload"
        panel.prompt = appLanguage == .de ? "Hochladen" : "Upload"
        
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
