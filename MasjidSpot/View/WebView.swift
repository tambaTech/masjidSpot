//
//  WebView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/28/25.
//

import SwiftUI
import WebKit

// MARK: - WebView Configuration

/// Configuration options for WebView
struct WebViewConfiguration {
    var allowsBackForwardNavigationGestures: Bool = true
    var allowsInlineMediaPlayback: Bool = true
    var allowsAirPlayForMediaPlayback: Bool = true
    var allowsPictureInPictureMediaPlayback: Bool = true
    var javaScriptEnabled: Bool = true
    var dataDetectorTypes: WKDataDetectorTypes = [.phoneNumber, .link, .address]
    var customUserAgent: String? = nil
    
    static let `default` = WebViewConfiguration()
}

// MARK: - WebView State

/// Observable state for WebView
@Observable
class WebViewState {
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var title: String?
    var url: URL?
    var estimatedProgress: Double = 0
    var error: Error?
    
    func reset() {
        isLoading = false
        canGoBack = false
        canGoForward = false
        title = nil
        url = nil
        estimatedProgress = 0
        error = nil
    }
}

// MARK: - WebView

/// A SwiftUI wrapper for WKWebView with enhanced features and customization
struct WebView: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// The URL string to load
    var url: String
    
    /// Configuration options
    var configuration: WebViewConfiguration
    
    /// Observable state object
    var state: WebViewState?
    
    /// Callback when navigation completes
    var onNavigationComplete: ((URL?) -> Void)?
    
    /// Callback when an error occurs
    var onError: ((Error) -> Void)?
    
    /// Callback for handling navigation decisions
    var shouldAllowNavigation: ((URL) -> Bool)?
    
    /// HTML content to load instead of URL (takes precedence over URL)
    var htmlContent: String?
    
    /// Base URL for HTML content
    var baseURL: URL?
    
    // MARK: - Initialization
    
    init(
        url: String,
        configuration: WebViewConfiguration = .default,
        state: WebViewState? = nil,
        onNavigationComplete: ((URL?) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil,
        shouldAllowNavigation: ((URL) -> Bool)? = nil
    ) {
        self.url = url
        self.configuration = configuration
        self.state = state
        self.onNavigationComplete = onNavigationComplete
        self.onError = onError
        self.shouldAllowNavigation = shouldAllowNavigation
    }
    
    init(
        htmlContent: String,
        baseURL: URL? = nil,
        configuration: WebViewConfiguration = .default,
        state: WebViewState? = nil
    ) {
        self.url = ""
        self.htmlContent = htmlContent
        self.baseURL = baseURL
        self.configuration = configuration
        self.state = state
    }
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> WKWebView {
        // Create configuration
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = configuration.allowsInlineMediaPlayback
        webConfiguration.allowsAirPlayForMediaPlayback = configuration.allowsAirPlayForMediaPlayback
        webConfiguration.allowsPictureInPictureMediaPlayback = configuration.allowsPictureInPictureMediaPlayback
        webConfiguration.dataDetectorTypes = configuration.dataDetectorTypes
        
        // Create web view
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.allowsBackForwardNavigationGestures = configuration.allowsBackForwardNavigationGestures
        
        // Set custom user agent if provided
        if let customUserAgent = configuration.customUserAgent {
            webView.customUserAgent = customUserAgent
        }
        
        // Set delegates
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Add observers for state changes
        context.coordinator.setupObservers(for: webView)
        
        // Load content
        loadContent(in: webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if the URL has changed and we're not currently loading
        guard !webView.isLoading else { return }
        
        let currentURLString = webView.url?.absoluteString ?? ""
        if currentURLString != url && htmlContent == nil {
            loadContent(in: webView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            state: state,
            onNavigationComplete: onNavigationComplete,
            onError: onError,
            shouldAllowNavigation: shouldAllowNavigation
        )
    }
    
    // MARK: - Private Methods
    
    private func loadContent(in webView: WKWebView) {
        if let htmlContent = htmlContent {
            // Load HTML content
            webView.loadHTMLString(htmlContent, baseURL: baseURL)
        } else if let url = URL(string: url) {
            // Load URL
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            // Invalid URL - handle error
            let error = NSError(
                domain: "WebView",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(url)"]
            )
            onError?(error)
            state?.error = error
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var state: WebViewState?
        var onNavigationComplete: ((URL?) -> Void)?
        var onError: ((Error) -> Void)?
        var shouldAllowNavigation: ((URL) -> Bool)?
        
        private var progressObserver: NSKeyValueObservation?
        private var titleObserver: NSKeyValueObservation?
        private var urlObserver: NSKeyValueObservation?
        private var canGoBackObserver: NSKeyValueObservation?
        private var canGoForwardObserver: NSKeyValueObservation?
        
        init(
            state: WebViewState?,
            onNavigationComplete: ((URL?) -> Void)?,
            onError: ((Error) -> Void)?,
            shouldAllowNavigation: ((URL) -> Bool)?
        ) {
            self.state = state
            self.onNavigationComplete = onNavigationComplete
            self.onError = onError
            self.shouldAllowNavigation = shouldAllowNavigation
        }
        
        deinit {
            progressObserver?.invalidate()
            titleObserver?.invalidate()
            urlObserver?.invalidate()
            canGoBackObserver?.invalidate()
            canGoForwardObserver?.invalidate()
        }
        
        func setupObservers(for webView: WKWebView) {
            progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
                DispatchQueue.main.async {
                    self?.state?.estimatedProgress = change.newValue ?? 0
                }
            }
            
            titleObserver = webView.observe(\.title, options: [.new]) { [weak self] _, change in
                DispatchQueue.main.async {
                    self?.state?.title = change.newValue ?? nil
                }
            }
            
            urlObserver = webView.observe(\.url, options: [.new]) { [weak self] _, change in
                DispatchQueue.main.async {
                    self?.state?.url = change.newValue ?? nil
                }
            }
            
            canGoBackObserver = webView.observe(\.canGoBack, options: [.new]) { [weak self] _, change in
                DispatchQueue.main.async {
                    self?.state?.canGoBack = change.newValue ?? false
                }
            }
            
            canGoForwardObserver = webView.observe(\.canGoForward, options: [.new]) { [weak self] _, change in
                DispatchQueue.main.async {
                    self?.state?.canGoForward = change.newValue ?? false
                }
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { [weak self] in
                self?.state?.isLoading = true
                self?.state?.error = nil
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { [weak self] in
                self?.state?.isLoading = false
                self?.onNavigationComplete?(webView.url)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.state?.isLoading = false
                self?.state?.error = error
                self?.onError?(error)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.state?.isLoading = false
                self?.state?.error = error
                self?.onError?(error)
            }
        }
        
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            
            // Check custom navigation handler
            if let shouldAllowNavigation = shouldAllowNavigation {
                let allowed = shouldAllowNavigation(url)
                decisionHandler(allowed ? .allow : .cancel)
                return
            }
            
            // Handle external URLs (mailto, tel, etc.)
            if !["http", "https", "file", "about"].contains(url.scheme?.lowercased() ?? "") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        // MARK: - WKUIDelegate
        
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Handle target="_blank" links
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            // Handle JavaScript alerts
            let alert = UIAlertController(
                title: frame.request.url?.host,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler()
            })
            
            // Get the root view controller using the modern approach
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            } else {
                completionHandler()
            }
        }
    }
}

// MARK: - WebView with Navigation Controls

/// A WebView with built-in navigation controls and loading indicator
struct WebViewWithControls: View {
    
    let url: String
    let configuration: WebViewConfiguration
    
    @State private var state = WebViewState()
    @State private var webView: WKWebView?
    
    init(url: String, configuration: WebViewConfiguration = .default) {
        self.url = url
        self.configuration = configuration
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            if state.isLoading {
                ProgressView(value: state.estimatedProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
            
            // Web view
            WebView(url: url, configuration: configuration, state: state)
                .overlay(alignment: .center) {
                    if state.isLoading && state.estimatedProgress < 0.1 {
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            
            // Navigation toolbar
            HStack(spacing: DesignSystem.Spacing.large) {
                Button {
                    webView?.goBack()
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(state.canGoBack ? .primary : .secondary)
                        .frame(width: 44, height: 44)
                }
                .disabled(!state.canGoBack)
                
                Button {
                    webView?.goForward()
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(state.canGoForward ? .primary : .secondary)
                        .frame(width: 44, height: 44)
                }
                .disabled(!state.canGoForward)
                
                Spacer()
                
                Button {
                    webView?.reload()
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    Image(systemName: state.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
                
                if let url = state.url {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .onAppear {
            // Store web view reference for navigation
            // This is a workaround since we can't directly access the UIView
        }
    }
}

// MARK: - Convenience Extensions

extension WebView {
    /// Creates a WebView with JavaScript disabled for security
    static func secure(url: String) -> WebView {
        var config = WebViewConfiguration.default
        config.javaScriptEnabled = false
        return WebView(url: url, configuration: config)
    }
    
    /// Creates a WebView optimized for media playback
    static func forMedia(url: String) -> WebView {
        var config = WebViewConfiguration.default
        config.allowsInlineMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        return WebView(url: url, configuration: config)
    }
}

// MARK: - Previews

#Preview("Basic WebView") {
    WebView(url: "https://my-masjid.com/")
}
#Preview("WebView with Controls") {
    NavigationStack {
        WebViewWithControls(url: "https://my-masjid.com/")
            .navigationTitle("Web Browser")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("WebView with State") {
    struct StatePreview: View {
        @State private var state = WebViewState()
        
        var body: some View {
            VStack {
                if let title = state.title {
                    Text(title)
                        .font(.headline)
                        .padding()
                }
                
                if state.isLoading {
                    ProgressView(value: state.estimatedProgress)
                        .padding()
                }
                
                WebView(url: "https://my-masjid.com/", state: state)
            }
        }
    }
    
    return StatePreview()
}

#Preview("HTML Content") {
    WebView(
        htmlContent: """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { 
                    font-family: -apple-system; 
                    padding: 20px;
                    font-size: 16px;
                }
                h1 { color: #007AFF; }
            </style>
        </head>
        <body>
            <h1>MasjidSpot</h1>
            <p>Find mosques near you! 🕌</p>
        </body>
        </html>
        """
    )
}

