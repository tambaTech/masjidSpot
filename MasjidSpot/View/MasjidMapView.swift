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
    @StateObject private var locationGeocoder = CloudKitLocationGeocoder()
    @StateObject private var locationManager = LocationManager()
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
    
    var interactionMode: MapInteractionModes = .all
    
    // Filter and sort mosques based on search and distance from user
    private var filteredMosques: [CKRecord] {
        let mosques: [CKRecord]
        
        if searchText.isEmpty {
            mosques = cloudStore.cloudMosques
        } else {
            mosques = cloudStore.cloudMosques.filter { mosque in
                let name = mosque["name"] as? String ?? ""
                let location = mosque["location"] as? String ?? ""
                return name.localizedStandardContains(searchText) ||
                       location.localizedStandardContains(searchText)
            }
        }
        
        // Sort by distance from user location if available
        guard let userLocation = locationManager.currentLocation else {
            return mosques
        }
        
        return mosques.sorted { mosque1, mosque2 in
            let distance1 = distanceToMosque(mosque1, from: userLocation)
            let distance2 = distanceToMosque(mosque2, from: userLocation)
            return distance1 < distance2
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CustomMapView(
                    mapType: mapType,
                    position: $position,
                    mosques: filteredMosques,
                    locationGeocoder: locationGeocoder,
                    onMosqueSelected: { mosque in
                        isLoadingMosqueDetail = true
                        selectedMosque = mosque
                        
                        // Simulate loading delay for mosque details
                        Task {
                            // Add a small delay to show the loading indicator
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            await MainActor.run {
                                isLoadingMosqueDetail = false
                                showingMosqueDetail = true
                            }
                        }
                    },
                    onLookAroundRequested: { scene in
                        lookAroundScene = scene
                        showingLookAround = true
                    }
                )
                .ignoresSafeArea()
                
                // Loading indicator
                if isLoading {
                    VStack {
                        ProgressView("Loading mosques...")
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(12)
                    }
                } else if isGeocoding {
                    VStack {
                        ProgressView("Geocoding locations...")
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(12)
                    }
                } else if isLoadingMosqueDetail {
                    VStack {
                        ProgressView("Loading mosque details...")
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(12)
                    }
                }
                
                // Empty state
                if !isLoading && filteredMosques.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "building.2")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No mosques found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                        if !searchText.isEmpty {
                            Text("Try adjusting your search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                
                // Floating Directions Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingDirectionsOptions = true
                        }) {
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .disabled(filteredMosques.isEmpty)
                        .padding(.trailing)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Masjid Map")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search masjids...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await setInitialLocation()
                        }
                    }) {
                        Image(systemName: "location.fill")
                    }
                    .disabled(locationManager.currentLocation == nil)
                }
                
             
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Map Style") {
                            Button(action: {
                                mapType = .standard
                            }) {
                                HStack {
                                    Label("Standard", systemImage: "map")
                                    Spacer()
                                    if mapType == .standard {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                            }
                            
                            Button(action: {
                                mapType = .satellite
                            }) {
                                HStack {
                                    Label("Satellite", systemImage: "globe.americas")
                                    Spacer()
                                    if mapType == .satellite {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                            }
                            
                            Button(action: {
                                mapType = .hybrid
                            }) {
                                HStack {
                                    Label("Hybrid", systemImage: "globe.americas.fill")
                                    Spacer()
                                    if mapType == .hybrid {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.brandPrimary)
                                    }
                                }
                            }
                        }
                        
                        Section("View Options") {
                            Button(action: {
                                Task {
                                    await fitAllMosques()
                                }
                            }) {
                                Label("Fit All Mosques", systemImage: "viewfinder")
                            }
                            
                            Button(action: {
                                Task {
                                    await setInitialLocation()
                                }
                            }) {
                                Label("My Location", systemImage: "location.fill")
                            }
                            
                            Button(action: {
                                Task {
                                    await requestLookAround()
                                }
                            }) {
                                Label("Look Around", systemImage: "binoculars")
                            }
                        }
                        
                        Section("Data") {
                            Button(action: {
                                Task {
                                    await refreshData()
                                }
                            }) {
                                Label("Refresh Data", systemImage: "arrow.clockwise")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            locationManager.requestLocationPermission()
            await loadMosques()
            await setInitialLocation()
        }
        .sheet(isPresented: $showingMosqueDetail) {
            if let selectedMosque = selectedMosque {
                CloudMosqueDetailView(mosque: selectedMosque)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingDirectionsOptions) {
            DirectionsOptionsView(mosques: filteredMosques, locationGeocoder: locationGeocoder, locationManager: locationManager)
                .presentationDetents([.medium])
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
    
    private func loadMosques() async {
        isLoading = true
        await cloudStore.fetchCloudMosques()
        isLoading = false
        
        // Start geocoding locations in the background
        Task {
            await locationGeocoder.geocodeAllMosqueLocations(cloudStore.cloudMosques)
        }
        
        await fitAllMosques()
    }
    
    private func getCoordinateFromLocation(_ locationString: String) -> CLLocationCoordinate2D? {
        // This is a synchronous geocoding placeholder
        // In a real app, you'd want to geocode these locations ahead of time
        // and store coordinates in CloudKit or cache them locally
        
        // For now, return some sample coordinates for known locations
        let sampleLocations = [
            "Al Haram, Makkah 24231, Saudi Arabia": CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262),
            "Medina": CLLocationCoordinate2D(latitude: 24.4539, longitude: 39.5970),
            "Jerusalem": CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)
        ]
        
        // Check for exact matches first
        if let coordinate = sampleLocations[locationString] {
            return coordinate
        }
        
        // Check for partial matches
        for (location, coordinate) in sampleLocations {
            if locationString.localizedCaseInsensitiveContains(location) ||
               location.localizedCaseInsensitiveContains(locationString) {
                return coordinate
            }
        }
        
        return nil
    }
    
    private func distanceToMosque(_ mosque: CKRecord, from userLocation: CLLocation) -> CLLocationDistance {
        guard let locationString = mosque["location"] as? String,
              let mosqueCoordinate = locationGeocoder.getCachedCoordinate(for: locationString) ?? getCoordinateFromLocation(locationString) else {
            return CLLocationDistance.greatestFiniteMagnitude // Put mosques without coordinates at the end
        }
        
        let mosqueLocation = CLLocation(latitude: mosqueCoordinate.latitude, longitude: mosqueCoordinate.longitude)
        return userLocation.distance(from: mosqueLocation)
    }
    
    private func formattedDistance(to mosque: CKRecord) -> String? {
        guard let userLocation = locationManager.currentLocation else { return nil }
        
        let distance = distanceToMosque(mosque, from: userLocation)
        if distance == CLLocationDistance.greatestFiniteMagnitude {
            return nil
        }
        
        let distanceInKm = distance / 1000.0
        if distanceInKm < 1.0 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distanceInKm)
        }
    }
    
    @MainActor
    private func setInitialLocation() async {
        if let userLocation = locationManager.currentLocation {
            // Center on user's location with a reasonable zoom level
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            position = .region(region)
        } else {
            // Fallback to default location if user location is not available
            let defaultCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262) // Mecca
            let region = MKCoordinateRegion(center: defaultCoordinate, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
            position = .region(region)
        }
    }
    
    @MainActor
    private func fitAllMosques() async {
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
    }
    
    private func refreshData() async {
        await loadMosques()
        await setInitialLocation()
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
        // Try to get Look Around scene for the nearest mosque first
        if let nearestMosque = filteredMosques.first,
           let locationString = nearestMosque["location"] as? String,
           let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) ?? getCoordinateFromLocation(locationString) {
            
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            
            do {
                let scene = try await request.scene
                if let scene = scene {
                    lookAroundScene = scene
                    showingLookAround = true
                    return
                }
            } catch {
                print("Failed to load Look Around scene for mosque: \(error)")
            }
        }
        
        // Fallback to user location if mosque Look Around isn't available
        guard let userLocation = locationManager.currentLocation else {
            lookAroundErrorMessage = "Location services are not available. Please enable location access to use Look Around."
            showingLookAroundAlert = true
            return
        }
        
        let request = MKLookAroundSceneRequest(coordinate: userLocation.coordinate)
        
        do {
            let scene = try await request.scene
            if let scene = scene {
                lookAroundScene = scene
                showingLookAround = true
            } else {
                lookAroundErrorMessage = "Look Around is not available for this area. Look Around coverage is limited to select cities and regions."
                showingLookAroundAlert = true
            }
        } catch {
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
    let onMosqueSelected: (CKRecord) -> Void
    let onLookAroundRequested: (MKLookAroundScene) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        
        // Update annotations
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        for mosque in mosques {
            if let locationString = mosque["location"] as? String,
               let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) ?? getCoordinateFromLocation(locationString) {
                
                let annotation = MosqueAnnotation()
                annotation.coordinate = coordinate
                annotation.title = mosque["name"] as? String ?? "Unknown"
                annotation.subtitle = locationString
                annotation.mosque = mosque
                mapView.addAnnotation(annotation)
            }
        }
        
        // Update camera position
        updateCameraPosition(mapView: mapView, position: position)
    }
    
    private func updateCameraPosition(mapView: MKMapView, position: CustomMapCameraPosition) {
        switch position {
        case .region(let region):
            mapView.setRegion(region, animated: true)
        case .automatic:
            // Do nothing – let the map decide
            break
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
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize the user location annotation
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
            
            // Use your custom CloudMosqueAnnotationView
            let hostingController = UIHostingController(rootView: CloudMosqueAnnotationView(mosque: mosque))
            hostingController.view.backgroundColor = .clear
            
            // Set the size for the custom view
            let size = hostingController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            hostingController.view.frame = CGRect(origin: CGPoint.zero, size: size)
            
            // Remove previous subviews and add the new one
            view.subviews.forEach { $0.removeFromSuperview() }
            view.addSubview(hostingController.view)
            
            // Configure the annotation view
            view.canShowCallout = false // Disable default callout since we have custom balloon
            view.frame = hostingController.view.frame
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let mosqueAnnotation = view.annotation as? MosqueAnnotation,
                  let mosque = mosqueAnnotation.mosque else { return }
            
            parent.onMosqueSelected(mosque)
            
            // Also try to get Look Around scene for this location
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
            // Handle tap on custom CloudMosqueAnnotationView balloon pins
            guard let mosqueAnnotation = view.annotation as? MosqueAnnotation,
                  let mosque = mosqueAnnotation.mosque else { return }
            
            // Trigger the mosque detail sheet when user taps the balloon pin
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
struct LookAroundView: UIViewControllerRepresentable {
    let scene: MKLookAroundScene
    
    func makeUIViewController(context: Context) -> UIViewController {
        let lookAroundController = MKLookAroundViewController(scene: scene)
        let navController = UINavigationController(rootViewController: lookAroundController)
        
        // Add a close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismissLookAround)
        )
        lookAroundController.navigationItem.rightBarButtonItem = closeButton
        lookAroundController.navigationItem.title = "Look Around"
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        @objc func dismissLookAround() {
            // The presentation will be handled by SwiftUI
        }
    }
}

#Preview {
    MasjidMapView()
}
