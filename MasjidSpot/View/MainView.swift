//
//  MainView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/5/25.
//

import SwiftUI

struct MainView: View {
    
    enum AppTab: Int, CaseIterable {
        case masjids, browse, map, about
    }
    
    @State private var selectedTab: AppTab = .masjids
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Masjids", systemImage: "building.fill", value: .masjids) {
                MasjidListView()
            }
            
            Tab("Browse", systemImage: "safari", value: .browse) {
                BrowseView()
            }
            
            Tab("Map", systemImage: "map.fill", value: .map) {
                MasjidMapView()
            }
            
            Tab("About", systemImage: "info.circle.fill", value: .about) {
                AboutView()
            }
        }
        .tint(Color("NavigationBarTitle"))
    }
}

#Preview {
    MainView()
}
