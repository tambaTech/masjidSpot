//
//  WebView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/28/25.
//


import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    var url: String
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}




#Preview {
    WebView(url: "https://my-masjid.com/")
}
