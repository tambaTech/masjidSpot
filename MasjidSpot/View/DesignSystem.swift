//
//  DesignSystem.swift
//  MasjidSpot
//
//  Design System for consistent UI across the app
//

import SwiftUI

// MARK: - Design System

/// Centralized design system for MasjidSpot app
/// Ensures consistency across all views with reusable components
struct DesignSystem {
    
    // MARK: - Typography
    struct Typography {
        static func largeTitle(weight: Font.Weight = .bold) -> Font {
            .system(size: 32, weight: weight, design: .rounded)
        }
        
        static func title(weight: Font.Weight = .bold) -> Font {
            .system(size: 22, weight: weight)
        }
        
        static func headline(weight: Font.Weight = .semibold) -> Font {
            .system(size: 18, weight: weight)
        }
        
        static func body(weight: Font.Weight = .regular) -> Font {
            .system(size: 16, weight: weight)
        }
        
        static func caption(weight: Font.Weight = .medium) -> Font {
            .system(size: 13, weight: weight)
        }
        
        static func footnote(weight: Font.Weight = .regular) -> Font {
            .system(size: 12, weight: weight)
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 24
        static let pill: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadow {
        static func light() -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(0.05), 4, 0, 2)
        }
        
        static func medium() -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(0.1), 8, 0, 4)
        }
        
        static func heavy() -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(0.15), 12, 0, 6)
        }
        
        static func accent() -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.mSPrimary.opacity(0.3), 12, 0, 6)
        }
    }
    
    // MARK: - Animations
    struct Animation {
        static let springQuick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Reusable UI Components

/// Enhanced card container with consistent styling
struct DSCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DesignSystem.Spacing.medium
    var shadowStyle: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = DesignSystem.Shadow.light()
    
    init(padding: CGFloat = DesignSystem.Spacing.medium,
         shadowStyle: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = DesignSystem.Shadow.light(),
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.shadowStyle = shadowStyle
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .shadow(color: shadowStyle.color, radius: shadowStyle.radius, x: shadowStyle.x, y: shadowStyle.y)
    }
}

/// Primary button with consistent styling
struct DSPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.small) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.headline(weight: .semibold))
                }
                
                Text(title)
                    .font(DesignSystem.Typography.headline(weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                    .fill(isDisabled ? Color.gray.gradient : Color.mSPrimary.gradient)
            )
            .shadow(
                color: isDisabled ? .clear : Color.mSPrimary.opacity(0.3),
                radius: 12,
                y: 6
            )
        }
        .disabled(isDisabled || isLoading)
    }
}

/// Secondary button with consistent styling
struct DSSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.body(weight: .medium))
                }
                
                Text(title)
                    .font(DesignSystem.Typography.body(weight: .medium))
            }
            .foregroundStyle(Color.mSPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                    .fill(Color.mSPrimary.opacity(0.1))
            )
        }
    }
}

/// Icon button with badge styling
struct DSIconButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    init(icon: String, color: Color = .mSPrimary, size: CGFloat = 48, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                        .fill(color.opacity(0.12))
                )
        }
    }
}

/// Section header with consistent styling
struct DSSectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
            Text(title)
                .font(DesignSystem.Typography.title(weight: .bold))
                .foregroundStyle(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption(weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Info row with icon and text
struct DSInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let action: (() -> Void)?
    
    init(icon: String, iconColor: Color = .mSPrimary, title: String, value: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    action()
                }) {
                    rowContent
                }
            } else {
                rowContent
            }
        }
    }
    
    @ViewBuilder
    private var rowContent: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(title)
                    .font(DesignSystem.Typography.caption(weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(DesignSystem.Typography.body(weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Tag/Chip component
struct DSTag: View {
    let icon: String?
    let title: String
    let color: Color
    var isSelected: Bool = false
    
    init(icon: String? = nil, title: String, color: Color = .mSPrimary, isSelected: Bool = false) {
        self.icon = icon
        self.title = title
        self.color = color
        self.isSelected = isSelected
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xSmall) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.caption(weight: .semibold))
            }
            
            Text(title)
                .font(DesignSystem.Typography.caption(weight: isSelected ? .semibold : .medium))
        }
        .foregroundStyle(isSelected ? .white : color)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.xSmall)
        .background(
            Capsule()
                .fill(isSelected ? color : color.opacity(0.1))
        )
    }
}

