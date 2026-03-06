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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let imageAsset = mosque["image"] as? CKAsset,
                       let imageData = try? Data(contentsOf: imageAsset.fileURL!),
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 445)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Name
                        Text(mosque["name"] as? String ?? "Unknown")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Location
                        if let location = mosque["location"] as? String, !location.isEmpty {
                            Label(location, systemImage: "location")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Phone
                        if let phone = mosque["phone"] as? String, !phone.isEmpty {
                            Label(phone, systemImage: "phone")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Description
                        if let description = mosque["description"] as? String, !description.isEmpty {
                            Text("About")
                                .font(.headline)
                                .padding(.top)
                            
                            Text(description)
                                .font(.body)
                                .lineLimit(nil)
                        }
                        
                        // Website
                        if let website = mosque["website"] as? String, !website.isEmpty {
                            Button(action: {
                                showWebsite = true
                            }) {
                                HStack {
                                    Image(systemName: "safari.fill")
                                        .font(.title2)
                                    Text("Visit Website")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        
                        // My Masjid URL
                        if let myMasjidUrl = mosque["myMasjidUrl"] as? String, !myMasjidUrl.isEmpty {
                            Button(action: {
                                showMyMasjid = true
                            }) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.title2)
                                    Text("Prayer Times")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.pink)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Directions Button
                            Button(action: {
                                openDirections()
                            }) {
                                HStack {
                                    Image(systemName: "car.fill")
                                        .font(.title2)
                                    Text("Get Directions")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            // Call Button (if phone number exists)
                            if let phone = mosque["phone"] as? String, !phone.isEmpty {
                                Button(action: {
                                    callMosque(phone: phone)
                                }) {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                            .font(.title2)
                                        Text("Call Mosque")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    
                }
                .padding(.horizontal, 20) // Consistent horizontal padding
                .padding(.vertical, 16) // Add vertical padding
                .safeAreaPadding(.horizontal, 4) // Additional safe area padding
            }
            
            .navigationTitle("Mosque Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color(.systemBackground)) // Ensure proper background
        .sheet(isPresented: $showWebsite) {
            if let website = mosque["website"] as? String, !website.isEmpty {
                SafariView(url: website)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showMyMasjid) {
            if let myMasjidUrl = mosque["myMasjidUrl"] as? String, !myMasjidUrl.isEmpty {
                SafariView(url: myMasjidUrl)
            } else {
                EmptyView()
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

#Preview {
    let mockRecord = CKRecord(recordType: "Mosque")
    mockRecord["name"] = "Sample Mosque"
    mockRecord["location"] = "123 Sample Street, Sample City"
    mockRecord["description"] = "This is a sample mosque for preview purposes."
    
    return CloudMosqueDetailView(mosque: mockRecord)
}
