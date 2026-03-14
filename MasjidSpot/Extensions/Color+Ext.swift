//
//  Color+Ext.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//

import SwiftUI


extension Color {
    // Primary brand color - main property
    static let pbPrimary = Color("brandPrimary")
    
    // Primary brand color with fallback
    static let brandColor = Color("brandPrimary")
    
    // Secondary brand color (for accents like Featured icon)
    static let brandSecondary = Color("brandSecondary")
    
    // Legacy aliases (consider deprecating these in future versions)
    static let primaryBrand = Color("brandPrimary")
    static let mSPrimary = Color("brandPrimary")
    static let bPrimary = Color("brandPrimary")
}
