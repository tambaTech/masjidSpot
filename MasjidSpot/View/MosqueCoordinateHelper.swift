//
//  MosqueCoordinateHelper.swift
//  MosquePin
//
//  Created by Assistant
//

import Foundation
import CoreLocation

/// Utility struct for handling mosque coordinate lookups
struct MosqueCoordinateHelper {
    
    /// Sample locations with hardcoded coordinates
    /// In production, these should be stored in CloudKit or geocoded dynamically
    private static let sampleLocations: [String: CLLocationCoordinate2D] = [
        "Al Haram, Makkah 24231, Saudi Arabia": CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262),
        "Medina": CLLocationCoordinate2D(latitude: 24.4539, longitude: 39.5970),
        "Jerusalem": CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)
    ]
    
    /// Get coordinate from a location string using hardcoded samples
    /// - Parameter locationString: The location string to look up
    /// - Returns: Coordinate if found, nil otherwise
    static func getCoordinate(for locationString: String) -> CLLocationCoordinate2D? {
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
    
    /// Calculate distance to a mosque from a user location
    /// - Parameters:
    ///   - locationString: The mosque's location string
    ///   - userLocation: The user's current location
    ///   - geocoder: Optional geocoder to check cached coordinates first
    /// - Returns: Distance in meters, or greatestFiniteMagnitude if coordinate unavailable
    static func distanceToMosque(
        locationString: String,
        from userLocation: CLLocation,
        geocoder: CloudKitLocationGeocoder? = nil
    ) -> CLLocationDistance {
        // Try cached coordinate first
        let coordinate = geocoder?.getCachedCoordinate(for: locationString) ?? getCoordinate(for: locationString)
        
        guard let coordinate = coordinate else {
            return CLLocationDistance.greatestFiniteMagnitude
        }
        
        let mosqueLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userLocation.distance(from: mosqueLocation)
    }
    
    /// Format distance for display
    /// - Parameter distance: Distance in meters
    /// - Returns: Formatted string (e.g., "500 m" or "1.2 km")
    static func formatDistance(_ distance: CLLocationDistance) -> String? {
        guard distance != CLLocationDistance.greatestFiniteMagnitude else {
            return nil
        }
        
        let distanceInKm = distance / 1000.0
        if distanceInKm < 1.0 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distanceInKm)
        }
    }
}
