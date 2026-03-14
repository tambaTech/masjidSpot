//
//  DirectionsOptionsView.swift
//  MasjidSpot
//
//  Created by Assistant
//

import SwiftUI
import CloudKit
import MapKit
import CoreLocation

struct DirectionsOptionsView: View {
    let mosques: [CKRecord]
    let locationGeocoder: CloudKitLocationGeocoder
    let locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Choose a mosque for directions") {
                    ForEach(mosques, id: \.recordID) { mosque in
                        HStack {
                            // Mosque Image
                            if let imageAsset = mosque["image"] as? CKAsset,
                               let imageData = try? Data(contentsOf: imageAsset.fileURL!),
                               let image = UIImage(data: imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "building.2")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mosque["name"] as? String ?? "Unknown")
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                if let location = mosque["location"] as? String {
                                    Text(location)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                if let distance = formattedDistance(to: mosque) {
                                    Text(distance)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                        .fontWeight(.medium)
                                }
                                
                                Button(action: {
                                    openDirections(to: mosque)
                                    dismiss()
                                }) {
                                    Image(systemName: "car.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Get Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openDirections(to mosque: CKRecord) {
        guard let locationString = mosque["location"] as? String, !locationString.isEmpty else {
            print("No location available for directions")
            return
        }
        
        // Try to get cached coordinate first
        if let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) {
            openMapsWithCoordinate(coordinate, mosqueName: mosque["name"] as? String ?? "Mosque")
        } else {
            // Fallback to location string
            openMapsWithLocationString(locationString)
        }
    }
    
    private func openMapsWithCoordinate(_ coordinate: CLLocationCoordinate2D, mosqueName: String) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = mosqueName
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    private func openMapsWithLocationString(_ locationString: String) {
        let encodedLocation = locationString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?daddr=\(encodedLocation)&dirflg=d"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func distanceToMosque(_ mosque: CKRecord, from userLocation: CLLocation) -> CLLocationDistance {
        guard let locationString = mosque["location"] as? String,
              let mosqueCoordinate = locationGeocoder.getCachedCoordinate(for: locationString) ?? getCoordinateFromLocation(locationString) else {
            return CLLocationDistance.greatestFiniteMagnitude
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
    
    private func getCoordinateFromLocation(_ locationString: String) -> CLLocationCoordinate2D? {
        // Sample coordinates for known locations
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
}

#Preview {
    let mockMosques: [CKRecord] = [
        {
            let record = CKRecord(recordType: "Mosque")
            record["name"] = "Al-Masjid Al-Haram"
            record["location"] = "Al Haram, Makkah 24231, Saudi Arabia"
            return record
        }(),
        {
            let record = CKRecord(recordType: "Mosque")
            record["name"] = "Masjid an-Nabawi"
            record["location"] = "Medina, Saudi Arabia"
            return record
        }()
    ]
    
    return DirectionsOptionsView(mosques: mockMosques, locationGeocoder: CloudKitLocationGeocoder(), locationManager: LocationManager())
}
