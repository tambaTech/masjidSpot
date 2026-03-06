import SwiftUI
import CloudKit
import UIKit

struct DiscoverView: View {
    @State private var cloudStore = MasjidCloudStore()
    @State private var showLoadingIndicator = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Discover")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.brandPrimary)
                        
                        Text("Find masjids in your area")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    
                    // MARK: - Featured Carousel
                    if let latestMasjids = sortedLatestMasjids(limit: 5), !latestMasjids.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                                
                                Text("Featured")
                                    .font(.title3.weight(.semibold))
                            }
                            .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(latestMasjids, id: \.recordID) { masjid in
                                        NavigationLink(destination: MasjidDetailView(masjid: convertToMasjid(masjid))) {
                                            FeaturedCard(masjid: masjid)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    
                    // MARK: - All Masjids Grid
                    if !cloudStore.cloudMosques.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "building.2.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.brandPrimary)
                                    
                                    Text("All Masjids")
                                        .font(.title3.weight(.semibold))
                                }
                                
                                Spacer()
                                
                                Text("\(cloudStore.cloudMosques.count)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 32, minHeight: 24)
                                    .background(
                                        Capsule()
                                            .fill(.brandPrimary.gradient)
                                    )
                            }
                            .padding(.horizontal, 24)
                            
                            LazyVStack(spacing: 14) {
                                ForEach(cloudStore.cloudMosques.sorted(by: isLatestFirst), id: \.recordID) { masjid in
                                    NavigationLink(destination: MasjidDetailView(masjid: convertToMasjid(masjid))) {
                                        MasjidCard(masjid: masjid)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    } else if !showLoadingIndicator {
                        EmptyView()
                    }
                    
                    Color.clear.frame(height: 40)
                }
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .overlay {
                if showLoadingIndicator {
                    LoadingOverlay()
                }
            }
            .task {
                if cloudStore.cloudMosques.isEmpty {
                    showLoadingIndicator = true
                    await cloudStore.fetchCloudMosques()
                    showLoadingIndicator = false
                }
            }
            .refreshable {
                await cloudStore.refreshData()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func sortedLatestMasjids(limit: Int) -> [CKRecord]? {
        let sorted = cloudStore.cloudMosques.sorted(by: isLatestFirst)
        return Array(sorted.prefix(limit))
    }
    
    private func isLatestFirst(_ lhs: CKRecord, _ rhs: CKRecord) -> Bool {
        (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
    }
    
    private func convertToMasjid(_ record: CKRecord) -> Masjid {
        let name = record.object(forKey: "name") as? String ?? "Unnamed Masjid"
        let location = extractLocation(from: record)
        let phone = record.object(forKey: "phone") as? String ?? ""
        let description = record.object(forKey: "description") as? String ?? record.object(forKey: "summary") as? String ?? ""
        let website = record.object(forKey: "website") as? String ?? ""
        let myMasjidUrl = record.object(forKey: "myMasjidUrl") as? String ?? ""
        let isVisited = record.object(forKey: "isVisited") as? Bool ?? false
        
        // Get image from CKAsset
        var image = UIImage(systemName: "building.2") ?? UIImage()
        if let asset = record.object(forKey: "image") as? CKAsset,
           let fileURL = asset.fileURL,
           let imageData = try? Data(contentsOf: fileURL),
           let uiImage = UIImage(data: imageData) {
            image = uiImage
        }
        
        return Masjid(
            name: name,
            location: location,
            phone: phone,
            description: description,
            image: image,
            website: website,
            myMasjidUrl: myMasjidUrl,
            isVisited: isVisited
        )
    }
    
    private func extractLocation(from record: CKRecord) -> String {
        if let city = record.object(forKey: "city") as? String,
           let country = record.object(forKey: "country") as? String {
            return "\(city), \(country)"
        } else if let address = record.object(forKey: "address") as? String {
            return address
        } else if let location = record.object(forKey: "location") as? String {
            return location
        }
        return ""
    }
}

// MARK: - Featured Card Component
struct FeaturedCard: View {
    let masjid: CKRecord
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    placeholderGradient
                case .empty:
                    ZStack {
                        placeholderGradient
                        ProgressView()
                            .tint(.white)
                    }
                @unknown default:
                    placeholderGradient
                }
            }
            .frame(width: 300, height: 380)
            .clipped()
            
            // Gradient Overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.8),
                            .black.opacity(0.4),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: UnitPoint(x: 0.5, y: 0.4)
                    )
                )
            
            // Content
            VStack(alignment: .leading, spacing: 10) {
                Text(masjidName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                
                // Location
                if let location = masjidLocation {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption.weight(.medium))
                        
                        Text(location)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                
                // Date
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption.weight(.medium))
                    
                    Text(formattedDate)
                        .font(.callout.weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.95))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(24)
        }
        .frame(width: 300, height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 12)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
    }
    
    private var placeholderGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.4),
                Color.purple.opacity(0.4),
                Color.pink.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var imageURL: URL? {
        (masjid.object(forKey: "image") as? CKAsset)?.fileURL
    }
    
    private var masjidName: String {
        masjid.object(forKey: "name") as? String ?? "Unnamed Masjid"
    }
    
    private var masjidLocation: String? {
        if let city = masjid.object(forKey: "city") as? String,
           let country = masjid.object(forKey: "country") as? String {
            return "\(city), \(country)"
        } else if let address = masjid.object(forKey: "address") as? String {
            return address
        } else if let location = masjid.object(forKey: "location") as? String {
            return location
        }
        return nil
    }
    
    private var formattedDate: String {
        guard let date = masjid.creationDate else { return "Recently added" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Masjid Card Component
struct MasjidCard: View {
    let masjid: CKRecord
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    placeholderGradient
                case .empty:
                    ZStack {
                        placeholderGradient
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                @unknown default:
                    placeholderGradient
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(masjidName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // Location
                if let location = masjidLocation {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Date
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    
                    Text(formattedDate)
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    private var placeholderGradient: some View {
        LinearGradient(
            colors: [
                Color.green.opacity(0.25),
                Color.teal.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var imageURL: URL? {
        (masjid.object(forKey: "image") as? CKAsset)?.fileURL
    }
    
    private var masjidName: String {
        masjid.object(forKey: "name") as? String ?? "Unnamed Masjid"
    }
    
    private var masjidLocation: String? {
        if let city = masjid.object(forKey: "city") as? String,
           let country = masjid.object(forKey: "country") as? String {
            return "\(city), \(country)"
        } else if let address = masjid.object(forKey: "address") as? String {
            return address
        } else if let location = masjid.object(forKey: "location") as? String {
            return location
        }
        return nil
    }
    
    private var formattedDate: String {
        guard let date = masjid.creationDate else { return "Recently added" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Empty State
struct EmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.brandPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.brandPrimary.gradient)
            }
            
            VStack(spacing: 10) {
                Text("No Masjids Available")
                    .font(.title3.weight(.semibold))
                
                Text("New masjids will appear here when they're added to the community")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.brandPrimary)
                
                Text("Loading masjids...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 30)
            }
        }
    }
}

#Preview {
    DiscoverView()
}
