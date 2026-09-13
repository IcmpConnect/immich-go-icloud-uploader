import SwiftUI
import Photos

enum MediaTypeFilter: String, CaseIterable, Identifiable {
    case all = "Alle Medien"
    case photos = "Nur Fotos"
    case videos = "Nur Videos"
    
    var id: String { rawValue }
}

enum DateFilterMode: String, CaseIterable, Identifiable {
    case all = "Gesamte Mediathek"
    case monthYear = "Monat & Jahr"
    case customRange = "Zeitraum (Von / Bis)"
    
    var id: String { rawValue }
}

enum TargetDestination: String, CaseIterable, Identifiable {
    case localFolder = "Lokaler Ordner"
    case immichServer = "Immich-Server"
    
    var id: String { rawValue }
}

struct MediaThumbnailView: View {
    let asset: PHAsset
    @State private var thumbnail: NSImage? = nil
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 74, height: 74)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 74, height: 74)
                    .overlay(
                        Image(systemName: asset.mediaType == .video ? "video" : "photo")
                            .foregroundColor(.secondary)
                            .font(.system(size: 20))
                    )
            }
            
            // Badges
            if asset.mediaType == .video {
                HStack(spacing: 2) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 8))
                    Text(formatDuration(asset.duration))
                        .font(.system(size: 9, weight: .bold))
                }
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(3)
                .padding(3)
            } else if asset.mediaSubtypes.contains(.photoLive) {
                Image(systemName: "livephoto")
                    .font(.system(size: 9, weight: .bold))
                    .padding(2)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(3)
                    .padding(3)
            }
        }
        .frame(width: 74, height: 74)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 148, height: 148),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let img = result {
                DispatchQueue.main.async {
                    self.thumbnail = img
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
