//  MosquePin
//
//  Created by Lamin Tamba on 6/12/25.
//

import MapKit
import SwiftUI
import CloudKit
import CoreLocation

struct MasjidMapView: View {
    
    @State private var position: CustomMapCameraPosition = .automatic
    @State private var cloudStore = MasjidCloudStore()
    @State private var locationGeocoder = CloudKitLocationGeocoder()
    @State private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var selectedMosque: CKRecord?
    @State private var showingMosqueDetail = false
    @State private var isLoadingMosqueDetail = false
    @State private var isLoading = true
    @State private var isGeocoding = false
    @State private var showingDirectionsOptions = false
    @State private var mapType: MKMapType = .standard
    @State private var showingLookAround = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showingLookAroundAlert = false
    @State private var lookAroundErrorMessage = ""
    @State private var is3DEnabled = true
    @State private var showingFilters = false
    @State private var sortBy: SortOption = .distance
    @State private var maxDistance: Double = 50.0 // km
    @State private var toastMessage: ToastMessage?
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system
    
    // Track user interaction to prevent auto-centering
    @State private var userHasInteractedWithMap = false
    @State private var shouldUpdateCameraPosition = true
    
    var interactionMode: MapInteractionModes = .all
    
    // Sort options
    enum SortOption: String, CaseIterable {
        case distance = "Distance"
        case name = "Name"
        case recent = "Recently Added"
    }
    
    // Filter and sort mosques based on search, distance, and filters
    private var filteredMosques: [CKRecord] {
        var mosques = cloudStore.cloudMosques
        
        // Apply search filter
        if !searchText.isEmpty {
            mosques = mosques.filter { mosque in
                let name = mosque.mosqueName ?? ""
                let location = mosque.mosqueLocation ?? ""
                return name.localizedStandardContains(searchText) ||
                       location.localizedStandardContains(searchText)
            }
        }
        
        // Apply distance filter if user location is available
        if let userLocation = locationManager.currentLocation {
            mosques = mosques.filter { mosque in
                let distance = distanceToMosque(mosque, from: userLocation)
                return distance <= maxDistance * 1000 // Convert km to meters
            }
        }
        
        // Sort mosques
        return sortMosques(mosques)
    }
    
