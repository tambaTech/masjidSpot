//
//  CloudKitLocationGeocoder.swift
//  MosquePin
//
//  Created by Lamin Tamba
//

import Foundation
import CoreLocation
import CloudKit
import Combine

/// Errors that can occur during geocoding
enum GeocodingError: LocalizedError {
    case locationNotFound
    case invalidAddress
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .locationNotFound:
            return "Could not find coordinates for this location"
        case .invalidAddress:
            return "The address provided is invalid"
        case .rateLimitExceeded:
            return "Too many geocoding requests. Please try again later."
        }
    }
}

@MainActor
class CloudKitLocationGeocoder: ObservableObject {
    private let geocoder = CLGeocoder()
    @Published var geocodedLocations: [String: CLLocationCoordinate2D] = [:]
    
    /// Geocode a location string to coordinates
    func geocodeLocation(_ locationString: String) async throws -> CLLocationCoordinate2D {
        // Check cache first
        if let cachedCoordinate = geocodedLocations[locationString] {
            return cachedCoordinate
        }
        
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
                
                let coordinate = location.coordinate
                
                // Cache the result - no need for DispatchQueue since we're already @MainActor
                Task { @MainActor in
                    self.geocodedLocations[locationString] = coordinate
                }
                
                continuation.resume(returning: coordinate)
            }
        }
    }
    
    /// Batch geocode all mosque locations from CloudKit records
    func geocodeAllMosqueLocations(_ mosques: [CKRecord]) async {
        for mosque in mosques {
            guard let locationString = mosque["location"] as? String,
                  !locationString.isEmpty,
                  geocodedLocations[locationString] == nil else {
                continue
            }
            
            do {
                let coordinate = try await geocodeLocation(locationString)
                print("Geocoded \(mosque["name"] as? String ?? "Unknown"): \(coordinate)")
                
                // Add delay to respect rate limits
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
            } catch {
                print("Failed to geocode \(mosque["name"] as? String ?? "Unknown"): \(error.localizedDescription)")
            }
        }
    }
    
    /// Get coordinate from cache or return nil
    func getCachedCoordinate(for locationString: String) -> CLLocationCoordinate2D? {
        return geocodedLocations[locationString]
    }
}
