import SwiftUI
import CloudKit

// Import UIKit only for UIImage
#if canImport(UIKit)
import UIKit.UIImage
#endif

struct BrowseView: View {
    @State private var cloudStore = MasjidCloudStore()
    @State private var showLoadingIndicator = false
    @State private var showErrorAlert = false
    @State private var convertedMasjids: [CKRecord.ID: Masjid] = [:]
    @State private var viewMode: ViewMode = .grid
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var sortOption: SortOption = .name
    @State private var showingSortMenu = false
    @State private var selectedFilter: FilterOption = .all
    
    enum ViewMode {
        case list
        case grid
    }
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case dateAdded = "Recently Added"
        case location = "Location"
        
        var icon: String {
            switch self {
            case .name: return "textformat"
            case .dateAdded: return "clock"
            case .location: return "map"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case recent = "Recent"
        case visited = "Visited"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .recent: return "clock"
            case .visited: return "checkmark.circle"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient for visual depth
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - Header Section
                        VStack(alignment: .leading, spacing: 16) {
                            // Title with count badge
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("Browse")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                if !filteredMosques.isEmpty {
                                    Text("\(filteredMosques.count)")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(.brandPrimary.gradient)
                                        )
                                }
                            }
                            
                            // Subtitle
                            Text("Find masjids in your community")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // MARK: - Search Bar with View Toggle
                        HStack(spacing: 12) {
                            // Search field
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(isSearchFocused ? .brandPrimary : .secondary)
                                    .font(.system(size: 16, weight: .medium))
                                    .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                                
                                TextField("Search masjids...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 17))
                                    .focused($isSearchFocused)
                                    .submitLabel(.search)
                                    .onChange(of: searchText) { _, _ in
                                        // Provide haptic feedback when clearing search
                                        if searchText.isEmpty {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                        }
                                    }
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        withAnimation(.snappy) {
                                            searchText = ""
                                            isSearchFocused = false
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 16))
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        isSearchFocused ? Color.brandPrimary.opacity(0.3) : Color.clear,
                                        lineWidth: 2
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
                            )
                            
                            // View mode toggle
                            Button(action: {
                                withAnimation(.snappy(duration: 0.3)) {
                                    viewMode = viewMode == .list ? .grid : .list
                                }
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }) {
                                Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.brandPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    )
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Sort and Filter Controls
                        HStack(spacing: 12) {
                            // Sort button
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        withAnimation(.snappy) {
                                            sortOption = option
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }) {
                                        Label(option.rawValue, systemImage: sortOption == option ? "checkmark" : option.icon)
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 14, weight: .medium))
                                    Text(sortOption.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                            
                            // Filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(FilterOption.allCases, id: \.self) { filter in
                                        Button(action: {
                                            withAnimation(.snappy) {
                                                selectedFilter = filter
                                            }
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: filter.icon)
                                                    .font(.system(size: 13, weight: .medium))
                                                Text(filter.rawValue)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedFilter == filter ? Color.brandPrimary.gradient : Color(.secondarySystemBackground).gradient)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Quick Stats or Helpful Tip
                        if !cloudStore.cloudMosques.isEmpty && searchText.isEmpty {
                            HStack(spacing: 16) {
                                // Total count
                                StatCard(
                                    icon: "building.2.fill",
                                    value: "\(cloudStore.cloudMosques.count)",
                                    label: "Total Masjids",
                                    color: .blue
                                )
                                
                                // Recent additions
                                if let recentCount = recentMasjidsCount {
                                    StatCard(
                                        icon: "sparkles",
                                        value: "\(recentCount)",
                                        label: "Added Recently",
                                        color: .purple
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Show search result count
                        if !searchText.isEmpty || selectedFilter != .all {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.brandPrimary)
                                
                                Text(resultCountText)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if !searchText.isEmpty || selectedFilter != .all {
                                    Button("Clear") {
                                        withAnimation(.snappy) {
                                            searchText = ""
                                            selectedFilter = .all
                                        }
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.brandPrimary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.brandPrimary.opacity(0.08))
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - Content Section
                        if !cloudStore.cloudMosques.isEmpty {
                            VStack(spacing: 0) {
                                if viewMode == .grid {
                                    // Grid View with staggered animation
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: 16),
                                        GridItem(.flexible(), spacing: 16)
                                    ], spacing: 20) {
                                        ForEach(Array(filteredMosques.enumerated()), id: \.element.recordID) { index, masjid in
                                            NavigationLink(destination: MasjidDetailView(masjid: cachedMasjid(for: masjid))) {
                                                ModernGridCard(masjid: masjid)
                                            }
                                            .buttonStyle(CardButtonStyle())
                                            .transition(.asymmetric(
                                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                                removal: .scale(scale: 0.8).combined(with: .opacity)
                                            ))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                } else {
                                    // List View with slide animation
                                    LazyVStack(spacing: 12) {
                                        ForEach(Array(filteredMosques.enumerated()), id: \.element.recordID) { index, masjid in
                                            NavigationLink(destination: MasjidDetailView(masjid: cachedMasjid(for: masjid))) {
                                                ModernListCard(masjid: masjid)
                                            }
                                            .buttonStyle(CardButtonStyle())
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)
                                            ))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                }
                            }
                        } else if !showLoadingIndicator {
                            EnhancedEmptyState(
                                searchText: searchText,
                                selectedFilter: selectedFilter,
                                onClearSearch: {
                                    withAnimation(.snappy) {
                                        searchText = ""
                                        selectedFilter = .all
                                    }
                                }
                            )
                            .padding(.top, 60)
                        }
                        
                        // Bottom spacing
                        Color.clear.frame(height: 80)
                    }
                    .padding(.top, 0)
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: 0)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Loading overlay
                if showLoadingIndicator {
                    ModernLoadingView()
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .animation(.snappy(duration: 0.3), value: viewMode)
            .animation(.snappy(duration: 0.3), value: filteredMosques.count)
            .task {
                if cloudStore.cloudMosques.isEmpty {
                    showLoadingIndicator = true
                    await cloudStore.fetchCloudMosques()
                    showLoadingIndicator = false
                    showErrorAlert = cloudStore.errorMessage != nil
                }
            }
            .refreshable {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                await cloudStore.refreshData()
                showErrorAlert = cloudStore.errorMessage != nil
                
                // Success feedback
                if cloudStore.errorMessage == nil {
                    let successGenerator = UINotificationFeedbackGenerator()
                    successGenerator.notificationOccurred(.success)
                }
            }
            .alert("Unable to Load Masjids", isPresented: $showErrorAlert) {
                Button("Retry") {
                    Task {
                        showLoadingIndicator = true
                        await cloudStore.refreshData()
                        showLoadingIndicator = false
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(cloudStore.errorMessage == nil ? .success : .error)
                    }
                }
                Button("Dismiss", role: .cancel) {
                    cloudStore.errorMessage = nil
                }
            } message: {
                if let errorMessage = cloudStore.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Filtered mosques based on search text
    private var filteredMosques: [CKRecord] {
        var mosques = cloudStore.cloudMosques
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .recent:
            // Show mosques added in the last 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            mosques = mosques.filter { mosque in
                guard let creationDate = mosque.creationDate else { return false }
                return creationDate > thirtyDaysAgo
            }
        case .visited:
            mosques = mosques.filter { mosque in
                mosque.object(forKey: "isVisited") as? Bool ?? false
            }
        }
        
        // Apply search
        if !searchText.isEmpty {
            mosques = mosques.filter { masjid in
                let name = masjid.masjidName.lowercased()
                let location = masjid.masjidLocation?.lowercased() ?? ""
                let query = searchText.lowercased()
                
                return name.contains(query) || location.contains(query)
            }
        }
        
        // Apply sort
        return sortedMosques(mosques)
    }
    
    /// Sort mosques based on selected option
    private func sortedMosques(_ mosques: [CKRecord]) -> [CKRecord] {
        switch sortOption {
        case .name:
            return mosques.sorted { ($0.masjidName) < ($1.masjidName) }
        case .dateAdded:
            return mosques.sorted(by: isLatestFirst)
        case .location:
            return mosques.sorted { 
                ($0.masjidLocation ?? "") < ($1.masjidLocation ?? "")
            }
        }
    }
    
    /// Cache converted masjids for better performance
    private func cachedMasjid(for record: CKRecord) -> Masjid {
        if let cached = convertedMasjids[record.recordID] {
            return cached
        }
        let masjid = convertToMasjid(record)
        convertedMasjids[record.recordID] = masjid
        return masjid
    }
    
    private func sortedLatestMasjids(limit: Int) -> [CKRecord]? {
        let sorted = cloudStore.cloudMosques.sorted(by: isLatestFirst)
        return Array(sorted.prefix(limit))
    }
    
    private func isLatestFirst(_ lhs: CKRecord, _ rhs: CKRecord) -> Bool {
        (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
    }
    
    private var recentMasjidsCount: Int? {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let count = cloudStore.cloudMosques.filter { mosque in
            guard let creationDate = mosque.creationDate else { return false }
            return creationDate > thirtyDaysAgo
        }.count
        return count > 0 ? count : nil
    }
    
    private var resultCountText: String {
        let count = filteredMosques.count
        let total = cloudStore.cloudMosques.count
        
        if count == total {
            return "Showing all \(count) masjids"
        } else {
            return "Found \(count) of \(total) masjids"
        }
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
        record.masjidLocation ?? ""
    }
}

// MARK: - CKRecord Extension for Masjid Data
extension CKRecord {
    /// Extracts location string from various possible keys
    var masjidLocation: String? {
        if let city = self.object(forKey: "city") as? String,
           let country = self.object(forKey: "country") as? String {
            return "\(city), \(country)"
        } else if let address = self.object(forKey: "address") as? String {
            return address
        } else if let location = self.object(forKey: "location") as? String {
            return location
        }
        return nil
    }
    
    /// Extracts masjid name with fallback
    var masjidName: String {
        self.object(forKey: "name") as? String ?? "Unnamed Masjid"
    }
    
    /// Extracts image URL from CKAsset
    var masjidImageURL: URL? {
        (self.object(forKey: "image") as? CKAsset)?.fileURL
    }
}

// MARK: - Featured Card Component
struct FeaturedCard: View {
    let masjid: CKRecord
    
    // ✅ Reusable formatter - created once
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
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
            
            // Content with Liquid Glass effect
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
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                }
                
    
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .background {
                LinearGradient(
                    colors: [
                        .black.opacity(0.7),
                        .black.opacity(0.3),
                        .clear
                    ],
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
        }
        .frame(width: 300, height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .modifier(ConditionalGlassEffect(cornerRadius: 28))
        .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 12)
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
        masjid.masjidImageURL
    }
    
    private var masjidName: String {
        masjid.masjidName
    }
    
    private var masjidLocation: String? {
        masjid.masjidLocation
    }
    
    private var formattedDate: String {
        guard let date = masjid.creationDate else { return "Recently added" }
        return Self.dateFormatter.string(from: date)
    }
}

// MARK: - Modern Grid Card
struct ModernGridCard: View {
    let masjid: CKRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with overlay gradient
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure(_), .empty:
                            placeholderView
                        @unknown default:
                            placeholderView
                        }
                    }
                    