    private func sortMosques(_ mosques: [CKRecord]) -> [CKRecord] {
        switch sortBy {
        case .distance:
            guard let userLocation = locationManager.currentLocation else {
                return mosques
            }
            return mosques.sorted { mosque1, mosque2 in
                let distance1 = distanceToMosque(mosque1, from: userLocation)
                let distance2 = distanceToMosque(mosque2, from: userLocation)
                return distance1 < distance2
            }
        case .name:
            return mosques.sorted { ($0.mosqueName ?? "") < ($1.mosqueName ?? "") }
        case .recent:
            return mosques.sorted { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) }
        }
    }
    
    var body: some View {
        ZStack {
            // Full-screen map
            CustomMapView(
                mapType: mapType,
                position: $position,
                mosques: filteredMosques,
                locationGeocoder: locationGeocoder,
                shouldUpdateCameraPosition: $shouldUpdateCameraPosition,
                is3DEnabled: is3DEnabled,
                onMosqueSelected: handleMosqueSelection,
                onLookAroundRequested: handleLookAroundRequest,
                onUserInteraction: handleUserInteraction
            )
            .ignoresSafeArea()
            .onTapGesture {
                // Dismiss keyboard when tapping the map
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            // Enhanced overlay controls
            VStack {
                EnhancedMapTopBarControls(
                    searchText: $searchText,
                    mapType: $mapType,
                    is3DEnabled: $is3DEnabled,
                    sortBy: $sortBy,
                    maxDistance: $maxDistance,
                    mosqueCount: filteredMosques.count,
                    totalCount: cloudStore.cloudMosques.count,
                    onFitAllMosques: { 
                        Task { 
                            await fitAllMosques()
                           // showToast("Showing all \(filteredMosques.count) mosques", type: .info)
                        }
                    },
                    onLookAround: { 
                        Task { 
                            await requestLookAround() 
                        } 
                    },
                    onRefreshData: { 
                        Task { 
                            await refreshData()
                            showToast("Data refreshed", type: .success)
                        } 
                    }
                )
                
                Spacer()
                
                EnhancedMapBottomBarControls(
                    userHasInteractedWithMap: userHasInteractedWithMap,
                    isLocationAvailable: locationManager.currentLocation != nil,
                    hasMosques: !filteredMosques.isEmpty,
                    nearestMosque: filteredMosques.first,
                    locationManager: locationManager,
                    onLookAround: { 
                        Task { 
                            await requestLookAround() 
                        } 
                    },
                    onDirections: { 
                        triggerHaptic()
                        showingDirectionsOptions = true 
                    },
                    onCenterLocation: {
                        triggerHaptic()
                        userHasInteractedWithMap = false
                        shouldUpdateCameraPosition = true
                        Task { 
                            await setInitialLocation()
                            showToast("Centered on your location", type: .info)
                        }
                    },
                    onNavigateToNearest: {
                        if let nearest = filteredMosques.first {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            openDirectionsToMosque(nearest)
                        }
                    }
                )
            }
            
            // Loading indicators with better styling
            if isLoading {
                EnhancedLoadingOverlay(message: "Loading mosques...", icon: "building.2")
            } else if isGeocoding {
                EnhancedLoadingOverlay(message: "Geocoding locations...", icon: "map")
            } else if isLoadingMosqueDetail {
                EnhancedLoadingOverlay(message: "Loading details...", icon: "info.circle")
            }
            
            // Enhanced empty state
            if !isLoading && filteredMosques.isEmpty {
                EnhancedEmptyStateView(
                    searchText: searchText,
                    totalMosques: cloudStore.cloudMosques.count,
                    maxDistance: maxDistance,
                    onClearFilters: {
                        searchText = ""
                        maxDistance = 50.0
                        showToast("Filters cleared", type: .info)
                    }
                )
            }
            
            // Toast notifications
            if let toast = toastMessage {
                VStack {
                    ToastView(message: toast.message, type: toast.type)
                        .padding(.top, 120)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            locationManager.requestLocationPermission()
            await loadMosques()
            if !userHasInteractedWithMap {
                await setInitialLocation()
            }
        }
        .sheet(isPresented: $showingMosqueDetail) {
            if let selectedMosque = selectedMosque {
                CloudMosqueDetailView(mosque: selectedMosque)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingDirectionsOptions) {
            DirectionsOptionsView(
                mosques: filteredMosques,
                locationGeocoder: locationGeocoder,
                locationManager: locationManager
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLookAround) {
            if let lookAroundScene = lookAroundScene {
                LookAroundView(scene: lookAroundScene)
                    .presentationDetents([.large])
            }
        }
        .alert("Look Around Unavailable", isPresented: $showingLookAroundAlert) {
            Button("OK") { }
        } message: {
            Text(lookAroundErrorMessage)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleMosqueSelection(_ mosque: CKRecord) {
        triggerHaptic()
        isLoadingMosqueDetail = true
        selectedMosque = mosque
        
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            isLoadingMosqueDetail = false
            showingMosqueDetail = true
        }
    }
    
    private func handleLookAroundRequest(_ scene: MKLookAroundScene) {
        lookAroundScene = scene
        showingLookAround = true
    }
    
    private func handleUserInteraction() {
        userHasInteractedWithMap = true
        // Dismiss keyboard when user interacts with map
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Helper Functions
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func showToast(_ message: String, type: ToastType) {
        withAnimation(.spring(response: 0.3)) {
            toastMessage = ToastMessage(message: message, type: type)
        }
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.3)) {
                toastMessage = nil
            }
        }
    }
    
    private func openDirectionsToMosque(_ mosque: CKRecord) {
        guard let locationString = mosque.mosqueLocation else {
            showToast("Location not available", type: .error)
            return
        }
        
        let encodedLocation = locationString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?daddr=\(encodedLocation)&dirflg=d"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
            showToast("Opening directions...", type: .success)
        }
    }
    
    private func loadMosques() async {
        isLoading = true
        await cloudStore.fetchCloudMosques()
        isLoading = false
        
        // Start geocoding locations in the background
        Task {
            await locationGeocoder.geocodeAllMosqueLocations(cloudStore.cloudMosques)
        }
        
        // Only fit all mosques if user hasn't started exploring
        if !userHasInteractedWithMap {
            await fitAllMosques()
        }
    }
    
    private func getCoordinateFromLocation(_ locationString: String) -> CLLocationCoordinate2D? {
        return MosqueCoordinateHelper.getCoordinate(for: locationString)
    }
    
    private func distanceToMosque(_ mosque: CKRecord, from userLocation: CLLocation) -> CLLocationDistance {
        guard let locationString = mosque.mosqueLocation else {
            return CLLocationDistance.greatestFiniteMagnitude
        }
        
        return MosqueCoordinateHelper.distanceToMosque(
            locationString: locationString,
            from: userLocation,
            geocoder: locationGeocoder
        )
    }
    
    private func formattedDistance(to mosque: CKRecord) -> String? {
        guard let userLocation = locationManager.currentLocation else { return nil }
        
        let distance = distanceToMosque(mosque, from: userLocation)
        return MosqueCoordinateHelper.formatDistance(distance)
    }
    
    @MainActor
    private func setInitialLocation() async {
        // Disable auto-updates temporarily
        shouldUpdateCameraPosition = false
        
        if let userLocation = locationManager.currentLocation {
            // Zoom to user's location with a closer view (approximately 2-3 km radius)
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            position = .region(region)
        } else {
            // Fallback to default location if user location is not available
            let defaultCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262) // Mecca
            let region = MKCoordinateRegion(center: defaultCoordinate, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
            position = .region(region)
        }
        
        // Re-enable auto-updates after a brief delay
        try? await Task.sleep(for: .milliseconds(500))
        shouldUpdateCameraPosition = true
    }
    
    @MainActor
    private func fitAllMosques() async {
        // Disable auto-updates temporarily
        shouldUpdateCameraPosition = false
        
        // Get all coordinates for mosques
        var coordinates: [CLLocationCoordinate2D] = []
        
        for mosque in filteredMosques {
            if let locationString = mosque["location"] as? String,
               let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) ?? getCoordinateFromLocation(locationString) {
                coordinates.append(coordinate)
            }
        }
        
        // If we have coordinates, fit them all
        if !coordinates.isEmpty {
            let mapRect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
                let point = MKMapPoint(coordinate)
                let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
                return rect.union(pointRect)
            }
            
            let region = MKCoordinateRegion(mapRect)
            position = .region(region)
        } else {
            // Fallback to default region
            let defaultCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262) // Mecca
            let region = MKCoordinateRegion(center: defaultCoordinate, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
            position = .region(region)
        }
        
        // Re-enable auto-updates after a brief delay
        try? await Task.sleep(for: .milliseconds(500))
        shouldUpdateCameraPosition = true
    }
    
    private func refreshData() async {
        // Don't reset user interaction state on refresh
        await loadMosques()
        // Only return to initial location if user hasn't moved the map
        if !userHasInteractedWithMap {
            await setInitialLocation()
        }
    }
    
    @MainActor
    private func requestLookAroundForMosque(_ mosque: CKRecord) async {
        guard let locationString = mosque["location"] as? String,
              let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) ?? getCoordinateFromLocation(locationString) else {
            print("No coordinate available for mosque")
            return
        }
        
        let request = MKLookAroundSceneRequest(coordinate: coordinate)
        
        do {
            let scene = try await request.scene
            if let scene = scene {
                lookAroundScene = scene
                showingLookAround = true
            } else {
                print("Look Around not available for this mosque location")
            }
        } catch {
            print("Failed to load Look Around scene for mosque: \(error)")
        }
    }
    
    @MainActor
    private func requestLookAround() async {
        // Show loading indicator
        isLoading = true
        
        // Start with user location for Look Around
        guard let userLocation = locationManager.currentLocation else {
            isLoading = false
            lookAroundErrorMessage = "Location services are not available. Please enable location access to use Look Around."
            showingLookAroundAlert = true
            return
        }
        
        let request = MKLookAroundSceneRequest(coordinate: userLocation.coordinate)
        
        do {
            if let scene = try await request.scene {
                isLoading = false
                lookAroundScene = scene
                showingLookAround = true
            } else {
                isLoading = false
                lookAroundErrorMessage = "Look Around is not available for this area. Look Around coverage is limited to select cities and regions."
                showingLookAroundAlert = true
            }
        } catch {
            isLoading = false
            lookAroundErrorMessage = "Failed to load Look Around: \(error.localizedDescription)"
            showingLookAroundAlert = true
        }
    }
}

