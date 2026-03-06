//
//  Masjid.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//

import SwiftUI

struct TutorialView: View {
   @Environment(\.dismiss) var dismiss
   @AppStorage("hasViewedWalkthrough") var hasViewedWalkthrough: Bool = false
   
   @State private var currentPage = 0
   
   let pageHeadings = ["CREATE YOUR OWN MASJDIS GUIDE", "SHOW YOU THE LOCATION", "DISCOVER GREATE MASJDIS"]
   
   let pageSubheadings = ["Spot your visited masjids and create your own masjid guide to share with others", "Search and location spot your masjids on maps", "Find masjids shared by your friends and others"]
   
   let pageImages = ["onboarding-1", "onboarding-2", "onboarding-3"]
   
   init() {
      UIPageControl.appearance().currentPageIndicatorTintColor = .systemTeal
      UIPageControl.appearance().pageIndicatorTintColor = .lightGray
   }
   
   

   var body: some View {
      TabView(selection: $currentPage) {
         ForEach(pageHeadings.indices, id: \.self) { index in
            TutorialPage(image: pageImages[index], heading: pageHeadings[index], subHeading: pageSubheadings[index])
               .tag(index)
         }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
      .indexViewStyle(.page(backgroundDisplayMode: .always))
      .animation(.default, value: currentPage)
      
      VStack(spacing: 20) {
         Button {
            if currentPage < pageHeadings.count - 1 {
               currentPage += 1
            } else {
               hasViewedWalkthrough = true
               dismiss()
            }
         } label: {
            Text(currentPage == pageHeadings.count - 1 ? "GET STRATED" : "NEXT")
               .font(.headline)
               .foregroundColor(.white)
               .padding()
               .padding(.horizontal, 50)
               .background(Color(.systemTeal))
               .cornerRadius(25)
         }
         
         if currentPage < pageHeadings.count - 1 {
            Button {
               hasViewedWalkthrough = true
               dismiss()
            } label: {
               Text("Skip")
                  .font(.headline)
                  .foregroundColor(Color(.darkGray))
            }
            
         }
         
      }
      .padding(.bottom)
      
   }
}


struct TutorialPage: View {
   
   let image: String
   let heading: String
   let subHeading: String
   
   var body: some View {
      VStack(spacing: 70) {
         Image(image)
            .resizable()
            .scaledToFit()
         
         VStack(spacing: 10) {
            Text(heading)
               .font(.headline)
            
            Text(subHeading)
               .font(.body)
               .foregroundColor(.gray)
               .multilineTextAlignment(.center)
         }
         .padding(.horizontal, 40)
         
         Spacer()
      }
      .padding(.top)
   }
}

#Preview {
    TutorialView()
}

#Preview("TutorialPage", traits: .sizeThatFitsLayout) {
    TutorialPage(image: "onboarding-1", heading: "CREATE YOUR OWN MOSQUE GUIDE", subHeading: "Pin your favorite mosques and create your own mosque guide")
}
