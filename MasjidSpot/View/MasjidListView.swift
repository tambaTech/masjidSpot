//
//  ContentView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/21/25.
//

import SwiftUI
import SwiftData

struct MasjidListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasViewedWalkthrough") var hasViewedWalkthrough: Bool = false
    
    @Query var masjids: [Masjid]
    
    @State private var showNewMasjid = false
    @State private var searchText = ""
    @State private var searchResult: [Masjid] = []
    @State private var isSearchActive = false
    @State private var showWalkthrough = false
    @State private var isRefreshing = false
    @State private var showFilters = false
    @State private var filterOption: FilterOption = .all
    @State private var sortOption: SortOption = .nameAscending
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case visited = "Visited"
        case notVisited = "Not Visited"
        case withCoordinates = "With Location"
    }
    
    enum SortOption: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case recentlyAdded = "Recently Added"
    }
    
    var filteredAndSortedMasjids: [Masjid] {
        var filtered = masjids
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { masjid in
                masjid.name.localizedStandardContains(searchText) ||
                masjid.location.localizedStandardContains(searchText)
            }
        }
        
        // Apply filter
        switch filterOption {
        case .all:
            break
        case .visited:
            filtered = filtered.filter { $0.isVisited }
        case .notVisited:
            filtered = filtered.filter { !$0.isVisited }
        case .withCoordinates:
            filtered = filtered.filter { $0.hasValidCoordinates }
        }
        
        // Apply sort
        switch sortOption {
        case .nameAscending:
            filtered.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            filtered.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .recentlyAdded:
            // Keep default order (most recent first)
            filtered.reverse()
        }
        
        return filtered
    }
    
    var visitedCount: Int {
        masjids.filter { $0.isVisited }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if masjids.isEmpty {
                    // Enhanced empty state
                    MasjidListEmptyStateView(
                        searchText: searchText,
                        onAddMasjid: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showNewMasjid = true
                        }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Stats Header
                            if !isSearchActive && searchText.isEmpty {
                                StatsHeaderView(
                                    totalCount: masjids.count,
                                    visitedCount: visitedCount
                                )
                                .padding(.horizontal)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            }
                            
                            // Filter chips
                            if !masjids.isEmpty {
                                FilterChipsView(
                                    filterOption: $filterOption,
                                    sortOption: $sortOption
                                )
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            
                            // Masjid list
                            if filteredAndSortedMasjids.isEmpty {
                                NoResultsView(filterOption: filterOption, searchText: searchText)
                                    .padding(.top, 60)
                            } else {
                                ForEach(filteredAndSortedMasjids, id: \.id) { masjid in
                                    NavigationLink(destination: MasjidDetailView(masjid: masjid)) {
                                        EnhancedMasjidRow(masjid: masjid)
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(MasjidRowButtonStyle())
                                }
                            }
                            
                            // Bottom spacing
                            Color.clear.frame(height: 20)
                        }
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
                
                // Floating action button
                if !masjids.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                showNewMasjid = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Add")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color.mSPrimary.gradient)
                                        .shadow(color: Color.mSPrimary.opacity(0.4), radius: 12, y: 6)
                                )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("MasjidSpot")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Filter") {
                            Picker("Filter", selection: $filterOption) {
                                ForEach(FilterOption.allCases, id: \.self) { option in
                                    Label(option.rawValue, systemImage: filterIcon(for: option))
                                        .tag(option)
                                }
                            }
                        }
                        
                        Section("Sort") {
                            Picker("Sort", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Label(option.rawValue, systemImage: "arrow.up.arrow.down")
                                        .tag(option)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .tint(Color.mSPrimary)
        .sheet(isPresented: $showNewMasjid) {
            NewMasjidView()
        }
        .sheet(isPresented: $showWalkthrough) {
            TutorialView()
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by name or location"
        )
        .onAppear() {
            showWalkthrough = hasViewedWalkthrough ? false : true
        }
    }
    
    private func filterIcon(for option: FilterOption) -> String {
        switch option {
        case .all: return "list.bullet"
        case .visited: return "checkmark.seal.fill"
        case .notVisited: return "circle"
        case .withCoordinates: return "location.fill"
        }
    }
    
    private func refreshData() async {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Simulate refresh (you can add CloudKit sync here)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
    }
    
    private func deleteRecord(indexSet: IndexSet) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            for index in indexSet {
                let itemToDelete = masjids[index]
                modelContext.delete(itemToDelete)
            }
        }
        
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
    }
}

