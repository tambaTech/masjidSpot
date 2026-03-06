//
//  MainView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/5/25.
//

import SwiftUI

struct MainView: View {
    
    @State private var selectedTabIndex = 0
    
   
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            MasjidListView()
                .tabItem {
                    Image(systemName: "building.fill")
                    Text("Masjids")
                }
                .tag(0)
            
            DiscoverView()
                 .tabItem {
                     Label("Discover Masjids", systemImage: "safari")
                 }
                 .tag(1)
               
            
            MasjidMapView()
                .tabItem {
                    Label("Masjid Map", systemImage: "map.fill")
                }
                .tag(2)
              
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
                .tag(3)
              
        }
        .tint(Color("NavigationBarTitle"))
    }
}

#Preview {
    MainView()
}
