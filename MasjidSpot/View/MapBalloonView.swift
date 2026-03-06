//
//  MapBalloonView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/2/25.
//


import SwiftUI

struct MapBalloonView: Shape {
   func path(in rect: CGRect) -> Path {
      var path = Path()
      path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
      path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.minY))
      
      
      return path
   }
}



#Preview {
    MapBalloonView()
      .frame(width: 300, height: 300)
      .foregroundColor(.mSPrimary)
}
