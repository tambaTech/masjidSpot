//
//  MasjidDetailView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/27/25.
//

import SwiftUI
import SwiftData

struct MasjidDetailView: View {
    @Environment(\.dismiss) var dismiss
    var masjid: Masjid
    
    @State private var isVisited: Bool = false
    @State private var showingShareSheet = false
    @State private var imageOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Hero Image Section
                GeometryReader { geometry in
                    let offset = geometry.frame(in: .global).minY
                    
                    Image(uiImage: masjid.image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height + (offset > 0 ? offset : 0)
                        )
                        .offset(y: offset > 0 ? -offset : 0)
                        .clipped()
                        .overlay {
                            // Gradient overlay for better text readability
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .clear,
                                    .black.opacity(0.3),
                                    .black.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .overlay(alignment: .topTrailing) {
                            // Visited badge
                            Button(action: {
                                toggleVisited()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isVisited ? "checkmark.seal.fill" : "checkmark.seal")
                                        .font(.system(size: 20, weight: .semibold))
                                    
                                    if isVisited {
                                        Text("Visited")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                .foregroundStyle(isVisited ? .green : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .padding(.top, 60)
                            .padding(.trailing, 20)
                        }
                        .overlay(alignment: .bottomLeading) {
                            // Title and location
                            VStack(alignment: .leading, spacing: 12) {
                                Text(masjid.name)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 10)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 16))
                                    
                                    Text(masjid.location)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .padding(24)
                        }
                }
                .frame(height: 400)
                
                // MARK: - Content Section
                VStack(alignment: .leading, spacing: 24) {
                    // Quick Actions
                    ModernActionButtons(masjid: masjid)
                        .padding(.top, 20)
                    
                    // About Section
                    if !masjid.summary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Text(masjid.summary)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .lineSpacing(6)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Contact Information Cards
                    VStack(spacing: 12) {
                        // Address Card
                        ContactInfoCard(
                            icon: "mappin.circle.fill",
                            title: "Address",
                            value: masjid.location,
                            color: .blue
                        ) {
                            openMaps()
                        }
                        
                        // Phone Card
                        if !masjid.phone.isEmpty {
                            ContactInfoCard(
                                icon: "phone.circle.fill",
                                title: "Phone",
                                value: masjid.phone,
                                color: .green
                            ) {
                                openCall(phone: masjid.phone)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Map Preview
                    NavigationLink(destination: MasjidDetailMapView(location: masjid.location, masjid: masjid)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .edgesIgnoringSafeArea(.all)
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Location")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 20)
                            
                            ZStack(alignment: .bottomTrailing) {
                                MasjidDetailMapView(location: masjid.location, interactionMode: [], masjid: masjid)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .allowsHitTesting(false)
                                
                                // Tap to expand indicator
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Tap to expand")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.7))
                                )
                                .padding(12)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .buttonStyle(MapPreviewButtonStyle())
                    
                    // Share Section
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Share This Masjid")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .tint(.mSPrimary)
        .onAppear {
            isVisited = masjid.isVisited
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createShareText()])
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleVisited() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isVisited.toggle()
        }
        
        // Update the masjid model
        masjid.isVisited = isVisited
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(isVisited ? .success : .warning)
    }
    
    private func openMaps() {
        guard let url = URL(string: "maps://q?address=\(masjid.location.replacingOccurrences(of: " ", with: ","))") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    private func openCall(phone: String) {
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleanPhone)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    private func createShareText() -> String {
        return """
        Check out \(masjid.name)!
        
        📍 \(masjid.location)
        \(masjid.phone.isEmpty ? "" : "📞 \(masjid.phone)")
        
        \(masjid.summary)
        """
    }
}


// MARK: - Modern Action Buttons
fileprivate struct ModernActionButtons: View {
    var masjid: Masjid
    @State private var showMyMasjid = false
    @State private var showWebsite = false
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                // Prayer Times
                ActionButton(
                    icon: "clock.fill",
                    title: "Prayer Times",
                    color: .pink,
                    action: {
                        if !masjid.myMasjidUrl.isEmpty {
                            showMyMasjid = true
                        }
                    }
                )
                .disabled(masjid.myMasjidUrl.isEmpty)
                .opacity(masjid.myMasjidUrl.isEmpty ? 0.5 : 1.0)
                
                // Directions
                ActionButton(
                    icon: "car.fill",
                    title: "Directions",
                    color: .blue,
                    action: {
                        openMaps()
                    }
                )
                
                // Call
                if !masjid.phone.isEmpty {
                    ActionButton(
                        icon: "phone.fill",
                        title: "Call",
                        color: .green,
                        action: {
                            openCall(phone: masjid.phone)
                        }
                    )
                }
                
                // Website
                ActionButton(
                    icon: "safari.fill",
                    title: "Website",
                    color: .orange,
                    action: {
                        if !masjid.website.isEmpty {
                            showWebsite = true
                        }
                    }
                )
                .disabled(masjid.website.isEmpty)
                .opacity(masjid.website.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showMyMasjid) {
            if !masjid.myMasjidUrl.isEmpty {
                WebView(url: masjid.myMasjidUrl)
            }
        }
        .sheet(isPresented: $showWebsite) {
            if !masjid.website.isEmpty {
                SafariView(url: masjid.website)
            }
        }
    }
    
    private func openMaps() {
        guard let url = URL(string: "maps://q?address=\(masjid.location.replacingOccurrences(of: " ", with: ","))") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    private func openCall(phone: String) {
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
        guard let url = URL(string: "tel://\(cleanPhone)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

// MARK: - Action Button Component
fileprivate struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(color.gradient)
                    )
                    .shadow(color: color.opacity(0.3), radius: 8, y: 4)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(width: 90)
        }
    }
}

// MARK: - Contact Info Card
fileprivate struct ContactInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(color.opacity(0.12))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

// MARK: - Map Preview Button Style
fileprivate struct MapPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

fileprivate struct ActionButtonHStack: View {
    var masjid: Masjid
    @State private var showMyMasjid = false
    @State private var showWebsite = false
    @State private var showingLocationAlert = false
    @State private var showingCallAlert = false
    @State private var showingMyMasjidUrlAlert = false
    
    var body: some View {
        
        HStack(spacing: 20) {
            
            Button {
                showMyMasjid = true
                
            } label: {
                VStack {
                    STActionButton(color: .pink, imageName: "clock.fill")
                    
                    Text("Salah Time")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
            }
            .sheet(isPresented: $showMyMasjid) {
                if masjid.myMasjidUrl != ""  {
                    WebView(url: masjid.myMasjidUrl)
                } else {
                    EmptyView()
                }
            }
            .accessibilityRemoveTraits(.isButton)
            .accessibilityLabel(Text("Go to my-masjid website"))
            
            
            Button {
                
                print(masjid.location)
                
                openMaps()
                
            } label: {
                VStack {
                    STActionButton(color: .orange, imageName: "location.fill")
                    Text("Location")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel(Text("Get directions"))
            .alert(isPresented: $showingLocationAlert) {
                Alert(title: Text("Something went wrong ❌"), message: Text("No address found"), dismissButton: .default(Text("Got it!")))
            }
            
            
            Button {
                
                openCall(phone: masjid.phone)
                
            } label: {
                VStack {
                    STActionButton(color: .green, imageName: "phone.fill")
                    Text("Call")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                }
            }
            .accessibilityLabel(Text("Call location"))
            .alert(isPresented: $showingCallAlert) {
                Alert(title: Text("Something went wrong 📵"), message: Text("No phone number found"), dismissButton: .default(Text("Got it!")))
            }
            
            
            Button {
                showWebsite = true
            } label: {
                VStack {
                    STActionButton(color: .blue, imageName: "network")
                    Text("Website")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityRemoveTraits(.isButton)
            .accessibilityLabel(Text("Go to website"))
            
        }
        .padding(EdgeInsets(top: 15, leading: 25, bottom: 15, trailing: 25))
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .padding()
        .sheet(isPresented: $showWebsite) {
            if masjid.website != ""  {
                SafariView(url: masjid.website)
            } else {
                EmptyView()
                
            }
        }
        
    }
    
    func openMaps() {
        
        guard let url = URL(string: "maps://q?address=\(masjid.location.replacingOccurrences(of: " ", with: ","))") else {
            print(masjid.location)
            showingLocationAlert = true
            return
        }
        print(masjid.location)
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
    }
    
    
    func openCall(phone: String) {
        guard let url = URL(string: "tel://\(masjid.phone.replacingOccurrences(of: " ", with: ""))") else {
            showingCallAlert = true
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
}

#Preview {
    let sampleMasjid = Masjid(
        name: "Masjid al-Haram",
        location: "Mecca, Saudi Arabia",
        phone: "+966 12 250 0000",
        description: "The largest mosque in the world and the holiest site in Islam, surrounding the Kaaba.",
        image: UIImage(named: "mosquealmasjidalharam") ?? UIImage(),
        website: "https://www.saudiembassy.net/masjid-al-haram",
        myMasjidUrl: "https://www.my-masjid.com",
        isVisited: false
    )
    
    NavigationStack {
        MasjidDetailView(masjid: sampleMasjid)
            .modelContainer(for: Masjid.self, inMemory: true)
    }
}


