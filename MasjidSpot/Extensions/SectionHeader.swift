//
//  SectionHeader.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 3/12/26.
//

import SwiftUI

/// Reusable section header component with icon and title
struct SectionHeader: View {
    let icon: String
    let title: String
    let iconColor: Color
    var count: Int? = nil
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.title3.weight(.semibold))
            }
            
            Spacer()
            
            if let count = count {
                Text("\(count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(minWidth: 32, minHeight: 24)
                    .background(
                        Capsule()
                            .fill(Color.brandPrimary.gradient)
                    )
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview("With Count") {
    SectionHeader(
        icon: "building.2.fill",
        title: "All Masjids",
        iconColor: .brandPrimary,
        count: 42
    )
}

#Preview("Without Count") {
    SectionHeader(
        icon: "sparkles",
        title: "Featured",
        iconColor: .orange
    )
}
