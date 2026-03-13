# MasjidMapView Interactive Improvements

## 🎯 Problem Solved

Previously, the map would automatically re-center to the user's location whenever:
- Mosques were loaded or refreshed
- The view appeared
- Data was updated

This made it **impossible for users to explore** different areas of the map, as they would constantly be redirected back to their location.

---

## ✨ Solution Implemented

### 1. **User Interaction Tracking**

Added state variables to track when users interact with the map:

```swift
// Track user interaction to prevent auto-centering
@State private var userHasInteractedWithMap = false
@State private var shouldUpdateCameraPosition = true
```

**How it works:**
- `userHasInteractedWithMap` - Flags when user has panned, zoomed, or moved the map
- `shouldUpdateCameraPosition` - Controls whether programmatic camera updates should apply

---

### 2. **Smart Camera Position Updates**

Modified all camera positioning functions to respect user interaction:

#### ✅ `setInitialLocation()`
```swift
@MainActor
private func setInitialLocation() async {
    // Disable auto-updates temporarily
    shouldUpdateCameraPosition = false
    
    // ... set the region ...
    
    // Re-enable auto-updates after a brief delay
    try? await Task.sleep(nanoseconds: 500_000_000)
    shouldUpdateCameraPosition = true
}
```

#### ✅ `fitAllMosques()`
```swift
@MainActor
private func fitAllMosques() async {
    // Disable auto-updates temporarily
    shouldUpdateCameraPosition = false
    
    // ... calculate and set region ...
    
    // Re-enable auto-updates after a brief delay
    try? await Task.sleep(nanoseconds: 500_000_000)
    shouldUpdateCameraPosition = true
}
```

#### ✅ `loadMosques()`
```swift
private func loadMosques() async {
    // ... load mosques ...
    
    // Only fit all mosques if user hasn't started exploring
    if !userHasInteractedWithMap {
        await fitAllMosques()
    }
}
```

#### ✅ `refreshData()`
```swift
private func refreshData() async {
    await loadMosques()
    
    // Only return to initial location if user hasn't moved the map
    if !userHasInteractedWithMap {
        await setInitialLocation()
    }
}
```

---

### 3. **Enhanced UI with "Return to Location" Button**

Added a **dynamic floating button** that appears when users pan away from their location:

```swift
.safeAreaInset(edge: .bottom) {
    HStack(spacing: 12) {
        // Show "Return to Location" button when user has interacted with map
        if userHasInteractedWithMap {
            Button(action: {
                userHasInteractedWithMap = false
                shouldUpdateCameraPosition = true
                Task {
                    await setInitialLocation()
                }
            }) {
                Label("My Location", systemImage: "location.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .transition(.move(edge: .leading).combined(with: .opacity))
        }
        
        Spacer()
        
        Button(action: {
            showingDirectionsOptions = true
        }) {
            Label("Directions", systemImage: "car.fill")
                // ... styling ...
        }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: userHasInteractedWithMap)
}
```

**Features:**
- ✅ Appears with smooth spring animation when user pans/zooms
- ✅ Green color to differentiate from Directions button
- ✅ Resets interaction state and returns to user location when tapped
- ✅ Disappears when not needed

---

### 4. **Gesture Detection in CustomMapView**

Enhanced the `MKMapViewDelegate` to detect user gestures:

```swift
class Coordinator: NSObject, MKMapViewDelegate {
    var shouldUpdateCameraPosition: Bool = true
    
    // Track when user starts interacting with the map
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // Check if this is a user-initiated change (not programmatic)
        if !shouldUpdateCameraPosition {
            return
        }
        
        // Detect user interaction by checking if there's an active gesture
        if let gestureRecognizers = mapView.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer.state == .began || recognizer.state == .changed {
                    parent.onUserInteraction()
                    break
                }
            }
        }
    }
}
```

**Benefits:**
- Detects pan, pinch (zoom), and rotation gestures
- Differentiates between user gestures and programmatic changes
- Only triggers when `shouldUpdateCameraPosition` is true

---

### 5. **Updated CustomMapView Signature**

Added new parameters to pass interaction state:

```swift
struct CustomMapView: UIViewRepresentable {
    let mapType: MKMapType
    @Binding var position: CustomMapCameraPosition
    let mosques: [CKRecord]
    let locationGeocoder: CloudKitLocationGeocoder
    @Binding var shouldUpdateCameraPosition: Bool  // ✨ NEW
    let onMosqueSelected: (CKRecord) -> Void
    let onLookAroundRequested: (MKLookAroundScene) -> Void
    let onUserInteraction: () -> Void  // ✨ NEW
}
```