/// Loading overlay
struct DSLoadingOverlay: View {
    let message: String
    let icon: String?
    
    init(message: String = "Loading...", icon: String? = nil) {
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.large) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Color.mSPrimary)
                }
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.mSPrimary)
                
                Text(message)
                    .font(DesignSystem.Typography.headline(weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(DesignSystem.Spacing.xxLarge)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
    }
}

/// Empty state view
struct DSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xLarge) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(.secondary)
            
            VStack(spacing: DesignSystem.Spacing.small) {
                Text(title)
                    .font(DesignSystem.Typography.title(weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(DesignSystem.Typography.body(weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xxxLarge)
            }
            
            if let actionTitle = actionTitle, let action = action {
                DSPrimaryButton(title: actionTitle, icon: "plus.circle.fill", action: action)
                    .padding(.horizontal, DesignSystem.Spacing.xxLarge)
                    .padding(.top, DesignSystem.Spacing.xSmall)
            }
        }
        .padding()
    }
}

/// Floating Action Button
struct DSFloatingActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.xSmall) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(
                Capsule()
                    .fill(Color.mSPrimary.gradient)
                    .shadow(color: Color.mSPrimary.opacity(0.4), radius: 12, y: 6)
            )
        }
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply consistent card styling
    func dsCard(padding: CGFloat = DesignSystem.Spacing.medium) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }
    
    /// Apply button press animation
    func dsPressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.springQuick, value: isPressed)
    }
    
    /// Apply consistent shadow
    func dsShadow(_ style: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = DesignSystem.Shadow.medium()) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Button Styles

struct DSCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.springQuick, value: configuration.isPressed)
    }
}

struct DSScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(DesignSystem.Animation.springBouncy, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Design System Components") {
    ScrollView {
        VStack(spacing: 20) {
            DSSectionHeader("Typography", subtitle: "Consistent text styles")
            
            DSCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Large Title")
                        .font(DesignSystem.Typography.largeTitle(weight: .bold))
                    Text("Title")
                        .font(DesignSystem.Typography.title(weight: .bold))
                    Text("Headline")
                        .font(DesignSystem.Typography.headline(weight: .semibold))
                    Text("Body Text")
                        .font(DesignSystem.Typography.body(weight: .regular))
                    Text("Caption")
                        .font(DesignSystem.Typography.caption(weight: .medium))
                }
            }
            .padding(.horizontal)
            
            DSSectionHeader("Buttons", subtitle: "Primary and secondary actions")
            
            VStack(spacing: 12) {
                DSPrimaryButton(title: "Primary Action", icon: "checkmark.circle.fill", action: {})
                DSSecondaryButton(title: "Secondary Action", icon: "arrow.right", action: {})
            }
            .padding(.horizontal)
            
            DSSectionHeader("Tags", subtitle: "Chips and badges")
            
            HStack(spacing: 8) {
                DSTag(icon: "checkmark", title: "Selected", color: .green, isSelected: true)
                DSTag(icon: "star.fill", title: "Featured", color: .orange)
                DSTag(title: "New", color: .blue)
            }
            .padding(.horizontal)
            
            DSSectionHeader("Info Rows", subtitle: "Information display")
            
            VStack(spacing: 12) {
                DSInfoRow(
                    icon: "mappin.circle.fill",
                    iconColor: .blue,
                    title: "Address",
                    value: "123 Main Street, City",
                    action: {}
                )
                
                DSInfoRow(
                    icon: "phone.fill",
                    iconColor: .green,
                    title: "Phone",
                    value: "+1 234 567 8900"
                )
            }
            .padding(.horizontal)
            
            DSEmptyState(
                icon: "building.2",
                title: "No Items",
                message: "Start by adding your first item",
                actionTitle: "Add Item",
                action: {}
            )
        }
        .padding(.vertical)
    }
}
