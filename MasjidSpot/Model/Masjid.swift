//
//  Masjid.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/15/25.
//

import SwiftData
import SwiftUI
import Foundation


@Model class Masjid {
    var name: String = ""
    var location: String = ""
    var phone: String = ""
    var summary: String = ""
    var website: String = ""
    var myMasjidUrl: String = ""
    @Attribute(.externalStorage) var imageData = Data()
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var isVisited: Bool = false
    
    @Transient var image: UIImage {
        get {
            UIImage(data: imageData) ?? UIImage(systemName: "building.2.crop.circle") ?? UIImage()
        }
        
        set {
            self.imageData = newValue.pngData() ?? Data()
        }
    }
    
    // Computed property for address display
    @Transient var displayAddress: String {
        location.isEmpty ? "Location not specified" : location
    }
    
    // Computed property for coordinate validation
    @Transient var hasValidCoordinates: Bool {
        latitude != 0.0 && longitude != 0.0
    }
    
    init(name: String, location: String, phone: String, description: String, image: UIImage = UIImage(), website: String, myMasjidUrl: String, isVisited: Bool, latitude: Double = 0.0, longitude: Double = 0.0) {
        self.name = name
        self.location = location
        self.phone = phone
        self.summary = description
        self.image = image
        self.website = website
        self.myMasjidUrl = myMasjidUrl
        self.isVisited = isVisited
        self.latitude = latitude
        self.longitude = longitude
    }
}
