//
//  Masjid.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//


import SwiftUI

struct AboutView: View {
   
   enum WebLink: String, Identifiable {
      case rateUs = "https://www.apple.com/ios/app-store"
      case feedback = "https://www.tambatech.com"
      case x = "https://www.x.com"
      case facebook = "https://www.facebook.com/"
      case instagram = "https://www.instagram.com/akamuhamadu"
      
      var id: UUID {
         UUID()
      }
   }
   
   @State private var link: WebLink?
   
   
   var body: some View {
      NavigationStack {
         List {
            
            Image("about")
               .resizable()
               .scaledToFit()
            
            Section {
               
               Link(destination: URL(string: WebLink.rateUs.rawValue)!) {
                  Label("Rate us in AppStore", image: "store")
                     .foregroundColor(.primary)
               }
               
               Label("Tell us your feedback", image: "chat")
            }
            
            Section {
               Label("X", image: "x")
                  .onTapGesture {
                     link = .x
                  }
               Label("Facebook", image: "facebook")
                  .onTapGesture {
                     link = .facebook
                  }
               Label("Instagram", image: "instagram")
                  .onTapGesture {
                     link = .instagram
                  }
            }
            
         }
         .listStyle(.grouped)
         .navigationTitle("About")
         .navigationBarTitleDisplayMode(.automatic)
         .sheet(item: $link) { item in
            WebView(url: item.rawValue)
         }
         
      }
      
   }
}

#Preview {
    AboutView()
}

