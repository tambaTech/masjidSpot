//
//  CloudMosqueDetailView.swift
//  MosquePin
//
//  Created by Lamin Tamba
//

import SwiftUI
import CloudKit
import MapKit
import CoreLocation

struct CloudMosqueDetailView: View {
    let mosque: CKRecord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationGeocoder = CloudKitLocationGeocoder()
    
    // State variables for sheet presentations
    @State private var showWebsite = false
    @State private var showMyMasjid = false
    @State private var showingLookAround = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLoadingLookAround = false
    @State private var showingLookAroundAlert = false
    @State private var lookAroundErrorMessage = ""
    
    // Enhanced UX state
    @State private var showingShareSheet = false
    @State private var copiedToClipboard = false
    @State private var scrollOffset: CGFloat = 0
    @State private var imageHeight: CGFloat = 300
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Enhanced Hero Image with Parallax Effect
                    GeometryReader { geometry in
                        let offset = geometry.frame(in: .named("scroll")).minY
                        let height = imageHeight + max(0, offset)
                        
                        Group {
                            if let imageAsset = mosque["image"] as? CKAsset,
                               let imageData = try? Data(contentsOf: imageAsset.fileURL!),
                               let image = UIImage(data: imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: height)
                                    .clipped()
                                    .offset(y: -max(0, offset))
                            } else {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: geometry.size.width, height: height)
                                    .overlay(
                                        VStack(spacing: 12) {
                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.white.opacity(0.8))
                                            Text("No Image Available")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    )
                                    .offset(y: -max(0, offset))
                            }
                        }
                    }
                    .frame(height: imageHeight)
                    
                    // Content Section
                    VStack(alignment: .leading, spacing: 20) {
                        // Header with Name and Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                Text(mosque["name"] as? String ?? "Unknown")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                // Quick Share Button
                                Button {
                                    provideFeedback()
                                    showingShareSheet = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.blue)
                                        .frame(width: 44, height: 44)
                                        .background(.blue.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                            
                            // Location with copy functionality
                            if let location = mosque["location"] as? String, !location.isEmpty {
                                Button {
                                    copyToClipboard(location)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 16))
                                        Text(location)
                                            .font(.subheadline)
                                            .multilineTextAlignment(.leading)
                                        
                                        if copiedToClipboard {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Phone with direct call functionality
                            if let phone = mosque["phone"] as? String, !phone.isEmpty {
                                Button {
                                    callMosque(phone: phone)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 16))
                                        Text(phone)
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Quick Action Buttons Row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Prayer Times Button
                                if let myMasjidUrl = mosque["myMasjidUrl"] as? String, !myMasjidUrl.isEmpty {
                                    QuickActionButton(
                                        icon: "clock.fill",
                                        title: "Prayer Times",
                                        color: .pink
                                    ) {
                                        provideFeedback()
                                        showMyMasjid = true
                                    }
                                }
                                
                                // Website Button
                                if let website = mosque["website"] as? String, !website.isEmpty {
                                    QuickActionButton(
                                        icon: "safari.fill",
                                        title: "Website",
                                        color: .blue
                                    ) {
                                        provideFeedback()
                                        showWebsite = true
                                    }
                                }
                                
                                // Look Around Button
                                QuickActionButton(
                                    icon: isLoadingLookAround ? "" : "binoculars.fill",
                                    title: isLoadingLookAround ? "Loading..." : "Look Around",
                                    color: .purple,
                                    isLoading: isLoadingLookAround
                                ) {
                                    provideFeedback()
                                    Task {
                                        await requestLookAround()
                                    }
                                }
                                .disabled(isLoadingLookAround)
                                
                                // Directions Button
                                QuickActionButton(
                                    icon: "car.fill",
                                    title: "Directions",
                                    color: .green
                                ) {
                                    provideFeedback()
                                    openDirections()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Description Section
                        if let description = mosque["description"] as? String, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("About", systemImage: "info.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Additional spacing at bottom
                        Spacer(minLength: 20)
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Show title when scrolled
                    Text(mosque["name"] as? String ?? "")
                        .font(.headline)
                        .opacity(scrollOffset < -100 ? 1 : 0)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .sheet(isPresented: $showWebsite) {
            if let website = mosque["website"] as? String, !website.isEmpty {
                SafariView(url: website)
            }
        }
        .sheet(isPresented: $showMyMasjid) {
            if let myMasjidUrl = mosque["myMasjidUrl"] as? String, !myMasjidUrl.isEmpty {
                SafariView(url: myMasjidUrl)
            }
        }
        .sheet(isPresented: $showingLookAround) {
            if let lookAroundScene = lookAroundScene {
                NavigationStack {
                    LookAroundViewController(scene: lookAroundScene)
                        .ignoresSafeArea()
                        .navigationTitle("Look Around")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showingLookAround = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let name = mosque["name"] as? String,
               let location = mosque["location"] as? String {
                ShareSheet(items: ["\(name)\n\(location)"])
            }
        }
        .alert("Look Around Unavailable", isPresented: $showingLookAroundAlert) {
            Button("OK") { }
        } message: {
            Text(lookAroundErrorMessage)
        }
    }
    
    // MARK: - Helper Functions
    
    private func provideFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        provideFeedback()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copiedToClipboard = true
        }
        
        // Reset after 2 seconds
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation {
                    copiedToClipboard = false
                }
            }
        }
    }
    
    @MainActor
    private func requestLookAround() async {
        guard let locationString = mosque["location"] as? String, !locationString.isEmpty else {
            lookAroundErrorMessage = "No location available for this mosque."
            showingLookAroundAlert = true
            return
        }
        
        isLoadingLookAround = true
        
        // Try to get cached coordinate first
        var coordinate: CLLocationCoordinate2D?
        
        if let cached = locationGeocoder.getCachedCoordinate(for: locationString) {
            coordinate = cached
        } else {
            // Geocode the location
            do {
                coordinate = try await locationGeocoder.geocodeLocation(locationString)
            } catch {
                isLoadingLookAround = false
                lookAroundErrorMessage = "Unable to find coordinates for this location."
                showingLookAroundAlert = true
                return
            }
        }
        
        guard let coord = coordinate else {
            isLoadingLookAround = false
            lookAroundErrorMessage = "Unable to get coordinates for this mosque."
            showingLookAroundAlert = true
            return
        }
        
        let request = MKLookAroundSceneRequest(coordinate: coord)
        
        do {
            if let scene = try await request.scene {
                isLoadingLookAround = false
                lookAroundScene = scene
                showingLookAround = true
            } else {
                isLoadingLookAround = false
                lookAroundErrorMessage = "Look Around is not available for this mosque location. Coverage may be limited in this area."
                showingLookAroundAlert = true
            }
        } catch {
            isLoadingLookAround = false
            lookAroundErrorMessage = "Failed to load Look Around: \(error.localizedDescription)"
            showingLookAroundAlert = true
        }
    }
    
    private func openDirections() {
        guard let locationString = mosque["location"] as? String, !locationString.isEmpty else {
            print("No location available for directions")
            return
        }
        
        // Try to get cached coordinate first
        if let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) {
            openMapsWithCoordinate(coordinate)
        } else {
            // Fallback: geocode the location
            Task {
                do {
                    let coordinate = try await locationGeocoder.geocodeLocation(locationString)
                    await MainActor.run {
                        openMapsWithCoordinate(coordinate)
                    }
                } catch {
                    // If geocoding fails, try with the location string directly
                    await MainActor.run {
                        openMapsWithLocationString(locationString)
                    }
                }
            }
        }
    }
    
    private func openMapsWithCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = mosque["name"] as? String ?? "Mosque"
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    private func openMapsWithLocationString(_ locationString: String) {
        // Create URL for Maps app with location string
        let encodedLocation = locationString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?daddr=\(encodedLocation)&dirflg=d"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func callMosque(phone: String) {
        // Clean phone number (remove spaces, dashes, etc.)
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

/// Quick action button for horizontal scroll
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.gradient)
                        .frame(width: 56, height: 56)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if !icon.isEmpty {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
    }
}



#Preview {
    let mockRecord = CKRecord(recordType: "Mosque")
    mockRecord["name"] = "Sample Mosque"
    mockRecord["location"] = "123 Sample Street, Sample City"
    mockRecord["description"] = "This is a sample mosque for preview purposes."
    
    return CloudMosqueDetailView(mosque: mockRecord)
}
