# MasjidMapView - User Location Improvements

## Summary
Updated `MasjidMapView` to properly start centered on the user's location instead of defaulting to showing all mosques.

## Changes Made

### 1. **MasjidMapView.swift** - Updated `setInitialLocation()` method
**Before:** The method would immediately check for user location and fall back to Mecca if not available.

**After:** Now waits up to 1 second for the location manager to get the user's location before proceeding:

```swift
@MainActor
private func setInitialLocation() async {
    // Give location manager time to get user location
    if locationManager.currentLocation == nil {
        // Wait a bit for location to be available
        for _ in 0..<10 { // Try for up to 1 second
            if locationManager.currentLocation != nil {
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    // ... rest of the method
}
```

### 2. **MasjidMapView.swift** - Updated `.task` modifier
Added a delay after requesting location permission to give the system time to get the user's location:

```swift
.task {
    // Request location permission first
    locationManager.requestLocationPermission()
    
    // Wait a moment for location to be determined
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    
    // Load mosques
    await loadMosques()
    
    // Set initial location (will center on user or fallback to Mecca)
    if !userHasInteractedWithMap {
        await setInitialLocation()
    }
}
```

### 3. **MasjidMapView.swift** - Updated `loadMosques()` method
Removed the automatic "fit all mosques" behavior that was overriding the user location centering:

```swift
private func loadMosques() async {
    isLoading = true
    await cloudStore.fetchCloudMosques()
    isLoading = false
    
    // Start geocoding locations in the background
    Task {
        await locationGeocoder.geocodeAllMosqueLocations(cloudStore.cloudMosques)
    }
    
    // Don't auto-fit all mosques - let the map stay centered on user location
    // Users can manually trigger "Fit All Mosques" from the menu if desired
}
```

### 4. **LocationManager.swift** - Improved location updates
Updated to use continuous location updates instead of one-time requests:

```swift
func requestLocationPermission() {
    let currentStatus = locationManager.authorizationStatus
    
    // If already authorized, start updating immediately
    if currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways {
        locationManager.startUpdatingLocation()
    } else {
        locationManager.requestWhenInUseAuthorization()
    }
}
```

And in the delegate method:

```swift
nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
        self.authorizationStatus = manager.authorizationStatus
        
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            // Start continuous location updates for better accuracy
            manager.startUpdatingLocation()
        }
    }
}
```

## Behavior Changes

### Before:
1. Map would load and immediately fit all mosques in view
2. User location might not be ready in time
3. Map would show entire mosque collection, potentially zoomed way out

### After:
1. Map requests location permission
2. Waits briefly for location to be available
3. Centers on user's location with a ~2-3km radius view
4. Shows nearby mosques
5. Users can manually use "Fit All Mosques" button in the menu if they want to see all mosques

## User Experience Improvements

✅ **Better initial view**: Users now see their immediate surroundings
✅ **More relevant results**: Nearby mosques are immediately visible
✅ **Still accessible**: Users can manually fit all mosques via the menu
✅ **Debug logging**: Added console logs to help debug location issues
✅ **Graceful fallback**: Still falls back to Mecca if location is unavailable

## Testing Checklist

- [ ] Test with location permissions already granted
- [ ] Test with location permissions denied
- [ ] Test with location services disabled
- [ ] Test the "Fit All Mosques" menu option
- [ ] Verify user location dot appears on map
- [ ] Check console logs for location centering confirmation

## Notes

The map is already configured to:
- Show user's location (`showsUserLocation = true`)
- Track user location without following mode
- Update position when user moves
- Show 3D buildings and terrain for better context