---

### 6. **Toolbar Button Improvements**

Updated all navigation/camera buttons to reset interaction state when explicitly used:

```swift
ToolbarItem(placement: .navigationBarLeading) {
    Button(action: {
        userHasInteractedWithMap = false  // Reset state
        shouldUpdateCameraPosition = true
        Task {
            await setInitialLocation()
        }
    }) {
        Image(systemName: "location.fill")
    }
}
```

**Applies to:**
- ✅ Location button (nav bar leading)
- ✅ "Fit All Mosques" menu item
- ✅ "My Location" menu item

---

## 🎨 User Experience Flow

### **Initial Load**
1. App loads mosques from CloudKit
2. Map automatically fits all mosques in view
3. Centers on user location (if available)

### **User Explores**
1. User pans/zooms to explore different areas
2. `userHasInteractedWithMap` becomes `true`
3. "My Location" button appears at bottom-left
4. Map stays where user positioned it

### **User Continues Interacting**
1. Pull-to-refresh → Map stays in current position
2. Search mosques → Map doesn't jump away
3. Select mosque → Map focuses on mosque, but user can return to exploring

### **User Returns to Location**
1. Taps "My Location" button (bottom-left) OR
2. Taps location button (nav bar) OR
3. Uses menu option
4. Map smoothly animates to user location
5. `userHasInteractedWithMap` resets to `false`

---

## 📊 Technical Benefits

| Feature | Before | After |
|---------|--------|-------|
| **Exploring Map** | ❌ Impossible | ✅ Fully supported |
| **Auto-centering** | ❌ Always forced | ✅ Only on first load |
| **User Control** | ❌ Limited | ✅ Complete control |
| **Return to Location** | Manual nav bar tap only | ✅ Dynamic floating button |
| **Gesture Detection** | None | ✅ Full gesture tracking |
| **State Management** | Basic | ✅ Advanced with flags |

---

## 🚀 Future Enhancements

### 1. **Persistent Map State**
Save last map position using `@AppStorage`:
```swift
@AppStorage("lastMapLatitude") private var lastLat: Double = 21.4225
@AppStorage("lastMapLongitude") private var lastLon: Double = 39.8262
@AppStorage("lastMapZoom") private var lastZoom: Double = 0.1
```

### 2. **Smart Re-centering**
Add option to auto-center when user is far from mosques:
```swift
if userDistanceFromNearestMosque > 100000 { // 100km
    // Suggest returning to mosque area
}
```

### 3. **Compass/Orientation Indicator**
Show current heading when map is rotated:
```swift
.mapStyle(.hybrid(elevation: .realistic, showsTraffic: true))
```

### 4. **Haptic Feedback**
Add haptics when user starts/stops panning:
```swift
import CoreHaptics
// Trigger light impact when starting to pan
```

### 5. **Animation Customization**
Allow users to control animation speed:
```swift
@AppStorage("mapAnimationSpeed") private var animationDuration: Double = 0.5
```

---

## ✅ Testing Checklist

- [x] Map doesn't auto-center when user pans
- [x] "My Location" button appears after panning
- [x] Button animates smoothly in/out
- [x] Returning to location works correctly
- [x] Pull-to-refresh doesn't force re-centering
- [x] Initial load still centers properly
- [x] Toolbar buttons reset state correctly
- [x] Gesture detection works on all map types
- [x] Works with search functionality
- [x] Works with mosque selection

---

## 📝 Files Modified

1. ✅ `MasjidMapView.swift` - Main improvements

---

**Date:** March 12, 2026  
**Status:** ✅ Complete  
**Compatible with:** iOS 15+, iPadOS 15+  
**Tested on:** iOS 18.0 Simulator  

---

## 🎓 Key Learnings

1. **State-Driven UI** - Using flags to control when automatic behaviors should apply
2. **Gesture Detection** - Leveraging `MKMapViewDelegate` to detect user interaction
3. **Smooth Animations** - Using spring animations for natural UI transitions
4. **User Intent** - Differentiating between programmatic and user-initiated changes
5. **Conditional Updates** - Only updating camera when appropriate, respecting user control

---

## 💡 Implementation Tips

- Use `regionWillChangeAnimated` to detect map changes early
- Check gesture recognizer states to confirm user interaction
- Add brief delays after programmatic changes to prevent race conditions
- Use bindings to pass state between SwiftUI and UIViewRepresentable
- Combine animations for polished transitions (`.move + .opacity`)

---

**Happy Mapping! 🗺️**
