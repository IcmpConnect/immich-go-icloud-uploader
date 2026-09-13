import Foundation
import Photos

@MainActor
class UploadManager: ObservableObject {
    @Published var isUploading: Bool = false
    @Published var isPaused: Bool = false
    @Published var statusMessage: String = "Bereit"
    @Published var logOutput: String = "" {
        didSet {
            let maxLogCharacters = 25_000
            if logOutput.count > maxLogCharacters {
                let keepCount = 20_000
                let index = logOutput.index(logOutput.endIndex, offsetBy: -keepCount)
                logOutput = "[... Verlauf gekürzt ...]\n" + String(logOutput[index...])
            }
        }
    }
    @Published var uploadedCount: Int = 0
    @Published var exportedCount: Int = 0
    
    // Filter & Vorschau
    @Published var mediaTypeFilter: MediaTypeFilter = .all {
        didSet { refreshFilteredAssets() }
    }
    @Published var dateFilterMode: DateFilterMode = .all {
        didSet { refreshFilteredAssets() }
    }
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date()) {
        didSet { refreshFilteredAssets() }
    }
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date()) {
        didSet { refreshFilteredAssets() }
    }
    @Published var filterStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date() {
        didSet { refreshFilteredAssets() }
    }
    @Published var filterEndDate: Date = Date() {
        didSet { refreshFilteredAssets() }
    }
    
    @Published var filteredAssets: [PHAsset] = []
    @Published var photoCount: Int = 0
    @Published var videoCount: Int = 0
    @Published var isLibraryAuthorized: Bool = false
    @Published var isLoadingPreview: Bool = false
    
    enum DependencyStatus: Equatable {
        case checking
        case ready
        case missingImmichGo(brewAvailable: Bool)
        case installing
        case installationFailed(String)
    }
    
    @Published var dependencyStatus: DependencyStatus = .checking
    private var verifiedImmichGoPath: String?
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            if statusMessage.starts(with: "Verarbeite") || statusMessage.starts(with: "Exportiere") {
                statusMessage = "Pausiere nach aktuellem Batch..."
            } else {
                statusMessage = "Pausiert"
            }
            logOutput.append("Pausierungsanforderung empfangen. Der laufende Batch wird beendet...\n")
        } else {
            statusMessage = "Setze Vorgang fort..."
        }
    }
    
    private var uploadedAssetIDs: Set<String> = []
    private var exportedAssetIDs: Set<String> = []
    
    private var jsonFilePath: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("ImmichGo_UploadedAssets.json")
    }
    
    private var exportJsonFilePath: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("ImmichGo_ExportedAssets.json")
    }
    
    init() {
        loadUploadedAssetIDs()
        loadExportedAssetIDs()
        checkDependencies()
        refreshFilteredAssets()
    }
    
    func refreshFilteredAssets() {
        DispatchQueue.main.async { [weak self] in
            self?.performFilteredAssetsRefresh()
        }
    }
    
    private func performFilteredAssetsRefresh() {
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authStatus != .authorized && authStatus != .limited {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        self?.isLibraryAuthorized = true
                        self?.performFilteredAssetsRefresh()
                    } else {
                        self?.isLibraryAuthorized = false
                    }
                }
            }
            return
        }
        
        isLibraryAuthorized = true
        isLoadingPreview = true
        
        let mediaType = self.mediaTypeFilter
        let dateMode = self.dateFilterMode
        let selYear = self.selectedYear
        let selMonth = self.selectedMonth
        let startDate = self.filterStartDate
        let endDate = self.filterEndDate
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            var predicates: [NSPredicate] = []
            
            switch mediaType {
            case .all:
                break
            case .photos:
                predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue))
            case .videos:
                predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue))
            }
            
            let calendar = Calendar.current
            
            switch dateMode {
            case .all:
                break
            case .monthYear:
                var components = DateComponents()
                components.year = selYear
                components.month = selMonth
                components.day = 1
                if let startOfMonth = calendar.date(from: components),
                   let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) {
                    predicates.append(NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startOfMonth as NSDate, endOfMonth as NSDate))
                }
            case .customRange:
                let start = calendar.startOfDay(for: startDate)
                let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
                predicates.append(NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", start as NSDate, end as NSDate))
            }
            
            if !predicates.isEmpty {
                options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            let fetchResult = PHAsset.fetchAssets(with: options)
            var assets: [PHAsset] = []
            var pCount = 0
            var vCount = 0
            
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
                if asset.mediaType == .image {
                    pCount += 1
                } else if asset.mediaType == .video {
                    vCount += 1
                }
            }
            
            DispatchQueue.main.async {
                self.filteredAssets = assets
                self.photoCount = pCount
                self.videoCount = vCount
                self.isLoadingPreview = false
            }
        }
    }
    
    private func loadUploadedAssetIDs() {
        if FileManager.default.fileExists(atPath: jsonFilePath.path) {
            do {
                let data = try Data(contentsOf: jsonFilePath)
                let ids = try JSONDecoder().decode([String].self, from: data)
                uploadedAssetIDs = Set(ids)
                uploadedCount = uploadedAssetIDs.count
                logOutput.append("Erfolgreich \(uploadedAssetIDs.count) bereits hochgeladene Asset-IDs aus der Verlaufsdatei geladen.\n")
            } catch {
                uploadedCount = 0
                logOutput.append("Warnung: Verlaufsdatei konnte nicht geladen werden (\(error.localizedDescription)).\n")
            }
        } else {
            uploadedAssetIDs = []
            uploadedCount = 0
            logOutput.append("Keine bestehende Verlaufsdatei gefunden. Starte neu.\n")
        }
    }
    
    private func saveUploadedAssetIDs() {
        uploadedCount = uploadedAssetIDs.count
        do {
            let data = try JSONEncoder().encode(Array(uploadedAssetIDs))
            try data.write(to: jsonFilePath, options: .atomic)
        } catch {
            logOutput.append("Fehler beim Speichern der hochgeladenen Asset-IDs: \(error.localizedDescription)\n")
        }
    }
    
    private func loadExportedAssetIDs() {
        if FileManager.default.fileExists(atPath: exportJsonFilePath.path) {
            do {
                let data = try Data(contentsOf: exportJsonFilePath)
                let ids = try JSONDecoder().decode([String].self, from: data)
                exportedAssetIDs = Set(ids)
                exportedCount = exportedAssetIDs.count
                logOutput.append("Erfolgreich \(exportedAssetIDs.count) bereits exportierte Asset-IDs aus der Export-Verlaufsdatei geladen.\n")
            } catch {
                exportedCount = 0
                logOutput.append("Warnung: Export-Verlaufsdatei konnte nicht geladen werden (\(error.localizedDescription)).\n")
            }
        } else {
            exportedAssetIDs = []
            exportedCount = 0
        }
    }
    
    private func saveExportedAssetIDs() {
        exportedCount = exportedAssetIDs.count
        do {
            let data = try JSONEncoder().encode(Array(exportedAssetIDs))
            try data.write(to: exportJsonFilePath, options: .atomic)
        } catch {
            logOutput.append("Fehler beim Speichern der exportierten Asset-IDs: \(error.localizedDescription)\n")
        }
    }
    
    func resetUploadedAssets() {
        uploadedAssetIDs.removeAll()
        uploadedCount = 0
        if FileManager.default.fileExists(atPath: jsonFilePath.path) {
            try? FileManager.default.removeItem(at: jsonFilePath)
        }
        logOutput.append("Upload-Verlauf erfolgreich zurückgesetzt. Bei einem erneuten Upload werden alle Fotos neu verarbeitet.\n")
    }
    
    func resetExportedAssets() {
        exportedAssetIDs.removeAll()
        exportedCount = 0
        if FileManager.default.fileExists(atPath: exportJsonFilePath.path) {
            try? FileManager.default.removeItem(at: exportJsonFilePath)
        }
        logOutput.append("Export-Verlauf erfolgreich zurückgesetzt. Bei einem erneuten Export werden alle Fotos neu heruntergeladen.\n")
    }
    
    func checkDependencies() {
        dependencyStatus = .checking
        
        if let path = findBinary(name: "immich-go") {
            verifiedImmichGoPath = path
            logOutput.append("immich-go gefunden unter: \(path)\n")
            dependencyStatus = .ready
        } else {
            logOutput.append("immich-go wurde nicht im System gefunden.\n")
            if let brewPath = findBinary(name: "brew") {
                logOutput.append("Homebrew gefunden unter: \(brewPath)\n")
                dependencyStatus = .missingImmichGo(brewAvailable: true)
            } else {
                logOutput.append("Weder immich-go noch Homebrew wurden gefunden.\n")
                dependencyStatus = .missingImmichGo(brewAvailable: false)
            }
        }
    }
    
    private func findBinary(name: String) -> String? {
        let standardPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/bin/\(name)"
        ]
        
        for path in standardPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            let directories = pathEnv.components(separatedBy: ":")
            for directory in directories {
                let fullPath = URL(fileURLWithPath: directory).appendingPathComponent(name).path
                if FileManager.default.fileExists(atPath: fullPath) {
                    return fullPath
                }
            }
        }
        
        return nil
    }
    
    func installImmichGo() {
        dependencyStatus = .installing
        logOutput.append("Starte Installation von immich-go via Homebrew...\n")
        
        guard let brewPath = findBinary(name: "brew") else {
            dependencyStatus = .missingImmichGo(brewAvailable: false)
            logOutput.append("Fehler: Homebrew-Pfad konnte nicht ermittelt werden.\n")
            return
        }
        
        Task {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["install", "immich-go"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if data.isEmpty { return }
                if let outputString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self?.logOutput.append(outputString)
                    }
                }
            }
            
            do {
                let status = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int32, Error>) in
                    process.terminationHandler = { proc in
                        fileHandle.readabilityHandler = nil
                        continuation.resume(returning: proc.terminationStatus)
                    }
                    
                    do {
                        try process.run()
                    } catch {
                        fileHandle.readabilityHandler = nil
                        continuation.resume(throwing: error)
                    }
                }
                
                if status == 0 {
                    logOutput.append("immich-go wurde erfolgreich installiert!\n")
                    self.checkDependencies()
                } else {
                    logOutput.append("Fehler bei der Installation von immich-go (Code \(status)).\n")
                    dependencyStatus = .installationFailed("Installation von immich-go fehlgeschlagen (Code \(status)).")
                }
            } catch {
                logOutput.append("Fehler beim Ausführen von brew: \(error.localizedDescription)\n")
                dependencyStatus = .installationFailed("Fehler: \(error.localizedDescription)")
            }
        }
    }
    
    func installHomebrew() {
        logOutput.append("Versuche Terminal zu öffnen, um Homebrew zu installieren...\n")
        let appleScript = """
        tell application "Terminal"
            activate
            do script "/bin/bash -c \\"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\\""
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            scriptObject.executeAndReturnError(&error)
            if let err = error {
                logOutput.append("Fehler beim Öffnen des Terminals: \(err)\n")
            } else {
                logOutput.append("Terminal wurde geöffnet. Bitte folge den Anweisungen im Terminal-Fenster und klicke danach auf 'Erneut prüfen'.\n")
            }
        }
    }
    
    func startFolderUpload(serverIP: String, serverPort: String, apiKey: String, folderPath: String) {
        isUploading = true
        logOutput = "Starte Ordner-Upload für: \(folderPath)...\n"
        statusMessage = "Lade Ordner hoch..."
        
        Task {
            do {
                let exitStatus = try await runImmichGo(server: "\(serverIP):\(serverPort)", apiKey: apiKey, folderPath: folderPath)
                if exitStatus == 0 {
                    logOutput.append("Ordner erfolgreich hochgeladen.\n")
                    statusMessage = "Ordner erfolgreich hochgeladen!"
                } else {
                    logOutput.append("Fehler: immich-go beendete mit Code \(exitStatus).\n")
                    statusMessage = "Fehler beim Ordner-Upload (Code \(exitStatus))"
                }
            } catch {
                logOutput.append("Fehler beim Ausführen von immich-go: \(error.localizedDescription)\n")
                statusMessage = "Fehler bei Shell-Ausführung"
            }
            isUploading = false
        }
    }
    
    func startPhotoLibraryUpload(serverIP: String, serverPort: String, apiKey: String, concurrencyLimit: Int, batchSize: Int) {
        isUploading = true
        logOutput = "Starte Apple Fotos-Mediathek Upload (parallele Downloads: \(concurrencyLimit), Batch-Größe: \(batchSize))...\n"
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.logOutput.append("Photo Library Zugriff gestattet.\n")
                    Task {
                        await self.processPhotoLibraryUpload(serverIP: serverIP, serverPort: serverPort, apiKey: apiKey, concurrencyLimit: concurrencyLimit, batchSize: batchSize)
                    }
                default:
                    self.logOutput.append("Fehler: Zugriff auf Apple Fotos-Mediathek wurde verweigert.\n")
                    self.statusMessage = "Fehler: Kein Zugriff auf Fotos"
                    self.isUploading = false
                }
            }
        }
    }
    
    func startPhotoLibraryExport(destinationURL: URL, concurrencyLimit: Int) {
        isUploading = true
        isPaused = false
        logOutput = "Starte Apple Fotos Export nach: \(destinationURL.path) (parallele Downloads: \(concurrencyLimit))...\n"
        statusMessage = "Prüfe Fotos-Mediathek..."
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.logOutput.append("Photo Library Zugriff gestattet.\n")
                    Task {
                        await self.processPhotoLibraryExport(destinationURL: destinationURL, concurrencyLimit: concurrencyLimit)
                    }
                default:
                    self.logOutput.append("Fehler: Zugriff auf Apple Fotos-Mediathek wurde verweigert.\n")
                    self.statusMessage = "Fehler: Kein Zugriff auf Fotos"
                    self.isUploading = false
                }
            }
        }
    }
    
    private func getAssetsForProcessing() -> [PHAsset] {
        if !filteredAssets.isEmpty {
            return filteredAssets.sorted { ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast) }
        }
        return fetchAllAssets()
    }
    
    private func fetchAllAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetchResult = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
    
    private func processPhotoLibraryUpload(serverIP: String, serverPort: String, apiKey: String, concurrencyLimit: Int, batchSize: Int) async {
        let allAssets = getAssetsForProcessing()
        let filteredAssets = allAssets.filter { !uploadedAssetIDs.contains($0.localIdentifier) }
        let totalAssets = filteredAssets.count
        
        logOutput.append("Gefunden: \(allAssets.count) Assets insgesamt. Zu verarbeiten: \(totalAssets) (bereits hochgeladen: \(uploadedAssetIDs.count)).\n")
        
        if totalAssets == 0 {
            statusMessage = "Alles auf dem neuesten Stand!"
            isUploading = false
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("immich-go-upload-temp")
        
        if !FileManager.default.fileExists(atPath: tempDir.path) {
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                logOutput.append("Fehler beim Erstellen des temporären Verzeichnisses: \(error.localizedDescription)\n")
                statusMessage = "Temporäres Verzeichnis Fehler"
                isUploading = false
                return
            }
        }
        
        var index = 0
        while index < totalAssets {
            if isPaused {
                statusMessage = "Pausiert"
                logOutput.append("Upload pausiert. Warte auf Fortsetzung...\n")
                while isPaused {
                    do {
                        try await Task.sleep(nanoseconds: 500_000_000)
                    } catch {
                        return
                    }
                    if !isUploading { return }
                }
                logOutput.append("Upload fortgesetzt.\n")
            }
            
            if !isUploading { return }
            
            let endIndex = min(index + batchSize, totalAssets)
            let batch = Array(filteredAssets[index..<endIndex])
            let batchDisplayStart = index + 1
            
            statusMessage = "Verarbeite Batch \(batchDisplayStart) bis \(endIndex) von \(totalAssets)..."
            logOutput.append("========================================\n")
            logOutput.append("Verarbeite Batch \(batchDisplayStart) bis \(endIndex)...\n")
            
            // 1. Clear temp directory
            clearTempDirectory(at: tempDir)
            
            // 2. Download assets in batch concurrently
            var downloadedIDs: [String] = []
            
            logOutput.append("Starte parallelen Download für Batch (Limit: \(concurrencyLimit))...\n")
            
            do {
                let downloadResults = try await withThrowingTaskGroup(of: (String, Bool, [URL]).self) { group in
                    var activeCount = 0
                    var batchIdx = 0
                    var results: [(String, Bool, [URL])] = []
                    
                    while batchIdx < batch.count || activeCount > 0 {
                        // Fill the group up to the concurrencyLimit
                        while activeCount < concurrencyLimit && batchIdx < batch.count {
                            let asset = batch[batchIdx]
                            batchIdx += 1
                            activeCount += 1
                            
                            group.addTask {
                                let resources = PHAssetResource.assetResources(for: asset)
                                let allowedTypes: [PHAssetResourceType] = [.photo, .video, .pairedVideo, .audio]
                                let filteredResources = resources.filter { allowedTypes.contains($0.type) }
                                
                                var filesDownloadedForAsset: [URL] = []
                                var assetDownloadSucceeded = true
                                
                                for resource in filteredResources {
                                    let filename = resource.originalFilename
                                    let fileURL = tempDir.appendingPathComponent(filename)
                                    do {
                                        try await self.downloadResource(resource, to: tempDir)
                                        filesDownloadedForAsset.append(fileURL)
                                    } catch {
                                        assetDownloadSucceeded = false
                                        break
                                    }
                                }
                                return (asset.localIdentifier, assetDownloadSucceeded, filesDownloadedForAsset)
                            }
                        }
                        
                        // Wait for one task to finish
                        if let result = try await group.next() {
                            activeCount -= 1
                            results.append(result)
                            
                            let id = result.0
                            let succeeded = result.1
                            await MainActor.run {
                                if succeeded {
                                    self.logOutput.append("Asset erfolgreich heruntergeladen: \(id)\n")
                                } else {
                                    self.logOutput.append("Fehler beim Herunterladen von Asset: \(id)\n")
                                }
                            }
                        }
                    }
                    return results
                }
                
                // Process results
                for result in downloadResults {
                    let id = result.0
                    let succeeded = result.1
                    let files = result.2
                    
                    if succeeded {
                        downloadedIDs.append(id)
                    } else {
                        logOutput.append("Asset \(id) wird übersprungen (Download fehlgeschlagen). Bereits heruntergeladene Fragmente werden bereinigt...\n")
                        for fileURL in files {
                            try? FileManager.default.removeItem(at: fileURL)
                        }
                    }
                }
            } catch {
                logOutput.append("Schwerwiegender Fehler beim parallelen Download: \(error.localizedDescription)\n")
            }
            
            if downloadedIDs.isEmpty {
                logOutput.append("Keine Assets in diesem Batch erfolgreich heruntergeladen. Überspringe Upload für diesen Batch.\n")
                index += batchSize
                continue
            }
            
            // 3. Execute immich-go with retries
            logOutput.append("Starte immich-go Upload für Batch...\n")
            var uploadSucceeded = false
            let maxUploadRetries = 3
            var uploadAttempt = 0
            
            while uploadAttempt < maxUploadRetries && !uploadSucceeded {
                uploadAttempt += 1
                if !isUploading { return }
                
                do {
                    let exitStatus = try await runImmichGo(server: "\(serverIP):\(serverPort)", apiKey: apiKey, folderPath: tempDir.path, concurrentTasks: concurrencyLimit)
                    if exitStatus == 0 {
                        uploadSucceeded = true
                        logOutput.append("Batch erfolgreich hochgeladen.\n")
                        // Add downloaded IDs to uploaded list
                        for id in downloadedIDs {
                            uploadedAssetIDs.insert(id)
                        }
                        saveUploadedAssetIDs()
                    } else {
                        logOutput.append("Warnung: immich-go beendete mit Code \(exitStatus) (Versuch \(uploadAttempt)/\(maxUploadRetries)).\n")
                        if uploadAttempt < maxUploadRetries {
                            let backoff = UInt64(uploadAttempt * 5)
                            logOutput.append("Warte \(backoff) Sekunden vor dem nächsten Versuch...\n")
                            try? await Task.sleep(nanoseconds: backoff * 1_000_000_000)
                        }
                    }
                } catch {
                    logOutput.append("Warnung: Fehler beim Ausführen von immich-go: \(error.localizedDescription) (Versuch \(uploadAttempt)/\(maxUploadRetries)).\n")
                    if uploadAttempt < maxUploadRetries {
                        let backoff = UInt64(uploadAttempt * 5)
                        logOutput.append("Warte \(backoff) Sekunden vor dem nächsten Versuch...\n")
                        try? await Task.sleep(nanoseconds: backoff * 1_000_000_000)
                    }
                }
            }
            
            if !uploadSucceeded {
                logOutput.append("Warnung: Batch \(batchDisplayStart) bis \(endIndex) konnte nach \(maxUploadRetries) Versuchen nicht vollständig hochgeladen werden. Überspringe diesen Batch und fahre fort...\n")
            }
            
            index += batchSize
        }
        
        // Clear final temp dir
        clearTempDirectory(at: tempDir)
        
        logOutput.append("Upload abgeschlossen! Alle \(totalAssets) neuen Assets verarbeitet.\n")
        statusMessage = "Erfolgreich abgeschlossen!"
        isUploading = false
    }
    
    private func processPhotoLibraryExport(destinationURL: URL, concurrencyLimit: Int) async {
        let allAssets = getAssetsForProcessing()
        let filteredAssets = allAssets.filter { !exportedAssetIDs.contains($0.localIdentifier) }
        let totalAssets = filteredAssets.count
        
        logOutput.append("Gefunden: \(allAssets.count) Assets insgesamt. Zu exportieren: \(totalAssets) (bereits exportiert: \(exportedAssetIDs.count)).\n")
        
        if totalAssets == 0 {
            statusMessage = "Alle ausgewählten Fotos bereits exportiert!"
            isUploading = false
            return
        }
        
        var processedCount = 0
        var successCount = 0
        var failedCount = 0
        
        statusMessage = "Exportiere 0 von \(totalAssets) (0%)..."
        logOutput.append("Starte kontinuierlichen Export von \(totalAssets) Medien nach: \(destinationURL.path)\n")
        logOutput.append("Parallele Downloads: \(concurrencyLimit) | Ordnerstruktur: Jahr/Monat/Tag\n")
        
        do {
            try await withThrowingTaskGroup(of: (String, Bool, String).self) { group in
                var activeCount = 0
                var assetIdx = 0
                
                while assetIdx < totalAssets || activeCount > 0 {
                    // Auf Pause prüfen
                    while self.isPaused {
                        self.statusMessage = "Pausiert (\(processedCount)/\(totalAssets))"
                        try await Task.sleep(nanoseconds: 500_000_000)
                        if !self.isUploading { break }
                    }
                    
                    if !self.isUploading {
                        group.cancelAll()
                        break
                    }
                    
                    // Tasks bis zum Concurrency-Limit starten
                    while activeCount < concurrencyLimit && assetIdx < totalAssets && self.isUploading && !self.isPaused {
                        let asset = filteredAssets[assetIdx]
                        assetIdx += 1
                        activeCount += 1
                        
                        group.addTask {
                            let dateFolder = UploadManager.dateSubfolderURL(for: asset, baseDirectory: destinationURL)
                            let resources = PHAssetResource.assetResources(for: asset)
                            let allowedTypes: [PHAssetResourceType] = [.photo, .video, .pairedVideo, .audio]
                            let filteredResources = resources.filter { allowedTypes.contains($0.type) }
                            
                            if filteredResources.isEmpty {
                                return (asset.localIdentifier, false, "Keine unterstützten Medienressourcen")
                            }
                            
                            // Primärer Dateiname zur Suffix-Ermittlung
                            let primaryResource = filteredResources.first!
                            let originalPrimaryName = primaryResource.originalFilename
                            let baseName = (originalPrimaryName as NSString).deletingPathExtension
                            
                            // Vorbereitung für Existenz-Check
                            let expectedFiles: [(filename: String, expectedSize: Int64?)] = filteredResources.map { res in
                                let size = (res.value(forKey: "fileSize") as? NSNumber)?.int64Value
                                return (res.originalFilename, size)
                            }
                            
                            let reservation = UploadManager.reserveAvailableSuffix(
                                for: baseName,
                                in: dateFolder,
                                expectedFiles: expectedFiles
                            )
                            
                            let suffix = reservation.suffix
                            let alreadyOnDisk = reservation.isAlreadyExportedOnDisk
                            
                            if alreadyOnDisk {
                                let fileNames = expectedFiles.map { $0.filename }.joined(separator: ", ")
                                return (asset.localIdentifier, true, "\(fileNames) (bereits vorhanden)")
                            }
                            
                            defer {
                                UploadManager.releaseReservedSuffix(baseName: baseName, suffix: suffix, in: dateFolder)
                            }
                            
                            var anySaved = false
                            var savedFileNames: [String] = []
                            
                            for resource in filteredResources {
                                do {
                                    let savedURL = try await self.downloadResourceToFolder(
                                        resource,
                                        to: dateFolder,
                                        baseName: baseName,
                                        nameSuffix: suffix
                                    )
                                    anySaved = true
                                    savedFileNames.append(savedURL.lastPathComponent)
                                } catch {
                                    await MainActor.run {
                                        self.logOutput.append("Warnung: Ressource \(resource.originalFilename) konnte nicht exportiert werden: \(error.localizedDescription)\n")
                                    }
                                }
                            }
                            
                            let summary = savedFileNames.isEmpty ? "Fehler beim Schreiben" : savedFileNames.joined(separator: ", ")
                            return (asset.localIdentifier, anySaved, summary)
                        }
                    }
                    
                    // Nächstes fertiggestelltes Asset verarbeiten
                    if let result = try await group.next() {
                        activeCount -= 1
                        processedCount += 1
                        
                        let assetId = result.0
                        let succeeded = result.1
                        let details = result.2
                        
                        let percent = Int((Double(processedCount) / Double(totalAssets)) * 100)
                        self.statusMessage = "Exportiere \(processedCount) von \(totalAssets) (\(percent)%)..."
                        
                        if succeeded {
                            successCount += 1
                            self.exportedAssetIDs.insert(assetId)
                            self.saveExportedAssetIDs()
                            self.logOutput.append("[\(processedCount)/\(totalAssets)] Gespeichert: \(details)\n")
                        } else {
                            failedCount += 1
                            self.logOutput.append("[\(processedCount)/\(totalAssets)] Fehlgeschlagen: \(assetId) (\(details))\n")
                        }
                    }
                }
            }
        } catch {
            logOutput.append("Fehler beim Exportieren: \(error.localizedDescription)\n")
        }
        
        if isUploading {
            logOutput.append("========================================\n")
            logOutput.append("Export abgeschlossen!\n")
            logOutput.append("Gesamt: \(processedCount) verarbeitet (\(successCount) erfolgreich, \(failedCount) fehlgeschlagen).\n")
            statusMessage = "Export erfolgreich abgeschlossen (\(successCount) gespeichert)!"
            isUploading = false
        }
    }
    
    private func clearTempDirectory(at url: URL) {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for item in contents {
                try fileManager.removeItem(at: item)
            }
        } catch {
            logOutput.append("Warnung: Temporäres Verzeichnis konnte nicht vollständig bereinigt werden.\n")
        }
    }
    
    nonisolated private func downloadResource(_ resource: PHAssetResource, to folderURL: URL) async throws {
        let filename = resource.originalFilename
        let fileURL = folderURL.appendingPathComponent(filename)
        
        let maxRetries = 3
        var attempt = 0
        
        while attempt < maxRetries {
            attempt += 1
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let options = PHAssetResourceRequestOptions()
                    options.isNetworkAccessAllowed = true
                    
                    PHAssetResourceManager.default().writeData(for: resource, toFile: fileURL, options: options) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                return // Success!
            } catch {
                if attempt >= maxRetries {
                    throw error
                }
                // Sleep 2 seconds before retrying
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    nonisolated static func dateSubfolderURL(for asset: PHAsset, baseDirectory: URL) -> URL {
        let date = asset.creationDate ?? asset.modificationDate ?? Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let yearStr = String(format: "%04d", year)
        let monthStr = String(format: "%02d", month)
        let dayStr = String(format: "%02d", day)
        
        let targetFolder = baseDirectory
            .appendingPathComponent(yearStr, isDirectory: true)
            .appendingPathComponent(monthStr, isDirectory: true)
            .appendingPathComponent(dayStr, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: targetFolder.path) {
            try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)
        }
        
        return targetFolder
    }
    
    nonisolated private static let fileNamingLock = NSLock()
    nonisolated(unsafe) private static var inFlightNames: Set<String> = []
    
    nonisolated private static func reserveAvailableSuffix(
        for baseName: String,
        in directory: URL,
        expectedFiles: [(filename: String, expectedSize: Int64?)]
    ) -> (suffix: String, isAlreadyExportedOnDisk: Bool) {
        fileNamingLock.lock()
        defer { fileNamingLock.unlock() }
        
        // 1. Prüfen, ob die Dateien mit Standardnamen (ohne Suffix) bereits vollständig auf der Festplatte liegen
        var allMatch = true
        var anyExists = false
        
        for item in expectedFiles {
            let path = directory.appendingPathComponent(item.filename).path
            if FileManager.default.fileExists(atPath: path) {
                anyExists = true
                if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                   let diskSize = attrs[.size] as? Int64 {
                    if diskSize == 0 {
                        allMatch = false // Beschädigte 0-Byte-Datei
                    } else if let expected = item.expectedSize, expected > 0 && diskSize != expected {
                        allMatch = false // Dateigröße weicht ab
                    }
                } else {
                    allMatch = false
                }
            } else {
                allMatch = false
            }
        }
        
        let baseKey = directory.path + "/" + baseName
        if anyExists && allMatch && !inFlightNames.contains(baseKey) {
            // Alle Dateien existieren bereits intakt -> Nicht überschreiben!
            return ("", true)
        }
        
        // 2. Ansonsten einen eindeutigen Suffix finden, um keine vorhandenen Dateien zu überschreiben
        var suffix = ""
        var counter = 1
        
        func isTaken(_ testSuffix: String) -> Bool {
            let nameWithSuffix = baseName + testSuffix
            let inFlightKey = directory.path + "/" + nameWithSuffix
            if inFlightNames.contains(inFlightKey) {
                return true
            }
            if let items = try? FileManager.default.contentsOfDirectory(atPath: directory.path) {
                for item in items {
                    let itemBase = (item as NSString).deletingPathExtension
                    if itemBase.caseInsensitiveCompare(nameWithSuffix) == .orderedSame {
                        return true
                    }
                }
            }
            return false
        }
        
        while isTaken(suffix) {
            suffix = "_\(counter)"
            counter += 1
        }
        
        let reservedKey = directory.path + "/" + (baseName + suffix)
        inFlightNames.insert(reservedKey)
        return (suffix, false)
    }
    
    nonisolated private static func releaseReservedSuffix(baseName: String, suffix: String, in directory: URL) {
        fileNamingLock.lock()
        defer { fileNamingLock.unlock() }
        let reservedKey = directory.path + "/" + (baseName + suffix)
        inFlightNames.remove(reservedKey)
    }
    
    nonisolated private func downloadResourceToFolder(
        _ resource: PHAssetResource,
        to dateFolderURL: URL,
        baseName: String,
        nameSuffix: String
    ) async throws -> URL {
        let ext = (resource.originalFilename as NSString).pathExtension
        let finalFileName = ext.isEmpty ? "\(baseName)\(nameSuffix)" : "\(baseName)\(nameSuffix).\(ext)"
        let fileURL = dateFolderURL.appendingPathComponent(finalFileName)
        
        // Falls die Datei bereits existiert und nicht leer ist, NICHT überschreiben!
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let diskSize = attrs[.size] as? Int64, diskSize > 0 {
                let expectedSize = (resource.value(forKey: "fileSize") as? NSNumber)?.int64Value
                if expectedSize == nil || expectedSize == diskSize {
                    return fileURL
                }
            }
            // Falls eine alte 0-Byte-Datei existiert, vor PhotoKit-Download entfernen
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let maxRetries = 3
        var attempt = 0
        
        while attempt < maxRetries {
            attempt += 1
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let options = PHAssetResourceRequestOptions()
                    options.isNetworkAccessAllowed = true
                    
                    PHAssetResourceManager.default().writeData(for: resource, toFile: fileURL, options: options) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                return fileURL
            } catch {
                if attempt >= maxRetries {
                    // Nach allen Retries fehlgeschlagen: unvollständige Fragmente entfernen
                    try? FileManager.default.removeItem(at: fileURL)
                    throw error
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        return fileURL
    }
    
    private func runImmichGo(server: String, apiKey: String, folderPath: String, concurrentTasks: Int = 3) async throws -> Int32 {
        guard let executablePath = verifiedImmichGoPath else {
            throw NSError(domain: "UploadManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "immich-go Pfad nicht gefunden. Bitte installiere die Abhängigkeiten."])
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        
        var serverURLString = server
        if !serverURLString.lowercased().hasPrefix("http://") && !serverURLString.lowercased().hasPrefix("https://") {
            serverURLString = "http://" + serverURLString
        }
        
        process.arguments = [
            "upload",
            "from-folder",
            "--server=\(serverURLString)",
            "--api-key=\(apiKey)",
            "--pause-immich-jobs=false",
            "--on-errors=continue",
            "--concurrent-tasks=\(concurrentTasks)",
            folderPath
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        
        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            if let outputString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.logOutput.append(outputString)
                }
            }
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int32, Error>) in
            process.terminationHandler = { proc in
                fileHandle.readabilityHandler = nil
                continuation.resume(returning: proc.terminationStatus)
            }
            
            do {
                try process.run()
            } catch {
                fileHandle.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}
