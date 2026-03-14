//
//  AppearanceMode.swift
//  MasjidSpot
//
//  Created by Assistant on 3/14/26.
//

import SwiftUI

/// Defines the appearance mode options for the app
enum AppearanceMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil  // nil = follow system settings
        }
    }
    
    var description: String {
        switch self {
        case .light: return "Light mode always"
        case .dark: return "Dark mode always"
        case .system: return "Follow system settings"
        }
    }
}
