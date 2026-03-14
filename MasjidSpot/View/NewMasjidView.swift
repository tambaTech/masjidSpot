//
//  NewMasjidView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/3/25.
//

import CoreLocation
import SwiftUI
import SwiftData
import MapKit



struct NewMasjidView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    enum PhotoSource: Identifiable {
        case photoLibrary
        case camera
        
        var id: Int {
            hashValue
        }
    }
    
    @State private var photoSource: PhotoSource?
    @State private var showPhotoOptions = false
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isValidatingAddress = false
    @State private var addressValidationResult: String?
    @FocusState private var focusedField: FormField?
    
    enum FormField: Hashable {
        case name, location, phone, website, myMasjidUrl, description
    }
    
    @Bindable private var masjidFormViewModel: MasjidFormViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Photo Section
                        VStack(spacing: 12) {
                            Text("Masjid Photo")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                showPhotoOptions.toggle()
                            }) {
                                ZStack(alignment: .bottomTrailing) {
                                    Image(uiImage: masjidFormViewModel.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    Color.mSPrimary.opacity(0.1),
                                                    Color.mSPrimary.opacity(0.05)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 1)
                                        )
                                    
                                    // Camera badge
                                    HStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(isDefaultImage ? "Add Photo" : "Change Photo")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(.black.opacity(0.7))
                                    )
                                    .padding(16)
                                }
                            }
                            
                            Text("Tap to add a photo of the masjid")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // MARK: - Required Information
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Required Information")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                                
                                Image(systemName: "asterisk")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                            
                            EnhancedFormTextField(
                                icon: "building.2.fill",
                                placeholder: "Masjid Name",
                                text: $masjidFormViewModel.name,
                                isRequired: true
                            )
                            .focused($focusedField, equals: .name)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                EnhancedFormTextField(
                                    icon: "mappin.circle.fill",
                                    placeholder: "Full Address",
                                    text: $masjidFormViewModel.location,
                                    isRequired: true
                                )
                                .focused($focusedField, equals: .location)
                                .onChange(of: masjidFormViewModel.location) { oldValue, newValue in
                                    addressValidationResult = nil
                                }
                                
                                if isValidatingAddress {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Validating address...")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                }
                                
                                if let result = addressValidationResult {
                                    HStack(spacing: 8) {
                                        Image(systemName: result.contains("✓") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(result.contains("✓") ? .green : .orange)
                                        
                                        Text(result)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                }
                                
                                Button(action: {
                                    validateAddress()
                                }) {
                                    validateAddressButtonContent
                                }
                                .disabled(masjidFormViewModel.location.isEmpty || isValidatingAddress)
                            }
                        }
                        
                        // MARK: - Contact Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Contact Information")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            EnhancedFormTextField(
                                icon: "phone.fill",
                                placeholder: "Phone Number",
                                text: $masjidFormViewModel.phone
                            )
                            .focused($focusedField, equals: .phone)
                            .keyboardType(.phonePad)
                            
                            EnhancedFormTextField(
                                icon: "safari.fill",
                                placeholder: "Website URL",
                                text: $masjidFormViewModel.website
                            )
                            .focused($focusedField, equals: .website)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .textInputAutocapitalization(.never)
                            
                            EnhancedFormTextField(
                                icon: "clock.fill",
                                placeholder: "My-Masjid URL (Prayer Times)",
                                text: $masjidFormViewModel.myMasjidUrl
                            )
                            .focused($focusedField, equals: .myMasjidUrl)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .textInputAutocapitalization(.never)
                        }
                        
                        // MARK: - Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            EnhancedFormTextView(
                                placeholder: "Tell us about this masjid...",
                                text: $masjidFormViewModel.summary,
                                height: 120
                            )
                            .focused($focusedField, equals: .description)
                            
                            Text("Add details like facilities, parking info, or special features")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        
                        // MARK: - Save Button
                        Button(action: {
                            save()
                        }) {
                            HStack(spacing: 10) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                
                                Text(isSaving ? "Saving..." : "Add Masjid")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isFormValid && !isSaving ? Color.mSPrimary.gradient : Color.gray.gradient)
                            )
                            .shadow(color: isFormValid && !isSaving ? .mSPrimary.opacity(0.3) : .clear, radius: 12, y: 6)
                        }
                        .disabled(!isFormValid || isSaving)
                        .padding(.top, 8)
                        
                        // Bottom spacing
                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Loading overlay
                if isSaving {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.mSPrimary)
                                
                                Text("Adding Masjid...")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(32)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .transition(.opacity)
                }
            }
            .navigationTitle("Add Masjid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 17))
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    Button("Done") {
                        focusedField = nil
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.mSPrimary)
                }
            }
        }
        .confirmationDialog("Choose Photo Source", isPresented: $showPhotoOptions, titleVisibility: .visible) {
            Button("Camera") {
                photoSource = .camera
            }
            
            Button("Photo Library") {
                photoSource = .photoLibrary
            }
        }
        .fullScreenCover(item: $photoSource) { source in
            switch source {
            case .photoLibrary:
                ImagePicker(sourceType: .photoLibrary, selectedImage: $masjidFormViewModel.image)
                    .ignoresSafeArea()
            case .camera:
                ImagePicker(sourceType: .camera, selectedImage: $masjidFormViewModel.image)
                    .ignoresSafeArea()
            }
        }
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("The masjid has been added successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .tint(.mSPrimary)
    }
    
    init() {
        let viewModel = MasjidFormViewModel()
        viewModel.image = UIImage(named: "newphoto") ?? UIImage()
        masjidFormViewModel = viewModel
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !masjidFormViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !masjidFormViewModel.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isDefaultImage: Bool {
        // Check if this is the default "newphoto" image
        masjidFormViewModel.image.pngData() == UIImage(named: "newphoto")?.pngData()
    }
    
    private var validateAddressButtonContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 13, weight: .medium))
            Text("Validate Address")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(Color.mSPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.mSPrimary.opacity(0.1))
        )
    }
    
    // MARK: - Methods
    
    private func validateAddress() {
        guard !masjidFormViewModel.location.isEmpty else { return }
        
        isValidatingAddress = true
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        geocodeAddress(masjidFormViewModel.location) { coordinate in
            DispatchQueue.main.async {
                isValidatingAddress = false
                
                if coordinate != nil {
                    addressValidationResult = "✓ Address verified"
                    let successGenerator = UINotificationFeedbackGenerator()
                    successGenerator.notificationOccurred(.success)
                } else {
                    addressValidationResult = "⚠ Could not verify address"
                    let warningGenerator = UINotificationFeedbackGenerator()
                    warningGenerator.notificationOccurred(.warning)
                }
            }
        }
    }
    
    private func save() {
        guard isFormValid else { return }
        
        isSaving = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Dismiss keyboard
        focusedField = nil
        
        // Create the mosque
        let masjid = Masjid(
            name: masjidFormViewModel.name.trimmingCharacters(in: .whitespacesAndNewlines),
            location: masjidFormViewModel.location.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: masjidFormViewModel.phone.trimmingCharacters(in: .whitespacesAndNewlines),
            description: masjidFormViewModel.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            image: masjidFormViewModel.image,
            website: masjidFormViewModel.website.trimmingCharacters(in: .whitespacesAndNewlines),
            myMasjidUrl: masjidFormViewModel.myMasjidUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            isVisited: false,
            latitude: 0.0,
            longitude: 0.0
        )
        
        // Insert the mosque
        modelContext.insert(masjid)
        
        // Save immediately
        do {
            try modelContext.save()
        } catch {
            isSaving = false
            errorMessage = "Failed to save masjid: \(error.localizedDescription)"
            showErrorAlert = true
            
            let errorGenerator = UINotificationFeedbackGenerator()
            errorGenerator.notificationOccurred(.error)
            return
        }
        
        // Geocode the address
        geocodeAddress(masjid.location) { coordinate in
            if let coordinate = coordinate {
                masjid.latitude = coordinate.latitude
                masjid.longitude = coordinate.longitude
                try? modelContext.save()
                print("✅ Geocoded \(masjid.name): \(coordinate.latitude), \(coordinate.longitude)")
            } else {
                print("⚠️ Could not geocode address for \(masjid.name)")
            }
            
            // Save to CloudKit
            Task {
                do {
                    let cloudStore = MasjidCloudStore()
                    try await cloudStore.saveRecordToCloud(mosque: masjid)
                    print("✅ Successfully saved to CloudKit")
                    
                    await MainActor.run {
                        isSaving = false
                        
                        let successGenerator = UINotificationFeedbackGenerator()
                        successGenerator.notificationOccurred(.success)
                        
                        showSuccessAlert = true
                    }
                } catch {
                    print("❌ Failed to save to CloudKit: \(error.localizedDescription)")
                    
                    await MainActor.run {
                        isSaving = false
                        errorMessage = "Saved locally but failed to sync: \(error.localizedDescription)"
                        showErrorAlert = true
                        
                        let errorGenerator = UINotificationFeedbackGenerator()
                        errorGenerator.notificationOccurred(.error)
                    }
                }
            }
        }
    }
    
    private func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard !address.isEmpty else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = address
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                await MainActor.run {
                    if let firstItem = response.mapItems.first {
                        let coordinate = firstItem.placemark.coordinate
                        completion(coordinate)
                        print("✅ Successfully geocoded: \(address)")
                    } else {
                        completion(nil)
                        print("⚠️ No results found for: \(address)")
                    }
                }
            } catch {
                print("❌ Geocoding error: \(error.localizedDescription)")
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
}

