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
    // Remove @StateObject - geocoder should be passed in or accessed from environment
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                MapBalloonView()
                    .frame(width: 100, height: 70)
                    .foregroundStyle(.brandPrimary)
                
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
                        .foregroundStyle(.white)
                }
            }
            
            Text(mosque["name"] as? String ?? "Unknown")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.75))
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
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
        
        // Simplified - just open Maps with the location string
        openMapsWithLocationString(locationString)
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
