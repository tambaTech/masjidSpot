//
//  ActtionButton.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/28/25.
//

import SwiftUI

struct STActionButton: View {
   var color: Color
     var imageName: String
     
     var body: some View {
       ZStack {
         Circle()
           .foregroundStyle(color)
           .frame(width: 60, height: 60)
         
         Image(systemName: imageName)
           .resizable()
           .scaledToFit()
           .foregroundStyle(.white)
           .frame(width: 22, height: 22)
       }
     }
}

#Preview {
    STActionButton(color: .red, imageName: "globe")
}