                    // Subtle gradient overlay for text readability
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .aspectRatio(1.4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Content section
            VStack(alignment: .leading, spacing: 8) {
                Text(masjidName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                if let location = masjidLocation {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.brandPrimary)
                        
                        Text(location)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.2),
                    Color.brandPrimary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "building.2.fill")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.brandPrimary.opacity(0.3))
        }
    }
    
    private var imageURL: URL? { masjid.masjidImageURL }
    private var masjidName: String { masjid.masjidName }
    private var masjidLocation: String? { masjid.masjidLocation }
}

// MARK: - Modern List Card
struct ModernListCard: View {
    let masjid: CKRecord
    
    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_), .empty:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(masjidName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                if let location = masjidLocation {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.brandPrimary)
                        
                        Text(location)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.2),
                    Color.brandPrimary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "building.2.fill")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.brandPrimary.opacity(0.3))
        }
    }
    
    private var imageURL: URL? { masjid.masjidImageURL }
    private var masjidName: String { masjid.masjidName }
    private var masjidLocation: String? { masjid.masjidLocation }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(color.gradient)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.12))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Enhanced Empty State
struct EnhancedEmptyState: View {
    let searchText: String
    let selectedFilter: BrowseView.FilterOption
    let onClearSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.2),
                                Color.brandPrimary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: searchText.isEmpty ? "building.2.crop.circle" : "magnifyingglass")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.brandPrimary, .brandPrimary.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.bounce, value: searchText.isEmpty)
            }
            
            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.title2.weight(.bold))
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            if !searchText.isEmpty || selectedFilter != .all {
                Button(action: {
                    onClearSearch()
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Clear Filters")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.brandPrimary.gradient)
                    )
                    .shadow(color: .brandPrimary.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        } else if selectedFilter == .recent {
            return "No Recent Masjids"
        } else if selectedFilter == .visited {
            return "No Visited Masjids"
        } else {
            return "No Masjids Found"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search or filters to find what you're looking for."
        } else if selectedFilter == .recent {
            return "No masjids have been added in the last 30 days. Check back soon!"
        } else if selectedFilter == .visited {
            return "You haven't marked any masjids as visited yet. Visit a masjid to add it here."
        } else {
            return "New masjids will appear here when they're added to the community. Pull down to refresh."
        }
    }
}

