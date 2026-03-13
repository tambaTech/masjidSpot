//
//  AboutView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//

import SwiftUI
import MessageUI

struct AboutView: View {
    
    enum WebLink: String, Identifiable {
        case rateUs = "https://apps.apple.com/app/id6738267025"
        case feedback = "https://www.tambatech.com"
        case privacyPolicy = "https://www.tambatech.com/privacy"
        case termsOfService = "https://www.tambatech.com/terms"
        case x = "https://www.x.com"
        case facebook = "https://www.facebook.com/"
        case instagram = "https://www.instagram.com/akamuhamadu"
        
        var id: String {
            rawValue
        }
    }
    
    @State private var link: WebLink?
    @State private var showShareSheet = false
    @State private var showMailComposer = false
    @State private var showCopiedAlert = false
    
    // App information
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xLarge) {
                    
                    // MARK: - App Header
                    headerSection
                    
                    // MARK: - Actions Section
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        DSSectionHeader("Quick Actions", subtitle: "Help us improve")
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                        
                        VStack(spacing: DesignSystem.Spacing.small) {
                            actionButton(
                                icon: "star.fill",
                                title: "Rate Us",
                                subtitle: "Share your experience on the App Store",
                                color: .orange,
                                action: { link = .rateUs }
                            )
                            
                            actionButton(
                                icon: "envelope.fill",
                                title: "Send Feedback",
                                subtitle: "Help us make MasjidSpot better",
                                color: .blue,
                                action: { showMailComposer = true }
                            )
                            
                            actionButton(
                                icon: "square.and.arrow.up.fill",
                                title: "Share App",
                                subtitle: "Tell others about MasjidSpot",
                                color: .green,
                                action: { showShareSheet = true }
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                    }
                    
                    // MARK: - Social Media Section
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        DSSectionHeader("Connect With Us", subtitle: "Follow us on social media")
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                        
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            socialButton(image: "x", color: Color(red: 0.1, green: 0.1, blue: 0.1)) {
                                link = .x
                            }
                            
                            socialButton(image: "facebook", color: Color(red: 0.23, green: 0.35, blue: 0.6)) {
                                link = .facebook
                            }
                            
                            socialButton(image: "instagram", color: Color(red: 0.83, green: 0.15, blue: 0.45)) {
                                link = .instagram
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                    }
                    
                    // MARK: - Legal Section
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        DSSectionHeader("Legal", subtitle: "Terms and policies")
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                        
                        VStack(spacing: DesignSystem.Spacing.small) {
                            legalButton(
                                icon: "hand.raised.fill",
                                title: "Privacy Policy",
                                action: { link = .privacyPolicy }
                            )
                            
                            legalButton(
                                icon: "doc.text.fill",
                                title: "Terms of Service",
                                action: { link = .termsOfService }
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                    }
                    
                    // MARK: - App Info Section
                    appInfoSection
                    
                }
                .padding(.vertical, DesignSystem.Spacing.large)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $link) { item in
                SafariView(url: item.rawValue)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = URL(string: "https://apps.apple.com/app/id6738267025") {
                    ActivityView(activityItems: [
                        "Check out MasjidSpot - Find mosques near you! 🕌",
                        url
                    ])
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(
                    recipients: ["feedback@tambatech.com"],
                    subject: "MasjidSpot Feedback",
                    body: """
                    
                    
                    ---
                    App Version: \(appVersion) (\(buildNumber))
                    iOS Version: \(UIDevice.current.systemVersion)
                    Device: \(UIDevice.current.model)
                    """
                )
            }
            .overlay(alignment: .top) {
                if showCopiedAlert {
                    copiedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Image("about")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .padding(.horizontal, DesignSystem.Spacing.xxLarge)
            
            VStack(spacing: DesignSystem.Spacing.xSmall) {
                Text("MasjidSpot")
                    .font(DesignSystem.Typography.largeTitle(weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Find mosques near you")
                    .font(DesignSystem.Typography.body(weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Action Button
    private func actionButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                            .fill(color.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(title)
                        .font(DesignSystem.Typography.headline(weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption(weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(DSCardButtonStyle())
    }
    
    // MARK: - Social Button
    private func socialButton(image: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 2)
                )
        }
        .buttonStyle(DSScaleButtonStyle())
    }
    
    // MARK: - Legal Button
    private func legalButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.mSPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous)
                            .fill(Color.mSPrimary.opacity(0.15))
                    )
                
                Text(title)
                    .font(DesignSystem.Typography.body(weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(DSCardButtonStyle())
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("Version \(appVersion) (\(buildNumber))")
                .font(DesignSystem.Typography.caption(weight: .medium))
                .foregroundStyle(.secondary)
            
            Button(action: {
                UIPasteboard.general.string = "Version \(appVersion) (\(buildNumber))"
                withAnimation(DesignSystem.Animation.springQuick) {
                    showCopiedAlert = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(DesignSystem.Animation.springQuick) {
                        showCopiedAlert = false
                    }
                }
            }) {
                Text("Tap to copy version info")
                    .font(DesignSystem.Typography.footnote(weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            
            Text("Made with ❤️ by TambaTech")
                .font(DesignSystem.Typography.footnote(weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.top, DesignSystem.Spacing.xSmall)
            
            Text("© 2025 MasjidSpot. All rights reserved.")
                .font(DesignSystem.Typography.footnote(weight: .regular))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }
    
    // MARK: - Copied Toast
    private var copiedToast: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Copied to clipboard")
                .font(DesignSystem.Typography.body(weight: .medium))
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding(.top, DesignSystem.Spacing.medium)
    }
}

// MARK: - Mail Composer
struct MailComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    AboutView()
}

