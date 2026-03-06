//
//  MapView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/2/25.
//

import SwiftUI
import MapKit



struct MapView: View {
    var location: String = ""
    var interactionMode: MapInteractionModes = .all
    
    var masjid: Masjid
    
    
    @State private var position: MapCameraPosition = .automatic
    @State private var markerLocation = CLLocationCoordinate2D()
    
    
    var body: some View {
        Map(position: $position, interactionModes: interactionMode) {
            Annotation(masjid.name, coordinate: markerLocation){
                AnnotationView(masjid: masjid)
            }
            .annotationTitles(.hidden)
            
        }
        .task {
            convertAddress(location: location)
        }
        .ignoresSafeArea()
    }
    
    private func convertAddress(location: String) {
        // First check if mosque already has coordinates
        if masjid.latitude != 0.0 && masjid.longitude != 0.0 {
            let coordinate = CLLocationCoordinate2D(latitude: masjid.latitude, longitude: masjid.longitude)
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015))
            self.position = .region(region)
            self.markerLocation = coordinate
            return
        }
        
        // Get location from address string using MapKit's MKLocalSearch API
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = location
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                guard let firstItem = response.mapItems.first else {
                    print("No location found for address: \(location)")
                    return
                }
                
                let coordinate = firstItem.placemark.coordinate
                let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.0015, longitudeDelta: 0.0015))
                
                self.position = .region(region)
                self.markerLocation = coordinate
                
            } catch {
                print("Geocoding error: \(error.localizedDescription)")
            }
        }
    }
    
    
}


#Preview {
    MapView(masjid: Masjid(name: "Masjid al-Nabawi", location: "Al Haram, Madinah 42311, Saudi Arabia", phone: "+966 14 823 2400", description: "The Prophet's Mosque is the second mosque built by the Islamic prophet Muhammad in Medina, after the Quba Mosque, as well as the second largest mosque and holiest site in Islam, after the Masjid al-Haram in Mecca, in the Saudi region of the Hejaz.", image: UIImage(named: "mosquealmasjidalharam")!, website: "https://haramain.com", myMasjidUrl:  "https://time.my-masjid.com", isVisited: false))
}