// MARK: - Stats Header View
struct StatsHeaderView: View {
    let totalCount: Int
    let visitedCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            MasjidStatCard(
                title: "Total",
                value: "\(totalCount)",
                icon: "building.2.fill",
                color: Color.mSPrimary
            )
            
            MasjidStatCard(
                title: "Visited",
                value: "\(visitedCount)",
                icon: "checkmark.seal.fill",
                color: .green
            )
            
            MasjidStatCard(
                title: "To Visit",
                value: "\(totalCount - visitedCount)",
                icon: "circle.dashed",
                color: .orange
            )
        }
    }
}

struct MasjidStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Filter Chips View
struct FilterChipsView: View {
    @Binding var filterOption: MasjidListView.FilterOption
    @Binding var sortOption: MasjidListView.SortOption
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Text("Filter:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                ForEach(MasjidListView.FilterOption.allCases, id: \.self) { option in
                    FilterChip(
                        title: option.rawValue,
                        isSelected: filterOption == option
                    ) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            filterOption = option
                        }
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : Color.mSPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.mSPrimary : Color.mSPrimary.opacity(0.1))
                )
        }
    }
}

// MARK: - Enhanced Masjid Row
struct EnhancedMasjidRow: View {
    @Bindable var masjid: Masjid
    
    var body: some View {
        HStack(spacing: 16) {
            // Image with overlay
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: masjid.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Visited badge
                if masjid.isVisited {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                        .background(
                            Circle()
                                .fill(.white)
                                .padding(4)
                        )
                        .offset(x: 4, y: 4)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(masjid.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mSPrimary)
                    
                    Text(masjid.displayAddress)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Tags
                HStack(spacing: 8) {
                    if !masjid.phone.isEmpty {
                        TagView(icon: "phone.fill", color: .blue)
                    }
                    
                    if !masjid.website.isEmpty {
                        TagView(icon: "safari.fill", color: .purple)
                    }
                    
                    if masjid.hasValidCoordinates {
                        TagView(icon: "location.fill", color: .green)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 1)
        )
        .contextMenu {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                masjid.isVisited.toggle()
            } label: {
                Label(
                    masjid.isVisited ? "Unmark as Visited" : "Mark as Visited",
                    systemImage: "checkmark.seal.fill"
                )
            }
            
            if !masjid.phone.isEmpty {
                Button {
                    if let url = URL(string: "tel://\(masjid.phone)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Call", systemImage: "phone.fill")
                }
            }
            
            if masjid.hasValidCoordinates {
                Button {
                    openInMaps()
                } label: {
                    Label("Open in Maps", systemImage: "map.fill")
                }
            }
        }
    }
    
    private func openInMaps() {
        let urlString = "maps://?ll=\(masjid.latitude),\(masjid.longitude)&q=\(masjid.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct TagView: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(6)
            .background(
                Circle()
                    .fill(color.opacity(0.15))
            )
    }
}

// MARK: - Enhanced Empty State
struct MasjidListEmptyStateView: View {
    let searchText: String
    let onAddMasjid: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image("emptydata")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 280)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            
            VStack(spacing: 12) {
                Text(searchText.isEmpty ? "No Masjids Yet" : "No Results Found")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(searchText.isEmpty ?
                     "Start building your collection of masjids" :
                     "Try adjusting your search or filters")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if searchText.isEmpty {
                Button(action: onAddMasjid) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Add Your First Masjid")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.mSPrimary.gradient)
                            .shadow(color: Color.mSPrimary.opacity(0.4), radius: 12, y: 6)
                    )
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - No Results View
struct NoResultsView: View {
    let filterOption: MasjidListView.FilterOption
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(.secondary)
            
            Text("No Masjids Found")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
    
    private var message: String {
        if !searchText.isEmpty {
            return "No masjids match '\(searchText)'"
        } else {
            switch filterOption {
            case .all:
                return "No masjids in your collection"
            case .visited:
                return "You haven't visited any masjids yet"
            case .notVisited:
                return "All masjids have been visited!"
            case .withCoordinates:
                return "No masjids have location coordinates"
            }
        }
    }
}

// MARK: - Custom Button Style
struct MasjidRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}



#Preview {
    MasjidListView()
}

#Preview("Dark mode") {
    MasjidListView()
        .preferredColorScheme(.dark)
}



struct BasicTextImageRow: View {
    // MARK: - Binding
    @Bindable var masjid: Masjid
    
