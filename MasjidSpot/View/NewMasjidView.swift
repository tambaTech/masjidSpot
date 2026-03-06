//
//  NewMasjidView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//

import CoreLocation
import SwiftUI
import SwiftData
import MapKit



struct NewMasjidView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        
        var id: Int {
            hashValue
        }
    }
    
    @State private var photoSource: PhotoSource?
    @State private var showPhotoOptions = false
    
    @Bindable private var masjidFormViewModel: MasjidFormViewModel
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    
                    Image(uiImage: masjidFormViewModel.image)
                        .resizable()
                        .scaledToFit()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20.0))
                        .padding(.bottom)
                        .onTapGesture {
                            self.showPhotoOptions.toggle()
                        }
                    
                    
                    FormTextField("Masjid name", text: $masjidFormViewModel.name)
                    
                    FormTextField("Address" , text: $masjidFormViewModel.location)
                    
                    FormTextField("Phone" , text: $masjidFormViewModel.phone)
                    
                    FormTextField("Website url" , text: $masjidFormViewModel.website)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    
                    FormTextField("My-masjid url" , text: $masjidFormViewModel.myMasjidUrl)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    
                    FormTextView("Description" , text: $masjidFormViewModel.summary, height: 100)
                    
                    
                }
                .padding()
            }
            // Navigation bar configuration
            .navigationTitle("Add Masjid")
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                    
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    Button {
                        save()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(Color("NavigationBarTitle"))
                    }
                    
                }
            }
        }
        .confirmationDialog("Choose your photo source", isPresented: $showPhotoOptions, titleVisibility: .visible) {
            
            Button("Camera") {
                self.photoSource = .camera
            }
            
            Button("Photo Library") {
                self.photoSource = .photoLibrary
            }
        }
        .fullScreenCover(item: $photoSource) { source in
            switch source {
            case .photoLibrary: ImagePicker(sourceType: .photoLibrary, selectedImage: $masjidFormViewModel.image).ignoresSafeArea()
            case .camera: ImagePicker(sourceType: .camera, selectedImage: $masjidFormViewModel.image).ignoresSafeArea()
            }
        }
        .tint(.mSPrimary)
    }
    
    init() {
        let viewModel = MasjidFormViewModel()
        viewModel.image = UIImage(named: "newphoto") ?? UIImage()
        masjidFormViewModel = viewModel
    }
    
    
    private func save() {
        // First create the mosque with explicit latitude/longitude parameters
        let masjid = Masjid(
            name: masjidFormViewModel.name,
            location: masjidFormViewModel.location,
            phone: masjidFormViewModel.phone,
            description: masjidFormViewModel.summary,
            image: masjidFormViewModel.image,
            website: masjidFormViewModel.website,
            myMasjidUrl: masjidFormViewModel.myMasjidUrl,
            isVisited: false,
            latitude: 0.0,  // Will be updated by geocoding
            longitude: 0.0  // Will be updated by geocoding
        )
        
        // Insert the mosque first
        modelContext.insert(masjid)
        
        // Save immediately to persist the masjid
        do {
            try modelContext.save()
        } catch {
            print("Error saving mosque: \(error)")
        }
        
        // Geocode the address to get coordinates
        geocodeAddress(masjid.location) { coordinate in
            if let coordinate = coordinate {
                // Update the masjid with the geocoded coordinates
                masjid.latitude = coordinate.latitude
                masjid.longitude = coordinate.longitude
                
                // Save the updated mosque with coordinates
                try? modelContext.save()
                print("✅ Geocoded \(masjid.name): \(coordinate.latitude), \(coordinate.longitude)")
            } else {
                print("⚠️ Could not geocode address for \(masjid.name)")
            }
        }
        
        // Save to CloudKit
        let cloudStore = MasjidCloudStore()
        cloudStore.saveRecordToCloud(mosque: masjid)
    }
    // Add geocoding function to convert addresses to coordinates using MapKit
    private func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard !address.isEmpty else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = address
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                await MainActor.run {
                    if let firstItem = response.mapItems.first {
                        let coordinate = firstItem.placemark.coordinate
                        completion(coordinate)
                        print("✅ Successfully geocoded: \(address)")
                    } else {
                        completion(nil)
                        print("⚠️ No results found for: \(address)")
                    }
                }
            } catch {
                print("❌ Geocoding error: \(error.localizedDescription)")
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
    
}

#Preview {
    NewMasjidView()
}



struct FormTextField: View {
    var placeholder: String
    @State private var animate = false
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeholder)
                .foregroundColor(text.isEmpty ? Color(.placeholderText) : .mSPrimary)
                .offset(y: text.isEmpty ? 0 : -30)
                .scaleEffect(text.isEmpty ? 1: 0.8, anchor: .leading)
            TextField("", text: $text)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(.systemGray5), lineWidth: 1.5)
                .padding(-4)
        )
        .padding(.top, 15)
        .animation(.default, value: animate)
    }
}

#Preview("FormTextField", traits: .fixedLayout(width: 300, height: 200)) {
    FormTextField("Masjid name", text: .constant(""))
    
}

struct FormTextView: View {
    var placeholder: String
    var height: CGFloat = 200.0
    @Binding var text: String
    @State private var animate = false
    
    init(_ placeholder: String, text: Binding<String>, height: CGFloat) {
        self.placeholder = placeholder
        self._text = text
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(placeholder)
                .foregroundColor(text.isEmpty ? Color(.placeholderText) : .mSPrimary)
                .offset(y: text.isEmpty ? 0 : -2)
                .scaleEffect(text.isEmpty ? 1: 0.8, anchor: .leading)
            
            TextEditor(text: $text)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray5), lineWidth: 1.5)
                )
                .padding(.top, 1)
            
        }
        .padding(.top, 10)
        .animation(.default, value: animate)
    }
}


#Preview("FormTextView", traits: .sizeThatFitsLayout) {
    FormTextView("Description", text: .constant(""), height: 100)
}
