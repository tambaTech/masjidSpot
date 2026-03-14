//
//  MasjidFormViewModel.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/24/25.
//



import SwiftUI

@MainActor
@Observable class MasjidFormViewModel {
    // Input
    var name: String = ""
    var location: String  = ""
    var phone: String  = ""
    var website: String  = ""
    var myMasjidUrl: String  = ""
    var summary: String  = ""
    var image: UIImage = UIImage()
    
    init(majsid: Masjid? = nil) {
        
        if let majsid = majsid {
            self.name = majsid.name
            self.location = majsid.location
            self.phone = majsid.phone
            self.website = majsid.website
            self.myMasjidUrl = majsid.myMasjidUrl
            self.summary = majsid.summary
            self.image = majsid.image
        }
    }
}