    // MARK: - State variables
    @State private var showOptions = false
    @State private var showError = false
    
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            
            Image(uiImage: masjid.image)
                .resizable()
                .scaledToFill()
                .frame(width:90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            
            VStack(alignment: .leading) {
                Text(masjid.name)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.brandPrimary)
                    .lineLimit(1)
                
                
                // Show the mosque location/address
                Text(masjid.location.isEmpty ? "No address provided" : masjid.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                   
                
                // Show the masjid description/summary
                //Text(masjid.summary.isEmpty ? "No description available" : masjid.summary)
                //    .font(.caption)
                //    .lineLimit(3)
                //    .padding(.top, 2)
                //    .padding(.bottom, 4)
                //    .background(Color(.systemGray6).opacity(0.1))
                //    .clipShape(RoundedRectangle(cornerRadius: 5))
                //    .padding(.trailing, 10)
            }
            
            if masjid.isVisited {
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
            
            
        }
        
        .contextMenu{
            
            Button(action: {
                self.showError.toggle()
            }) {
                HStack {
                    Text("Reserve a Spot")
                    Image(systemName: "phone")
                }
            }
            
            
            Button(action: {
                masjid.isVisited.toggle()
            }) {
                HStack {
                    Text(masjid.isVisited ? "Unmark as Visited" : "Mark as Visited")
                    Image(systemName: "checkmark.seal.fill")
                }
            }
            
        }
        .alert("Not yet available", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Sorry, this feature is not available yet. ")
        }
        .sheet(isPresented: $showOptions) {
            let defaultText = "Check out this mosque I found on MasjidSpot!"
            
            ActivityView(activityItems: [defaultText, masjid.image])
        }
        
    }
    
}




struct FullImageRow: View {
    // MARK: - Binding
    @Bindable var masjid: Masjid
    
    // MARK: - State variables
    @State private var showOptions = false
    @State private var showError = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Image(uiImage: masjid.image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            HStack(alignment: .top) {
                
                VStack(alignment: .leading) {
                    Text(masjid.name)
                        .font(.system(.title2, design: .rounded))
                    
                    Text(masjid.phone)
                        .font(.system(.body, design: .rounded))
                    
                    Text(masjid.location)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.gray)
                    
                }
                
                if masjid.isVisited {
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
            }
            .padding(.horizontal)
            .padding(.bottom)
            
        }
        .onTapGesture {
            showOptions.toggle()
        }
        .confirmationDialog("What would you like to do?", isPresented: $showOptions, titleVisibility: .visible) {
            
            Button ("Reserve a Spot") {
                self.showError.toggle()
                
            }
            
            Button (masjid.isVisited ? "Unmark as Visited" : "Mark as Visited") {
                masjid.isVisited.toggle()
            }
            
        }
        .alert("Unable to Reserve", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Sorry, this feature is not available yet. ")
            
        }
        .sheet(isPresented: $showOptions) {
            let defaultText = "Check out this mosque I found on MasjidSpot!"
            
            ActivityView(activityItems: [defaultText, masjid.image])
        }
        
    }
    
}


#Preview("BasicTextImageRow", traits: .sizeThatFitsLayout) {
    BasicTextImageRow(masjid: Masjid(name: "Masjid al-Nabawi", location: "Al Haram, Madinah 42311, Saudi Arabia", phone: "+966 14 823 2400", description: "The Prophet's Mosque is the second mosque built by the Islamic prophet Muhammad in Medina, after the Quba Mosque, as well as the second largest mosque and holiest site in Islam, after the Masjid al-Haram in Mecca, in the Saudi region of the Hejaz.", image: UIImage(named: "mosquealmasjidalharam") ?? UIImage(), website: "https://haramain.com", myMasjidUrl: "https://time.my-masjid.com", isVisited: false))
}

#Preview("FullImageRow", traits: .sizeThatFitsLayout) {
    FullImageRow(masjid: Masjid(name: "Masjid al-Nabawi", location: "Al Haram, Madinah 42311, Saudi Arabia", phone: "+966 14 823 2400", description: "The Prophet's Mosque is the second mosque built by the Islamic prophet Muhammad in Medina, after the Quba Mosque, as well as the second largest mosque and holiest site in Islam, after the Masjid al-Haram in Mecca, in the Saudi region of the Hejaz.", image: UIImage(named: "mosquealmasjidalharam") ?? UIImage(), website: "https://haramain.com", myMasjidUrl: "https://time.my-masjid.com", isVisited: false))
}