#Preview {
    NewMasjidView()
}

// MARK: - Enhanced Form Components

struct EnhancedFormTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(text.isEmpty ? .secondary : Color.mSPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(placeholder)
                        .font(.system(size: text.isEmpty ? 16 : 12, weight: text.isEmpty ? .regular : .medium))
                        .foregroundStyle(text.isEmpty ? .secondary : Color.mSPrimary)
                    
                    if isRequired {
                        Text("*")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
                
                TextField("", text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    text.isEmpty ? Color.clear : Color.mSPrimary.opacity(0.3),
                    lineWidth: 2
                )
        )
    }
}

struct EnhancedFormTextView: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 120
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !text.isEmpty || isFocused {
                Text(placeholder)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.mSPrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty && !isFocused {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                        .padding(.leading, 16)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .frame(height: height)
                    .padding(12)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isFocused || !text.isEmpty ? Color.mSPrimary.opacity(0.3) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}



struct FormTextField: View {
    var placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeholder)
                .foregroundStyle(text.isEmpty ? Color(.placeholderText) : .mSPrimary)
                .offset(y: text.isEmpty ? 0 : -30)
                .scaleEffect(text.isEmpty ? 1: 0.8, anchor: .leading)
            TextField("", text: $text)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(.systemGray5), lineWidth: 1.5)
                .padding(-4)
        )
        .padding(.top, 15)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
    }
}

#Preview("FormTextField", traits: .fixedLayout(width: 300, height: 200)) {
    FormTextField("Masjid name", text: .constant(""))
    
}

struct FormTextView: View {
    var placeholder: String
    var height: CGFloat = 200.0
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>, height: CGFloat) {
        self.placeholder = placeholder
        self._text = text
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(placeholder)
                .foregroundStyle(text.isEmpty ? Color(.placeholderText) : .mSPrimary)
                .offset(y: text.isEmpty ? 0 : -2)
                .scaleEffect(text.isEmpty ? 1: 0.8, anchor: .leading)
            
            TextEditor(text: $text)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray5), lineWidth: 1.5)
                )
                .padding(.top, 1)
            
        }
        .padding(.top, 10)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text.isEmpty)
    }
}


#Preview("FormTextView", traits: .sizeThatFitsLayout) {
    FormTextView("Description", text: .constant(""), height: 100)
}