// MARK: - Modern Loading View
struct ModernLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { } // Prevent interaction
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.brandPrimary, .brandPrimary.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                Text("Loading masjids...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.2), radius: 30)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Masjid List Card Component (Deprecated)
struct MasjidListCard: View {
    let masjid: CKRecord
    
    // ✅ Reusable formatter - created once
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
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
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(masjidName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                // Location
                if let location = masjidLocation {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        
                        Text(location)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        }
        .modifier(ConditionalGlassEffect(cornerRadius: 20, interactive: true))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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
        masjid.masjidImageURL
    }
    
    private var masjidName: String {
        masjid.masjidName
    }
    
    private var masjidLocation: String? {
        masjid.masjidLocation
    }
    
    private var formattedDate: String {
        guard let date = masjid.creationDate else { return "Recently added" }
        return Self.dateFormatter.string(from: date)
    }
}

// MARK: - Apple Style Grid Card (Like Developer App)
struct AppleStyleGridCard: View {
    let masjid: CKRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Container with proper aspect ratio
            GeometryReader { geometry in
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    case .failure(_):
                        placeholderContent
                    case .empty:
                        ZStack {
                            placeholderContent
                            ProgressView()
                                .tint(.white)
                        }
                    @unknown default:
                        placeholderContent
                    }
                }
            }
            .aspectRatio(1.7, contentMode: .fit)
            .background(Color(white: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Text Content
            VStack(alignment: .leading, spacing: 6) {
                Text(masjidName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let location = masjidLocation {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Text(location)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    
    private var placeholderContent: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(white: 0.25),
                    Color(white: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "building.2")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
    private var imageURL: URL? {
        masjid.masjidImageURL
    }
    
    private var masjidName: String {
        masjid.masjidName
    }
    
    private var masjidLocation: String? {
        masjid.masjidLocation
    }
}

// MARK: - Masjid Grid Card Component
struct MasjidGridCard: View {
    let masjid: CKRecord
    
    // ✅ Reusable formatter - created once
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
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
                            .scaleEffect(0.7)
                    }
                @unknown default:
                    placeholderGradient
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(masjidName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                // Location
                if let location = masjidLocation {
                    Text(location)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        }
        .modifier(ConditionalGlassEffect(cornerRadius: 16, interactive: true))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var placeholderGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.3),
                Color.purple.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var imageURL: URL? {
        masjid.masjidImageURL
    }
    
    private var masjidName: String {
        masjid.masjidName
    }
    
    private var masjidLocation: String? {
        masjid.masjidLocation
    }
    
    private var formattedDate: String? {
        guard let date = masjid.creationDate else { return nil }
        return Self.dateFormatter.string(from: date)
    }
}

// MARK: - Masjid Card Component (Deprecated - use MasjidListCard)
struct MasjidCard: View {
    let masjid: CKRecord
    
    // ✅ Reusable formatter - created once
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
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
        }
        .modifier(ConditionalGlassEffect(cornerRadius: 20, interactive: true))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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
        masjid.masjidImageURL
    }
    
    private var masjidName: String {
        masjid.masjidName
    }
    
    private var masjidLocation: String? {
        masjid.masjidLocation
    }
    
    private var formattedDate: String {
        guard let date = masjid.creationDate else { return "Recently added" }
        return Self.dateFormatter.string(from: date)
    }
}

// MARK: - Empty State
struct MasjidEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brandPrimary.gradient)
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
                    .tint(Color.brandPrimary)
                
                Text("Loading masjids...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 32)
            .modifier(ConditionalGlassEffect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 30)
        }
    }
}

// MARK: - Conditional Glass Effect Helper
struct ConditionalGlassEffect: ViewModifier {
    let cornerRadius: CGFloat
    var interactive: Bool = false
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            // Fallback for iOS 25 and earlier
            content
        }
    }
}

#Preview("Default View") {
    BrowseView()
}
#Preview("Loading State") {
    BrowseView()
        .onAppear {
            // Simulate loading
        }
}

#Preview("Empty State") {
    BrowseView()
        .onAppear {
            // Show empty state
        }
}

