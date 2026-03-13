//
//  LocationGeocoder.swift
//  MosquePin
//
//  Created by Lamin Tamba
//

import Foundation
import CoreLocation

class LocationGeocoder {
    private let geocoder = CLGeocoder()
    
    /// Geocode a location string to coordinates
    func geocodeLocation(_ locationString: String) async throws -> CLLocationCoordinate2D {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(locationString) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    continuation.resume(throwing: GeocodingError.locationNotFound)
                    return
                }
                
                continuation.resume(returning: location.coordinate)
            }
        }
    }
    
    /// Geocode all mosques that don't have coordinates
    func geocodeAllMosques(_ mosques: [Masjid]) async {
        for mosque in mosques where mosque.latitude == 0.0 && mosque.longitude == 0.0 {
            do {
                let coordinate = try await geocodeLocation(mosque.location)
                // Capture only the necessary values to avoid Sendable issues
                let latitude = coordinate.latitude
                let longitude = coordinate.longitude
                
                // Use Task.detached to avoid Sendable issues
                await Task.detached { @MainActor in
                    mosque.latitude = latitude
                    mosque.longitude = longitude
                }.value
                
                // Add delay to respect rate limits
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            } catch {
                print("Failed to geocode \(mosque.name): \(error.localizedDescription)")
            }
        }
    }
}

