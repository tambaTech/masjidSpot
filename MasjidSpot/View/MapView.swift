//
//  MapView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/2/25.
//

import SwiftUI
import MapKit

// MARK: - Map Style Type
enum MapStyleType: String, CaseIterable {
    case standard = "Standard"
    case hybrid = "Satellite"
    case imagery = "Imagery"
    
    var icon: String {
        switch self {
        case .standard: return "map"
        case .hybrid: return "globe.americas.fill"
        case .imagery: return "photo.fill"
        }
    }
    
    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .hybrid: return .hybrid
        case .imagery: return .imagery
        }
    }
}

// MARK: - View Model
@MainActor
@Observable
final class MasjidDetailMapViewModel {
    var position: MapCameraPosition = .automatic
    var markerLocation: CLLocationCoordinate2D?
    var isGeocoding = false
    var geocodingError: String?
    var showDirections = false
    var mapStyle: MapStyle = .standard
    var selectedMapStyleType: MapStyleType = .standard
    var showInfoPopup = false
    var showingShareSheet = false
    
    private let masjid: Masjid
    
    init(masjid: Masjid) {
        self.masjid = masjid
    }
    
    func recenterMap() {
        guard let coordinate = markerLocation else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015)
            )
            position = .region(region)
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func convertAddress(location: String) async {
        // Validate that we have a location to geocode
        guard !location.isEmpty else {
            geocodingError = "No location provided"
            setFallbackLocation()
            return
        }
        
        // First check if mosque already has valid coordinates
        if masjid.latitude != 0.0 && masjid.longitude != 0.0 {
            let coordinate = CLLocationCoordinate2D(latitude: masjid.latitude, longitude: masjid.longitude)
            updateMapPosition(with: coordinate, span: 0.0015)
            print("✅ Using stored coordinates: \(coordinate.latitude), \(coordinate.longitude)")
            return
        }
        
        // Geocode the address string
        isGeocoding = true
        geocodingError = nil
        
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = location
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            guard let firstItem = response.mapItems.first else {
                print("❌ No location found for address: \(location)")
                geocodingError = "Location not found: \(location)"
                isGeocoding = false
                setFallbackLocation()
                return
            }
            
            let coordinate = firstItem.placemark.coordinate
            updateMapPosition(with: coordinate, span: 0.0015)
            isGeocoding = false
            
            print("✅ Geocoded '\(location)' to: \(coordinate.latitude), \(coordinate.longitude)")
            
        } catch {
            print("❌ Geocoding error: \(error.localizedDescription)")
            geocodingError = "Failed to find location"
            isGeocoding = false
            setFallbackLocation()
        }
    }
    
    private func setFallbackLocation() {
        // Default to Mecca
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
        updateMapPosition(with: defaultCoordinate, span: 0.01)
    }
    
    private func updateMapPosition(with coordinate: CLLocationCoordinate2D, span: Double) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
        withAnimation(.easeInOut(duration: 0.5)) {
            self.position = .region(region)
            self.markerLocation = coordinate
        }
    }
}

struct MasjidDetailMapView: View {
    var location: String = ""
    var interactionMode: MapInteractionModes = .all
    var masjid: Masjid
    
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: MasjidDetailMapViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    @Namespace private var animation
    
    init(location: String = "", interactionMode: MapInteractionModes = .all, masjid: Masjid) {
        self.location = location
        self.interactionMode = interactionMode
        self.masjid = masjid
        self._viewModel = State(initialValue: MasjidDetailMapViewModel(masjid: masjid))
    }
    
