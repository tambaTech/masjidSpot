# Design System Quick Reference

## 🚀 Quick Start

Import the design system (it's available globally once added to your project):
```swift
import SwiftUI
// DesignSystem components are automatically available
```

## 📐 Common Patterns

### Creating a New View

```swift
struct MyNewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Section 1
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    DSSectionHeader("Section Title", subtitle: "Optional subtitle")
                    
                    DSCard {
                        VStack(spacing: DesignSystem.Spacing.small) {
                            Text("Card content")
                                .font(DesignSystem.Typography.body())
                        }
                    }
                }
                
                // Section 2
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    DSSectionHeader("Actions")
                    
                    DSPrimaryButton(
                        title: "Primary Action",
                        icon: "checkmark.circle.fill",
                        action: { /* action */ }
                    )
                    
                    DSSecondaryButton(
                        title: "Secondary Action",
                        icon: "arrow.right",
                        action: { /* action */ }
                    )
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
        .navigationTitle("My View")
    }
}
```

### Form Layout

```swift
VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
    DSSectionHeader("Required Information")
    
    VStack(spacing: DesignSystem.Spacing.medium) {
        EnhancedFormTextField(
            icon: "person.fill",
            placeholder: "Name",
            text: $name,
            isRequired: true
        )
        
        EnhancedFormTextField(
            icon: "envelope.fill",
            placeholder: "Email",
            text: $email
        )
    }
    
    DSPrimaryButton(
        title: "Submit",
        icon: "checkmark.circle.fill",
        action: submit,
        isLoading: isSubmitting,
        isDisabled: !isFormValid
    )
}
.padding(DesignSystem.Spacing.large)
```

### List with Cards

```swift
ScrollView {
    LazyVStack(spacing: DesignSystem.Spacing.medium) {
        ForEach(items) { item in
            Button(action: {
                // Navigate or action
            }) {
                DSCard {
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: item.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(Color.mSPrimary)
                        
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(DesignSystem.Typography.headline())
                            Text(item.subtitle)
                                .font(DesignSystem.Typography.caption())
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(DSCardButtonStyle())
        }
    }
    .padding(DesignSystem.Spacing.large)
}
```

### Empty State

```swift
if items.isEmpty {
    DSEmptyState(
        icon: "tray",
        title: "No Items",
        message: "Get started by adding your first item",
        actionTitle: "Add Item",
        action: { showAddSheet = true }
    )
} else {
    // List content
}
```

### Loading State

```swift
ZStack {
    // Main content
    ContentView()
    
    // Loading overlay
    if isLoading {
        DSLoadingOverlay(
            message: "Loading data...",
            icon: "arrow.down.circle"
        )
    }
}
```

### Info Sections

```swift
VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
    DSSectionHeader("Contact Information")
    
    VStack(spacing: DesignSystem.Spacing.small) {
        DSInfoRow(
            icon: "mappin.circle.fill",
            iconColor: .blue,
            title: "Address",
            value: address,
            action: { /* Open maps */ }
        )
        
        DSInfoRow(
            icon: "phone.fill",
            iconColor: .green,
            title: "Phone",
            value: phone,
            action: { /* Call */ }
        )
        
        DSInfoRow(
            icon: "envelope.fill",
            iconColor: .orange,
            title: "Email",
            value: email,
            action: { /* Email */ }
        )
    }
}
```

### Filter Chips

```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: DesignSystem.Spacing.xSmall) {
        ForEach(filters) { filter in
            Button(action: {
                selectedFilter = filter
            }) {
                DSTag(
                    icon: filter.icon,
                    title: filter.title,
                    color: filter.color,
                    isSelected: selectedFilter == filter
                )
            }
        }
    }
    .padding(.horizontal, DesignSystem.Spacing.large)
}
```

### Floating Action Button

```swift
ZStack(alignment: .bottomTrailing) {
    // Main content
    ContentView()
    
    // FAB
    DSFloatingActionButton(
        icon: "plus",
        title: "Add",
        action: { showAddSheet = true }
    )
    .padding(DesignSystem.Spacing.large)
}
```

## 🎨 Typography Usage

```swift
Text("Large Title")
    .font(DesignSystem.Typography.largeTitle())

Text("Title")
    .font(DesignSystem.Typography.title())

Text("Headline")
    .font(DesignSystem.Typography.headline())

Text("Body")
    .font(DesignSystem.Typography.body())

Text("Caption")
    .font(DesignSystem.Typography.caption())

Text("Footnote")
    .font(DesignSystem.Typography.footnote())

// With weight variations
Text("Bold Title")
    .font(DesignSystem.Typography.title(.bold))

Text("Semibold Body")
    .font(DesignSystem.Typography.body(.semibold))
```

## 📏 Spacing Usage

```swift
VStack(spacing: DesignSystem.Spacing.medium) {
    // Content
}
.padding(DesignSystem.Spacing.large)

HStack(spacing: DesignSystem.Spacing.xSmall) {
    // Icons and text
}

VStack(spacing: DesignSystem.Spacing.xxLarge) {
    // Large sections
}
```

## 🌈 Color Usage

```swift
// Primary brand color
.foregroundStyle(Color.mSPrimary)

// Semantic colors
.foregroundStyle(.primary)      // Main text
.foregroundStyle(.secondary)    // Supporting text
.foregroundStyle(.tertiary)     // Disabled text

// Accent colors for actions
.foregroundStyle(.blue)    // Location, navigation
.foregroundStyle(.green)   // Success, phone
.foregroundStyle(.orange)  // Warning, website
.foregroundStyle(.red)     // Error, delete
.foregroundStyle(.pink)    // Special features
```

## 🎭 Animation Usage

```swift
// Quick spring
withAnimation(DesignSystem.Animation.springQuick) {
    isExpanded.toggle()
}

// Bouncy spring
withAnimation(DesignSystem.Animation.springBouncy) {
    scale = 1.1
}

// Ease out
withAnimation(DesignSystem.Animation.easeOut) {
    opacity = 0
}

// Ease in/out
withAnimation(DesignSystem.Animation.easeInOut) {
    offset = 100
}
```

## 💫 Shadow Usage

```swift
// Using modifier
MyView()
    .dsShadow()  // Default medium shadow

MyView()
    .dsShadow(DesignSystem.Shadow.light())

MyView()
    .dsShadow(DesignSystem.Shadow.heavy())

MyView()
    .dsShadow(DesignSystem.Shadow.accent())  // For primary buttons

// Manual application
.shadow(
    color: DesignSystem.Shadow.medium().color,
    radius: DesignSystem.Shadow.medium().radius,
    x: DesignSystem.Shadow.medium().x,
    y: DesignSystem.Shadow.medium().y
)
```

## 🎯 Haptic Feedback

```swift
// Light tap (filters, secondary actions)
let generator = UIImpactFeedbackGenerator(style: .light)
generator.impactOccurred()

// Medium tap (primary actions)
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()

// Heavy tap (dramatic actions)
let generator = UIImpactFeedbackGenerator(style: .heavy)
generator.impactOccurred()

// Selection change
let generator = UISelectionFeedbackGenerator()
generator.selectionChanged()

// Success
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)

// Warning
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.warning)

// Error
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.error)
```

## 🎨 Corner Radius

```swift
RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)

// For capsules
Capsule()  // or
RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
```

## 🔘 Button Styles

```swift
// Card button (subtle press)
Button(action: { }) {
    Text("Action")
}
.buttonStyle(DSCardButtonStyle())

// Scale button (more dramatic)
Button(action: { }) {
    Text("Action")
}
.buttonStyle(DSScaleButtonStyle())

// Manual press animation
Button(action: { }) {
    Text("Action")
}
.dsPressAnimation(isPressed: isPressed)
```

## 📦 Card Styling

```swift
// Using DSCard component
DSCard {
    Text("Content")
}

// Using modifier
VStack {
    Text("Content")
}
.dsCard()

// Custom padding
VStack {
    Text("Content")
}
.dsCard(padding: DesignSystem.Spacing.large)
```

## 🎬 Common Animation Patterns

### Fade In
```swift
.opacity(isVisible ? 1 : 0)
.animation(DesignSystem.Animation.easeOut, value: isVisible)
```

### Scale In
```swift
.scaleEffect(isVisible ? 1 : 0.8)
.opacity(isVisible ? 1 : 0)
.animation(DesignSystem.Animation.springQuick, value: isVisible)
```

### Slide In
```swift
.offset(y: isVisible ? 0 : 50)
.opacity(isVisible ? 1 : 0)
.animation(DesignSystem.Animation.springQuick, value: isVisible)
```

### Rotation
```swift
.rotationEffect(.degrees(isRotated ? 180 : 0))
.animation(DesignSystem.Animation.springBouncy, value: isRotated)
```

## 📱 Responsive Patterns

### Adaptive Padding
```swift
#if os(iOS)
.padding(.horizontal, DesignSystem.Spacing.large)
#elseif os(macOS)
.padding(.horizontal, DesignSystem.Spacing.xxLarge)
#endif
```

### Adaptive Layout
```swift
ViewThatFits {
    HStack {
        // Horizontal layout for wide screens
    }
    
    VStack {
        // Vertical layout for narrow screens
    }
}
```

## ✅ Checklist for New Views

- [ ] Use design system spacing
- [ ] Apply consistent typography
- [ ] Use design system colors
- [ ] Add haptic feedback to interactions
- [ ] Use design system animations
- [ ] Apply appropriate shadows
- [ ] Use consistent corner radius
- [ ] Add loading states
- [ ] Add empty states
- [ ] Add error states
- [ ] Test in dark mode
- [ ] Test with dynamic type
- [ ] Add accessibility labels
- [ ] Use semantic colors

## 🎓 Common Mistakes to Avoid

❌ **Don't**: Use hard-coded spacing values
```swift
.padding(16)  // Wrong
```
✅ **Do**: Use design system spacing
```swift
.padding(DesignSystem.Spacing.medium)  // Correct
```

---

❌ **Don't**: Create custom button styling
```swift
Button(action: { }) {
    Text("Action")
        .padding()
        .background(Color.blue)
}
```
✅ **Do**: Use design system buttons
```swift
DSPrimaryButton(title: "Action", icon: nil, action: { })
```

---

❌ **Don't**: Forget haptic feedback
```swift
Button(action: save) {
    Text("Save")
}
```
✅ **Do**: Add haptic feedback
```swift
Button(action: {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    save()
}) {
    Text("Save")
}
```

---

❌ **Don't**: Use inconsistent animations
```swift
.animation(.default, value: state)
```
✅ **Do**: Use design system animations
```swift
.animation(DesignSystem.Animation.springQuick, value: state)
```

## 🔍 Finding Components

| Need | Component | File |
|------|-----------|------|
| Card container | `DSCard` | DesignSystem.swift |
| Primary button | `DSPrimaryButton` | DesignSystem.swift |
| Section header | `DSSectionHeader` | DesignSystem.swift |
| Info row | `DSInfoRow` | DesignSystem.swift |
| Empty state | `DSEmptyState` | DesignSystem.swift |
| Loading overlay | `DSLoadingOverlay` | DesignSystem.swift |
| Tag/chip | `DSTag` | DesignSystem.swift |
| FAB | `DSFloatingActionButton` | DesignSystem.swift |
| Form field | `EnhancedFormTextField` | NewMasjidView.swift |
| Text area | `EnhancedFormTextView` | NewMasjidView.swift |

## 📚 Additional Resources

- See `DESIGN_SYSTEM_ENHANCEMENTS.md` for complete documentation
- Check preview sections in `DesignSystem.swift` for examples
- Review existing views for usage patterns
- Test components in both light and dark mode

---

Remember: **Consistency is key!** Using the design system ensures your app looks professional and maintains a cohesive user experience across all views.
