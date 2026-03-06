//
//  CloudMosqueAnnotationView.swift
//  MasjidSpot
//
//  Created by Assistant
//

import SwiftUI
import CloudKit
import MapKit
import CoreLocation

struct CloudMosqueAnnotationView: View {
    var mosque: CKRecord
    @StateObject private var locationGeocoder = CloudKitLocationGeocoder()
    
    var body: some View {
        VStack {
            ZStack {
                MapBalloonView()
                    .frame(width: 100, height: 70)
                    .foregroundColor(.brandPrimary)
                
                if let imageAsset = mosque["image"] as? CKAsset,
                   let imageData = try? Data(contentsOf: imageAsset.fileURL!),
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "building.2")
                        .font(.title2)
                        .foregroundColor(.brandPrimary)
                }
            }
            Text(mosque["name"] as? String ?? "Unknown")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.color)
                .lineLimit(1)
        }
        .contextMenu {
            Button(action: {
                openDirections()
            }) {
                HStack {
                    Text("Get Directions")
                    Image(systemName: "car")
                }
            }
            
            if let phone = mosque["phone"] as? String, !phone.isEmpty {
                Button(action: {
                    callMosque(phone: phone)
                }) {
                    HStack {
                        Text("Call Mosque")
                        Image(systemName: "phone")
                    }
                }
            }
            
            if let website = mosque["website"] as? String, !website.isEmpty {
                Button(action: {
                    if let url = URL(string: website) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Visit Website")
                        Image(systemName: "safari")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func openDirections() {
        guard let locationString = mosque["location"] as? String, !locationString.isEmpty else {
            print("No location available for directions")
            return
        }
        
        // Try to get cached coordinate first
        if let coordinate = locationGeocoder.getCachedCoordinate(for: locationString) {
            openMapsWithCoordinate(coordinate)
        } else {
            // Fallback to location string
            openMapsWithLocationString(locationString)
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
        let encodedLocation = locationString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?daddr=\(encodedLocation)&dirflg=d"
    
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func callMosque(phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
}


#Preview {
    // Create a mock CKRecord for preview
    let mockRecord = CKRecord(recordType: "Mosque")
    mockRecord["name"] = "Sample Mosque"
    
    return CloudMosqueAnnotationView(mosque: mockRecord)
}