    var body: some View {
        ZStack {
            // Map View
            Map(position: $viewModel.position, interactionModes: interactionMode) {
                if let markerLocation = viewModel.markerLocation {
                    Annotation(masjid.name, coordinate: markerLocation) {
                        MasjidAnnotationView(masjid: masjid)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    viewModel.showInfoPopup = true
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(viewModel.mapStyle)
            .mapControlVisibility(.hidden)
            
            // Top controls overlay (only for full interactive mode)
            if interactionMode == .all {
                VStack {
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Back button with improved touch target
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.mSPrimary)
                                        .shadow(color: Color.mSPrimary.opacity(0.3), radius: 8, y: 4)
                                )
                        }
                        
                        Spacer()
                        
                        // Recenter button
                        Button {
                            viewModel.recenterMap()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.mSPrimary)
                                        .shadow(color: Color.mSPrimary.opacity(0.3), radius: 8, y: 4)
                                )
                        }
                        
                        // Improved map style selector
                        Menu {
                            ForEach(MapStyleType.allCases, id: \.self) { style in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.selectedMapStyleType = style
                                        viewModel.mapStyle = style.mapStyle
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Label(
                                        style.rawValue,
                                        systemImage: viewModel.selectedMapStyleType == style ? "checkmark.circle.fill" : style.icon
                                    )
                                }
                            }
                        } label: {
                            Image(systemName: "map.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.mSPrimary)
                                        .shadow(color: Color.mSPrimary.opacity(0.3), radius: 8, y: 4)
                                )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.top, 60) // Increased from .large to provide better spacing from top edge
                    
                    Spacer()
                }
            }
            
            // Loading overlay with improved design
            if viewModel.isGeocoding {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        ProgressView()
                            .tint(Color.mSPrimary)
                            .scaleEffect(1.2)
                        
                        Text("Finding location...")
                            .font(DesignSystem.Typography.body(weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(DesignSystem.Spacing.xLarge)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    )
                }
                .transition(.opacity)
            }
            
            // Error message with dismiss action
            if let error = viewModel.geocodingError {
                VStack {
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(DesignSystem.Typography.body(weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Text(error)
                            .font(DesignSystem.Typography.caption(weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                viewModel.geocodingError = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    )
                    .padding(DesignSystem.Spacing.large)
                    .padding(.bottom, 60) // Fixed position from bottom
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Info popup overlay (appears on annotation tap)
            if viewModel.showInfoPopup, let coordinate = viewModel.markerLocation {
                ZStack {
                    // Dimmed background
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                viewModel.showInfoPopup = false
                            }
                        }
                    
                    // Info popup card
                    MapInfoPopup(
                        masjid: masjid,
                        coordinate: coordinate,
                        onDirections: {
                            viewModel.showInfoPopup = false
                            openDirections()
                        },
                        onShare: {
                            viewModel.showingShareSheet = true
                        },
                        onClose: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                viewModel.showInfoPopup = false
                            }
                        }
                    )
                    .padding(.horizontal, DesignSystem.Spacing.xLarge)
                }
                .transition(.opacity)
            }
        }
        .task {
            await viewModel.convertAddress(location: location.isEmpty ? masjid.location : location)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let coordinate = viewModel.markerLocation {
                ShareSheet(items: [createShareText(coordinate: coordinate)])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createShareText(coordinate: CLLocationCoordinate2D) -> String {
        """
        📍 \(masjid.name)
        \(masjid.location)
        
        View on Maps: https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(masjid.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        """
    }
    
    private func openDirections() {
        guard let coordinate = viewModel.markerLocation else { return }
        
        let urlString = "maps://?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(masjid.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

// MARK: - Map Info Popup (Tap-triggered)
struct MapInfoPopup: View {
    let masjid: Masjid
    let coordinate: CLLocationCoordinate2D
    let onDirections: () -> Void
    let onShare: () -> Void
    let onClose: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var copiedCoordinates = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Header with close button
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(masjid.name)
                        .font(DesignSystem.Typography.title(weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text("Masjid Information")
                        .font(DesignSystem.Typography.caption(weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            
            // Masjid image
            Image(uiImage: masjid.image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                        .stroke(Color.mSPrimary.opacity(0.2), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
            // Location info
            VStack(spacing: DesignSystem.Spacing.medium) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.mSPrimary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location")
                            .font(DesignSystem.Typography.caption(weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Text(masjid.location)
                            .font(DesignSystem.Typography.body(weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                    }
                    
                    Spacer()
                }
                
                // Coordinates with copy button
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coordinates")
                            .font(DesignSystem.Typography.caption(weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                            .font(DesignSystem.Typography.body(weight: .medium))
                            .foregroundStyle(.primary)
                            .monospaced()
                    }
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = "\(coordinate.latitude), \(coordinate.longitude)"
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            copiedCoordinates = true
                        }
                        
                        // Reset after delay
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            await MainActor.run {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    copiedCoordinates = false
                                }
                            }
                        }
                    } label: {
                        Image(systemName: copiedCoordinates ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(copiedCoordinates ? .green : Color.mSPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(copiedCoordinates ? Color.green.opacity(0.15) : Color.mSPrimary.opacity(0.15))
                            )
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            
            // Action buttons
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Directions button (primary)
                Button(action: onDirections) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "car.fill")
                            .font(DesignSystem.Typography.body(weight: .semibold))
                        Text("Get Directions")
                            .font(DesignSystem.Typography.body(weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                            .fill(Color.mSPrimary.gradient)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Share button (secondary)
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(DesignSystem.Typography.body(weight: .semibold))
                        .foregroundStyle(Color.mSPrimary)
                        .frame(width: 54, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                .fill(Color.mSPrimary.opacity(0.15))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.xLarge)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
        )
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - Enhanced Annotation View
struct EnhancedAnnotationView: View {
    let masjid: Masjid
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Mosque icon with pulse effect
            ZStack {
                Circle()
                    .fill(Color.mSPrimary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
                
                Circle()
                    .fill(Color.mSPrimary.gradient)
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.mSPrimary.opacity(0.4), radius: 8, y: 4)
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            
            // Pin pointer
            Triangle()
                .fill(Color.mSPrimary.gradient)
                .frame(width: 20, height: 12)
                .offset(y: -1)
        }
        .overlay(alignment: .topTrailing) {
            if masjid.isVisited {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(.green)
                            .padding(-3)
                    )
                    .offset(x: 8, y: -4)
            }
        }
    }
}

// Triangle shape for pin pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Enhanced Map Info Card
struct EnhancedMapInfoCard: View {
    let masjid: Masjid
    let coordinate: CLLocationCoordinate2D
    @Binding var isExpanded: Bool
    let onDirections: () -> Void
    let onShare: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle and collapse button
            HStack {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.height
                        if translation > 0 { // Only allow downward drags
                            dragOffset = translation
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        let velocity = value.predictedEndLocation.y - value.location.y
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if translation > 50 || velocity > 100 {
                                isExpanded = false
                            }
                            dragOffset = 0
                        }
                        
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
            )
            
            if isExpanded {
                // Full content
                VStack(spacing: DesignSystem.Spacing.medium) {
                    // Masjid info
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Masjid image with better styling
                        Image(uiImage: masjid.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                    .stroke(Color.mSPrimary.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        
                        // Info
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                            Text(masjid.name)
                                .font(DesignSystem.Typography.headline(weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            
                            HStack(spacing: DesignSystem.Spacing.xxSmall) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(DesignSystem.Typography.caption(weight: .medium))
                                    .foregroundStyle(Color.mSPrimary)
                                
                                Text(masjid.location)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            // Coordinates with copy button
                            HStack(spacing: DesignSystem.Spacing.xxSmall) {
                                Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                                    .font(DesignSystem.Typography.footnote())
                                    .foregroundStyle(.tertiary)
                                    .monospaced()
                                
                                Button {
                                    UIPasteboard.general.string = "\(coordinate.latitude), \(coordinate.longitude)"
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                } label: {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Spacer(minLength: 0)
                    }
                    
                    // Action buttons with improved touch targets
                    HStack(spacing: DesignSystem.Spacing.small) {
                        // Directions button (primary)
                        Button(action: onDirections) {
                            HStack(spacing: DesignSystem.Spacing.xSmall) {
                                Image(systemName: "car.fill")
                                    .font(DesignSystem.Typography.body(weight: .semibold))
                                Text("Directions")
                                    .font(DesignSystem.Typography.body(weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                                    .fill(Color.mSPrimary.gradient)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Share button (secondary)
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(DesignSystem.Typography.body(weight: .semibold))
                                .foregroundStyle(Color.mSPrimary)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                                        .fill(Color.mSPrimary.opacity(0.15))
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.top, DesignSystem.Spacing.xSmall)
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.bottom, DesignSystem.Spacing.large)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Compact content
                HStack(spacing: DesignSystem.Spacing.medium) {
                    Image(uiImage: masjid.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(masjid.name)
                            .font(DesignSystem.Typography.body(weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Text(masjid.location)
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.vertical, DesignSystem.Spacing.medium)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 20, y: -5)
        )
        .offset(y: dragOffset)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Map Info Card (Legacy - kept for compatibility)
struct MapInfoCard: View {
    let masjid: Masjid
    let coordinate: CLLocationCoordinate2D
    let onDirections: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
            
            // Content
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Masjid image
                Image(uiImage: masjid.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
                
                // Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(masjid.name)
                        .font(DesignSystem.Typography.headline(weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Image(systemName: "mappin.circle.fill")
                            .font(DesignSystem.Typography.caption(weight: .medium))
                            .foregroundStyle(Color.mSPrimary)
                        
                        Text(masjid.location)
                            .font(DesignSystem.Typography.caption())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Coordinates
                    Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                        .font(DesignSystem.Typography.footnote())
                        .foregroundStyle(.tertiary)
                        .monospaced()
                }
                
                Spacer()
            }
            
            // Actions
            HStack(spacing: DesignSystem.Spacing.small) {
                Button(action: onDirections) {
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Image(systemName: "car.fill")
                            .font(DesignSystem.Typography.body(weight: .semibold))
                        Text("Directions")
                            .font(DesignSystem.Typography.body(weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                            .fill(Color.mSPrimary.gradient)
                    )
                }
                
                Button(action: {
                    shareLocation()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(DesignSystem.Typography.body(weight: .semibold))
                        .foregroundStyle(Color.mSPrimary)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                                .fill(Color.mSPrimary.opacity(0.1))
                        )
                }
            }
        }
        .padding(DesignSystem.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .dsShadow(DesignSystem.Shadow.heavy())
    }
    
    private func shareLocation() {
        let text = """
        \(masjid.name)
        📍 \(masjid.location)
        https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)
        """
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = []
            
            rootViewController.present(activityVC, animated: true)
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

#Preview {
    MasjidDetailMapView(
        location: "Al Haram, Madinah 42311, Saudi Arabia",
        masjid: Masjid(
            name: "Masjid al-Nabawi", 
            location: "Al Haram, Madinah 42311, Saudi Arabia", 
            phone: "+966 14 823 2400", 
            description: "The Prophet's Mosque is the second mosque built by the Islamic prophet Muhammad in Medina, after the Quba Mosque, as well as the second largest mosque and holiest site in Islam, after the Masjid al-Haram in Mecca, in the Saudi region of the Hejaz.", 
            image: UIImage(systemName: "building.2.crop.circle")!, 
            website: "https://haramain.com", 
            myMasjidUrl: "https://time.my-masjid.com", 
            isVisited: false,
            latitude: 24.4672,  // Madinah coordinates
            longitude: 39.6111
        )
    )
}

