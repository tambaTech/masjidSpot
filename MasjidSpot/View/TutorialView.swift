//
//  TutorialView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasViewedWalkthrough") var hasViewedWalkthrough: Bool = false
    
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    // Tutorial content with improved text and icons
    let pages: [TutorialPageContent] = [
        TutorialPageContent(
            image: "onboarding-1",
            icon: "book.fill",
            heading: "CREATE YOUR OWN MASJID GUIDE",
            subHeading: "Spot your visited masjids and create your own personalized guide to share with family and friends",
            accentColor: .blue
        ),
        TutorialPageContent(
            image: "onboarding-2",
            icon: "map.fill",
            heading: "SHOW YOU THE LOCATION",
            subHeading: "Search and locate your masjids on interactive maps with directions and distance tracking",
            accentColor: .green
        ),
        TutorialPageContent(
            image: "onboarding-3",
            icon: "building.2.fill",
            heading: "DISCOVER GREAT MASJIDS",
            subHeading: "Find masjids shared by your community and explore new places to pray wherever you go",
            accentColor: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    pages[currentPage].accentColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button at top
                HStack {
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            skipTutorial()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .opacity(currentPage < pages.count - 1 ? 1 : 0)
                
                // Main content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        EnhancedTutorialPage(
                            content: pages[index],
                            isCurrentPage: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .onChange(of: currentPage) { oldValue, newValue in
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                }
                
                // Bottom action area
                VStack(spacing: 16) {
                    // Progress indicators
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(currentPage == index ? 
                                      Color.mSPrimary : Color.mSPrimary.opacity(0.3))
                                .frame(width: currentPage == index ? 40 : 20, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Main action button
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        } else {
                            completeTutorial()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(currentPage == pages.count - 1 ? "GET STARTED" : "NEXT")
                                .font(.system(size: 18, weight: .bold))
                            
                            Image(systemName: currentPage == pages.count - 1 ? 
                                  "checkmark.circle.fill" : "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(Color.mSPrimary.gradient)
                                .shadow(color: Color.mSPrimary.opacity(0.4), radius: 12, y: 6)
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Swipe hint for first page
                    if currentPage == 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 14))
                            Text("Swipe to explore features")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .opacity(isAnimating ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            configurePageControl()
            isAnimating = true
        }
        .interactiveDismissDisabled(currentPage == pages.count - 1)
    }
    
    // MARK: - Helper Methods
    
    private func configurePageControl() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.mSPrimary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.mSPrimary.opacity(0.3))
    }
    
    private func skipTutorial() {
        withAnimation(.easeOut(duration: 0.2)) {
            hasViewedWalkthrough = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
        }
    }
    
    private func completeTutorial() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.easeOut(duration: 0.2)) {
            hasViewedWalkthrough = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Tutorial Page Content Model
struct TutorialPageContent {
    let image: String
    let icon: String
    let heading: String
    let subHeading: String
    let accentColor: Color
}

// MARK: - Enhanced Tutorial Page
struct EnhancedTutorialPage: View {
    let content: TutorialPageContent
    let isCurrentPage: Bool
    
    @State private var imageScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    @State private var iconRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon badge
            ZStack {
                Circle()
                    .fill(content.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: content.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(content.accentColor.gradient)
                    .rotationEffect(.degrees(iconRotation))
            }
            .padding(.bottom, 20)
            
            // Main image
            Image(content.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                .scaleEffect(imageScale)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Text content
            VStack(spacing: 16) {
                Text(content.heading)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(content.subHeading)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)
            }
            .padding(.horizontal, 40)
            .opacity(textOpacity)
            
            Spacer()
                .frame(height: 100)
        }
        .onChange(of: isCurrentPage) { oldValue, newValue in
            if newValue {
                animateIn()
            }
        }
        .onAppear {
            if isCurrentPage {
                animateIn()
            }
        }
    }
    
    private func animateIn() {
        // Reset states
        imageScale = 0.8
        textOpacity = 0
        iconRotation = -180
        
        // Animate in with staggered timing
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconRotation = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            imageScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            textOpacity = 1
        }
    }
}

// MARK: - Legacy Tutorial Page (for backwards compatibility)
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

// MARK: - Previews
#Preview {
    TutorialView()
}

#Preview("Dark Mode") {
    TutorialView()
        .preferredColorScheme(.dark)
}
#Preview("Single Page") {
    EnhancedTutorialPage(
        content: TutorialPageContent(
            image: "onboarding-1",
            icon: "book.fill",
            heading: "CREATE YOUR OWN MASJID GUIDE",
            subHeading: "Pin your favorite masjids and create your own personalized guide",
            accentColor: .blue
        ),
        isCurrentPage: true
    )
}

#Preview("Legacy Tutorial Page", traits: .sizeThatFitsLayout) {
    TutorialPage(
        image: "onboarding-1",
        heading: "CREATE YOUR OWN MOSQUE GUIDE",
        subHeading: "Pin your favorite mosques and create your own mosque guide"
    )
}

