//
//  AnnotationView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/2/25.
//

import SwiftUI

struct AnnotationView: View {
    var masjid: Masjid
    
    
    var body: some View {
        VStack {
            ZStack {
                MapBalloonView()
                    .frame(width: 100, height: 70)
                    .foregroundColor(.brandPrimary)
                
                
                Image(uiImage: masjid.image)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                
            }
            Text(masjid.name)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
}

#Preview {
    AnnotationView(masjid: Masjid(
        name: "Masjid al-Nabawi",
        location: "Al Haram, Madinah 42311, Saudi Arabia",
        phone: "+966 14 823 2400",
        description: "The Prophet's Mosque is the second mosque built by the Islamic prophet Muhammad in Medina, after the Quba Mosque, as well as the second largest mosque and holiest site in Islam, after the Masjid al-Haram in Mecca, in the Saudi region of the Hejaz.",
        image: UIImage(named: "mosquealmasjidalharam")!,
        website: "https://haramain.com",
        myMasjidUrl:  "https://time.my-masjid.com",
        isVisited: false,
        latitude: 0.0,
        longitude: 0.0
    ))
}