// Define the custom camera position enum outside of the CustomMapView
enum CustomMapCameraPosition {
    case region(MKCoordinateRegion)
    case automatic
}

// Custom MapView that supports different map types
struct CustomMapView: UIViewRepresentable {
    let mapType: MKMapType
    @Binding var position: CustomMapCameraPosition
    let mosques: [CKRecord]
    let locationGeocoder: CloudKitLocationGeocoder
    @Binding var shouldUpdateCameraPosition: Bool
    let is3DEnabled: Bool
    let onMosqueSelected: (CKRecord) -> Void
    let onLookAroundRequested: (MKLookAroundScene) -> Void
    let onUserInteraction: () -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Enable 3D buildings and terrain
        mapView.showsBuildings = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        
        // Set initial camera with pitch for 3D effect
        let camera = mapView.camera
        camera.pitch = 45 // Angle the camera for 3D view
        camera.altitude = 500 // Height above ground
        mapView.camera = camera
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map type
        mapView.mapType = mapType
        
        // Update 3D pitch
        if is3DEnabled {
            if mapView.camera.pitch < 45 {
                let camera = mapView.camera.copy() as! MKMapCamera
                camera.pitch = 45
                mapView.setCamera(camera, animated: true)
            }
        } else {
            if mapView.camera.pitch > 0 {
                let camera = mapView.camera.copy() as! MKMapCamera
                camera.pitch = 0
                mapView.setCamera(camera, animated: true)
            }
        }
        
