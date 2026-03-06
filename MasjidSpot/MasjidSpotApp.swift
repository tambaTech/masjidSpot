//
//  MasjidSpotApp.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/21/25.
//

import SwiftUI
import SwiftData

@main
struct MasjidSpotApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [Masjid.self])
    }
     init() {
           let navBarAppearance = UINavigationBarAppearance()
           navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemGreen, .font: UIFont(name: "ArialRoundedMTBold", size: 35)!]
           navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemGreen, .font: UIFont(name: "ArialRoundedMTBold", size: 20)!]
           navBarAppearance.backgroundColor = .clear
           navBarAppearance.backgroundEffect = .none
           navBarAppearance.shadowColor = .clear
           
           UINavigationBar.appearance().standardAppearance = navBarAppearance
           UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
           UINavigationBar.appearance().compactAppearance = navBarAppearance
       }
}
