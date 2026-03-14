//
//  MapOverlayControls.swift
//  MosquePin
//
//  Created by Assistant
//

import SwiftUI
import MapKit

// MARK: - Top Bar Controls
struct MapTopBarControls: View {
    @Binding var searchText: String
    @Binding var mapType: MKMapType
    @Binding var is3DEnabled: Bool
    let onFitAllMosques: () -> Void
    let onLookAround: () -> Void
    let onRefreshData: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search masjids...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Menu button
            Menu {
                Section("Map Style") {
                    Button(action: { mapType = .standard }) {
                        Label("Standard", systemImage: mapType == .standard ? "checkmark" : "map")
                    }
                    
                    Button(action: { mapType = .satellite }) {
                        Label("Satellite", systemImage: mapType == .satellite ? "checkmark" : "globe.americas")
                    }
                    
                    Button(action: { mapType = .hybrid }) {
                        Label("Hybrid", systemImage: mapType == .hybrid ? "checkmark" : "globe.americas.fill")
                    }
                }
                
                Section("View Options") {
                    Button(action: { is3DEnabled.toggle() }) {
                        Label(is3DEnabled ? "2D View" : "3D View",
                              systemImage: is3DEnabled ? "view.2d" : "view.3d")
                    }
                    
                    Button(action: onFitAllMosques) {
                        Label("Fit All Mosques", systemImage: "viewfinder")
                    }
                    
                    Button(action: onLookAround) {
                        Label("Look Around", systemImage: "binoculars")
                    }
                }
                
                Section("Data") {
                    Button(action: onRefreshData) {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }
}

// MARK: - Bottom Bar Controls
struct MapBottomBarControls: View {
    let userHasInteractedWithMap: Bool
    let isLocationAvailable: Bool
    let hasMosques: Bool
    let onLookAround: () -> Void
    let onDirections: () -> Void
    let onCenterLocation: () -> Void
    
    var body: some View {
        HStack {
            // Look Around button
            Button(action: onLookAround) {
                Image(systemName: "binoculars.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color(white: 0.2).opacity(0.9), in: Circle())
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                // Directions button
                Button(action: onDirections) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Color(white: 0.2).opacity(0.9), in: Circle())
                }
                .disabled(!hasMosques)
                
                // Location tracking button
                Button(action: onCenterLocation) {
                    Image(systemName: userHasInteractedWithMap ? "location" : "location.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(userHasInteractedWithMap ? .white : .blue)
                        .frame(width: 50, height: 50)
                        .background(Color(white: 0.2).opacity(0.9), in: Circle())
                }
                .disabled(!isLocationAvailable)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }
}

// MARK: - Loading States
struct MapLoadingOverlay: View {
    let message: String
    
    var body: some View {
        VStack {
            ProgressView(message)
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Empty State
struct MapEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("No mosques found")
                .font(.title2)
                .foregroundStyle(.secondary)
            if !searchText.isEmpty {
                Text("Try adjusting your search")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(30)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
