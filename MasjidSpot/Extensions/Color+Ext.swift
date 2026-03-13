//
//  Color+Ext.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif


extension Color {
    // Primary brand color - main property
    static let pbPrimary = Color("brandPrimary")
    
    // Primary brand color with fallback
    static var brandColor: Color {
        #if canImport(UIKit)
        if let uiColor = UIColor(named: "brandPrimary") {
            return Color(uiColor)
        } else {
            return Color.blue
        }
        #elseif canImport(AppKit)
        if let nsColor = NSColor(named: "brandPrimary") {
            return Color(nsColor)
        } else {
            return Color.blue
        }
        #else
        return Color.blue
        #endif
    }
    
    // Secondary brand color (for accents like Featured icon)
    static var brandSecondary: Color {
        #if canImport(UIKit)
        if let uiColor = UIColor(named: "brandSecondary") {
            return Color(uiColor)
        } else {
            return Color.orange
        }
        #elseif canImport(AppKit)
        if let nsColor = NSColor(named: "brandSecondary") {
            return Color(nsColor)
        } else {
            return Color.orange
        }
        #else
        return Color.orange
        #endif
    }
    
    // Legacy aliases (consider deprecating these in future versions)
    static let primaryBrand = Color("brandPrimary")
    static let mSPrimary = Color("brandPrimary")
    static let bPrimary = Color("brandPrimary")
}
