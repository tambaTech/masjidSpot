//
//  SafariView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/28/25.
//

import Foundation


import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    
    var url: String
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        
        guard let url = URL(string: url) else {
            fatalError("Invalid urlString: \(url)")
        }
        return SFSafariViewController(url: url)
        
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController,
                                context: UIViewControllerRepresentableContext<SafariView>) {
        
    }
    
}



#Preview {
    SafariView(url: "https://my-masjid.com/")
}
