//
//  SafariView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/28/25.
//

import Foundation
import SafariServices
import SwiftUI

/// A SwiftUI wrapper for SFSafariViewController with enhanced customization options
struct SafariView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// The URL string to display
    var url: String
    
    /// The tint color for Safari controls
    var tintColor: UIColor?
    
    /// The preferred bar tint color
    var barTintColor: UIColor?
    
    /// Whether to enable reader mode if available
    var entersReaderIfAvailable: Bool
    
    /// Dismiss action callback
    var onDismiss: (() -> Void)?
    
    /// Error callback for invalid URLs
    var onError: ((String) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    init(
        url: String,
        tintColor: UIColor? = nil,
        barTintColor: UIColor? = nil,
        entersReaderIfAvailable: Bool = false,
        onDismiss: (() -> Void)? = nil,
        onError: ((String) -> Void)? = nil
    ) {
        self.url = url
        self.tintColor = tintColor
        self.barTintColor = barTintColor
        self.entersReaderIfAvailable = entersReaderIfAvailable
        self.onDismiss = onDismiss
        self.onError = onError
    }
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        // Validate URL
        guard let validURL = URL(string: url) else {
            // Handle error gracefully instead of crashing
            onError?("Invalid URL: \(url)")
            
            // Return a fallback SafariViewController
            let fallbackURL = URL(string: "about:blank")!
            let safariVC = SFSafariViewController(url: fallbackURL)
            
            // Dismiss immediately if URL is invalid
            DispatchQueue.main.async {
                dismiss()
            }
            
            return safariVC
        }
        
        // Create configuration
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = entersReaderIfAvailable
        configuration.barCollapsingEnabled = true
        
        // Create Safari view controller
        let safariVC = SFSafariViewController(url: validURL, configuration: configuration)
        
        // Apply customizations
        if let tintColor = tintColor {
            safariVC.preferredControlTintColor = tintColor
        }
        
        if let barTintColor = barTintColor {
            safariVC.preferredBarTintColor = barTintColor
        }
        
        // Set delegate
        safariVC.delegate = context.coordinator
        
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Update colors if needed
        if let tintColor = tintColor {
            uiViewController.preferredControlTintColor = tintColor
        }
        
        if let barTintColor = barTintColor {
            uiViewController.preferredBarTintColor = barTintColor
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onDismiss: onDismiss)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let dismiss: DismissAction
        let onDismiss: (() -> Void)?
        
        init(dismiss: DismissAction, onDismiss: (() -> Void)?) {
            self.dismiss = dismiss
            self.onDismiss = onDismiss
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            dismiss()
            onDismiss?()
        }
        
        func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
            // Could track redirects if needed
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            // Could handle load failures if needed
            if !didLoadSuccessfully {
                print("Failed to load URL in Safari")
            }
        }
    }
}

// MARK: - Convenience Extensions

extension SafariView {
    /// Creates a SafariView with the app's primary color as tint
    static func withPrimaryTint(url: String) -> SafariView {
        SafariView(
            url: url,
            tintColor: UIColor(named: "mSPrimary")
        )
    }
    
    /// Creates a SafariView optimized for reading content
    static func forReading(url: String) -> SafariView {
        SafariView(
            url: url,
            entersReaderIfAvailable: true
        )
    }
}

// MARK: - View Extension

extension View {
    /// Present a Safari view with the given URL
    func safari(url: Binding<String?>) -> some View {
        sheet(item: Binding(
            get: { url.wrappedValue.map { URLWrapper(url: $0) } },
            set: { url.wrappedValue = $0?.url }
        )) { wrapper in
            SafariView(url: wrapper.url)
                .ignoresSafeArea()
        }
    }
    
    /// Present a Safari view with a URL wrapper
    func safari<Item: Identifiable>(item: Binding<Item?>, url: @escaping (Item) -> String) -> some View {
        sheet(item: item) { value in
            SafariView(url: url(value))
                .ignoresSafeArea()
        }
    }
}

// MARK: - Helper Types

private struct URLWrapper: Identifiable {
    let id = UUID()
    let url: String
}

// MARK: - Preview

#Preview("Basic Safari View") {
    SafariView(url: "https://my-masjid.com/")
}
#Preview("Safari with Custom Colors") {
    SafariView(
        url: "https://my-masjid.com/",
        tintColor: .systemGreen,
        barTintColor: .systemBackground
    )
}

#Preview("Safari with Reader Mode") {
    SafariView.forReading(url: "https://www.apple.com/newsroom/")
}

#Preview("Safari in Sheet") {
    struct PreviewWrapper: View {
        @State private var showSafari = false
        
        var body: some View {
            Button("Open Safari") {
                showSafari = true
            }
            .sheet(isPresented: $showSafari) {
                SafariView(url: "https://my-masjid.com/")
                    .ignoresSafeArea()
            }
        }
    }
    
    return PreviewWrapper()
}