        // Update camera position when requested
        if shouldUpdateCameraPosition {
            switch position {
            case .region(let region):
                let currentCenter = mapView.region.center
                let newCenter = region.center
                // Only update if position has meaningfully changed
                let latDiff = abs(currentCenter.latitude - newCenter.latitude)
                let lonDiff = abs(currentCenter.longitude - newCenter.longitude)
                if latDiff > 0.001 || lonDiff > 0.001 {
                    mapView.setRegion(region, animated: true)
                }
            case .automatic:
                // Do nothing – let the map decide
                break
            }
        }
        
        // Update annotations
        let existingAnnotations = mapView.annotations.compactMap { $0 as? MosqueAnnotation }
        let existingIDs = Set(existingAnnotations.compactMap { $0.mosque?.recordID.recordName })
        
        // Add new annotations
        for mosque in mosques {
            let recordID = mosque.recordID.recordName
            if !existingIDs.contains(recordID) {
                if let locationString = mosque["location"] as? String,
                   let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) ?? getCoordinateFromLocation(locationString) {
                    let annotation = MosqueAnnotation()
                    annotation.coordinate = coordinate
                    annotation.title = mosque["name"] as? String ?? "Mosque"
                    annotation.subtitle = locationString
                    annotation.mosque = mosque
                    mapView.addAnnotation(annotation)
                }
            }
        }
        
        // Remove annotations that are no longer in the filtered list
        let currentIDs = Set(mosques.map { $0.recordID.recordName })
        for annotation in existingAnnotations {
            if let recordID = annotation.mosque?.recordID.recordName, !currentIDs.contains(recordID) {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    private func getCoordinateFromLocation(_ locationString: String) -> CLLocationCoordinate2D? {
        let sampleLocations = [
            "Al Haram, Makkah 24231, Saudi Arabia": CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262),
            "Medina": CLLocationCoordinate2D(latitude: 24.4539, longitude: 39.5970),
            "Jerusalem": CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)
        ]
        
        if let coordinate = sampleLocations[locationString] {
            return coordinate
        }
        
        for (location, coordinate) in sampleLocations {
            if locationString.localizedCaseInsensitiveContains(location) ||
               location.localizedCaseInsensitiveContains(locationString) {
                return coordinate
            }
        }
        
        return nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Only track user interaction if we should be monitoring camera updates
            guard parent.shouldUpdateCameraPosition else { return }
            
            if let gestureRecognizers = mapView.gestureRecognizers {
                for recognizer in gestureRecognizers {
                    if recognizer.state == .began || recognizer.state == .changed {
                        parent.onUserInteraction()
                        break
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            guard let mosqueAnnotation = annotation as? MosqueAnnotation,
                  let mosque = mosqueAnnotation.mosque else {
                return nil
            }
            
            let identifier = "CloudMosquePin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            
            guard let view = annotationView else { return nil }
            
            let hostingController = UIHostingController(rootView: CloudMosqueAnnotationView(mosque: mosque))
            hostingController.view.backgroundColor = .clear
            
            let size = hostingController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            hostingController.view.frame = CGRect(origin: CGPoint.zero, size: size)
            
            view.subviews.forEach { $0.removeFromSuperview() }
            view.addSubview(hostingController.view)
            
            view.canShowCallout = false
            view.frame = hostingController.view.frame
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let mosqueAnnotation = view.annotation as? MosqueAnnotation,
                  let mosque = mosqueAnnotation.mosque else { return }
            
            parent.onMosqueSelected(mosque)
            
            Task {
                let request = MKLookAroundSceneRequest(coordinate: mosqueAnnotation.coordinate)
                do {
                    let scene = try await request.scene
                    if let scene = scene {
                        await MainActor.run {
                            parent.onLookAroundRequested(scene)
                        }
                    }
                } catch {
                    print("Look Around not available for this mosque location: \(error)")
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let mosqueAnnotation = view.annotation as? MosqueAnnotation,
                  let mosque = mosqueAnnotation.mosque else { return }
            
            parent.onMosqueSelected(mosque)
        }
    }
}

// Custom annotation class to hold mosque data
class MosqueAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var subtitle: String?
    var mosque: CKRecord?
}

// Look Around View wrapper
struct LookAroundView: View {
    let scene: MKLookAroundScene
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            LookAroundViewController(scene: scene)
                .ignoresSafeArea()
                .navigationTitle("Look Around")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// UIKit wrapper for MKLookAroundViewController
struct LookAroundViewController: UIViewControllerRepresentable {
    let scene: MKLookAroundScene
    
    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        let controller = MKLookAroundViewController(scene: scene)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    MasjidMapView()
}
// MARK: - Enhanced UI Components

// Toast notification system
struct ToastMessage: Equatable {
    let message: String
    let type: ToastType
}

enum ToastType {
    case success, error, info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(type.color)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.bPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .overlay(
            Capsule()
                .strokeBorder(type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// Enhanced Top Bar Controls
struct EnhancedMapTopBarControls: View {
    @Binding var searchText: String
    @Binding var mapType: MKMapType
    @Binding var is3DEnabled: Bool
    @Binding var sortBy: MasjidMapView.SortOption
    @Binding var maxDistance: Double
    let mosqueCount: Int
    let totalCount: Int
    let onFitAllMosques: () -> Void
    let onLookAround: () -> Void
    let onRefreshData: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Search masjids...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17))
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            // Dismiss keyboard when search is submitted
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = ""
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            // Dismiss keyboard when clearing search
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // Menu button
                Menu {
                    Section("Map Style") {
                        Button(action: { mapType = .standard }) {
                            Label("Standard", systemImage: mapType == .standard ? "checkmark" : "map")
                        }
                        
                        Button(action: { mapType = .satellite }) {
                            Label("Satellite", systemImage: mapType == .satellite ? "checkmark" : "globe.americas")
                        }
                        
                        Button(action: { mapType = .hybrid }) {
                            Label("Hybrid", systemImage: mapType == .hybrid ? "checkmark" : "globe.americas.fill")
                        }
                    }
                    
                    Section("Sort By") {
                        ForEach(MasjidMapView.SortOption.allCases, id: \.self) { option in
                            Button(action: { sortBy = option }) {
                                Label(option.rawValue, systemImage: sortBy == option ? "checkmark" : "arrow.up.arrow.down")
                            }
                        }
                    }
                    
                    Section("View Options") {
                        Button(action: { is3DEnabled.toggle() }) {
                            Label(is3DEnabled ? "2D View" : "3D View",
                                  systemImage: is3DEnabled ? "view.2d" : "view.3d")
                        }
                        
                        Button(action: onFitAllMosques) {
                            Label("Fit All Mosques", systemImage: "viewfinder")
                        }
                        
                        Button(action: onLookAround) {
                            Label("Look Around", systemImage: "binoculars.fill")
                        }
                    }
                    
                    Section("Distance Filter") {
                        Picker("Max Distance", selection: $maxDistance) {
                            Text("5 km").tag(5.0)
                            Text("10 km").tag(10.0)
                            Text("25 km").tag(25.0)
                            Text("50 km").tag(50.0)
                            Text("100 km").tag(100.0)
                        }
                    }
                    
                    Section("Data") {
                        Button(action: onRefreshData) {
                            Label("Refresh Data", systemImage: "arrow.clockwise")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.bPrimary)
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }
}

// Enhanced Bottom Bar Controls
struct EnhancedMapBottomBarControls: View {
    let userHasInteractedWithMap: Bool
    let isLocationAvailable: Bool
    let hasMosques: Bool
    let nearestMosque: CKRecord?
    let locationManager: LocationManager
    let onLookAround: () -> Void
    let onDirections: () -> Void
    let onCenterLocation: () -> Void
    let onNavigateToNearest: () -> Void
    
    private var distanceToNearest: String? {
        guard let nearestMosque = nearestMosque,
              let userLocation = locationManager.currentLocation,
              let locationString = nearestMosque.mosqueLocation else {
            return nil
        }
        
        let distance = MosqueCoordinateHelper.distanceToMosque(
            locationString: locationString,
            from: userLocation,
            geocoder: CloudKitLocationGeocoder()
        )
        
        return MosqueCoordinateHelper.formatDistance(distance)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Quick navigate to nearest mosque
            if let nearestMosque = nearestMosque, let distance = distanceToNearest {
                Button(action: onNavigateToNearest) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Navigate to Nearest")
                                .font(.system(size: 13, weight: .semibold))
                            Text("\(nearestMosque.mosqueName ?? "Mosque") • \(distance)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)
                }
            }
            
            HStack(alignment: .bottom) {
                // Look Around button
                Button(action: onLookAround) {
                    Image(systemName: "binoculars.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                
                Spacer()
                
                VStack(spacing: 14) {
                    // Directions button
                    Button(action: onDirections) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(
                                Circle()
                                    .fill(hasMosques ? Color.green.gradient : Color.gray.gradient)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .shadow(color: hasMosques ? .green.opacity(0.4) : .clear, radius: 12, y: 6)
                    }
                    .disabled(!hasMosques)
                    
                    // Location tracking button
                    Button(action: onCenterLocation) {
                        Image(systemName: userHasInteractedWithMap ? "location" : "location.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(userHasInteractedWithMap ? .white : .blue)
                            .frame(width: 54, height: 54)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                userHasInteractedWithMap ? Color.white.opacity(0.2) : Color.bPrimary.opacity(0.5),
                                                lineWidth: 2
                                            )
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    .disabled(!isLocationAvailable)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }
}

// Enhanced Loading Overlay
struct EnhancedLoadingOverlay: View {
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
            }
            
            VStack(spacing: 4) {
                Text(message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.bPrimary)
                
                Text("Please wait...")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
    }
}

// Enhanced Empty State View
struct EnhancedEmptyStateView: View {
    let searchText: String
    let totalMosques: Int
    let maxDistance: Double
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text("No Mosques Found")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.brandPrimary)
                
                if !searchText.isEmpty {
                    Text("No results for \"\(searchText)\"")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                } else if totalMosques > 0 {
                    Text("Try adjusting your distance filter")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    
                    Text("Current range: \(Int(maxDistance)) km")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.brandPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.bPrimary.opacity(0.1), in: Capsule())
                }
            }
            
            if !searchText.isEmpty || totalMosques > 0 {
                Button(action: onClearFilters) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Clear Filters")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.bPrimary.gradient, in: Capsule())
                    .shadow(color: .brandPrimary.opacity(0.3), radius: 8, y: 4)
                }
            }
        }
        .padding(40)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }
}


