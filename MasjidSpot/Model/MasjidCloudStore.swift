//
//  MasjidCloudStore.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/7/25.
//

import CloudKit
import SwiftUI


@MainActor
@Observable class MasjidCloudStore {
    var cloudMosques: [CKRecord] = []
    var isLoading = false
    var errorMessage: String?
    var iCloudAvailable = false
    
    init() {
        checkiCloudStatus()
    }
    
    private func checkiCloudStatus() {
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                self.iCloudAvailable = (status == .available)
                if !self.iCloudAvailable {
                    self.errorMessage = "iCloud is not available. Please sign in to your Apple ID in Settings."
                }
            } catch {
                self.errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchCloudMosques() async {
        isLoading = true
        errorMessage = nil
        cloudMosques.removeAll()
        
        do {
            let cloudContainer = CKContainer.default()
            let publicDatabase = cloudContainer.publicCloudDatabase
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "Masjid", predicate: predicate)
            
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let results = try await publicDatabase.records(matching: query)
            
            let processedMosques = results.matchResults.compactMap { (recordID, result) -> CKRecord? in
                do {
                    return try result.get()
                } catch {
                    print("Failed to fetch record \(recordID): \(error.localizedDescription)")
                    return nil
                }
            }
            
            self.cloudMosques = processedMosques
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            print("Failed to fetch cloud mosques: \(error)")
        }
    }
    
    func refreshData() async {
        await fetchCloudMosques()
    }
    
    func saveRecordToCloud(mosque: Masjid) async throws {
        // Prepare the record to save
        let record = CKRecord(recordType: "Masjid")
        record.setValue(mosque.name, forKey: "name")
        record.setValue(mosque.location, forKey: "location")
        record.setValue(mosque.website, forKey: "website")
        record.setValue(mosque.myMasjidUrl, forKey: "myMasjidUrl")
        record.setValue(mosque.phone, forKey: "phone")
        record.setValue(mosque.summary, forKey: "description")

        // Resize the image
        let originalImage = mosque.image
        let scalingFactor = (originalImage.size.width > 1024) ? 1024 / originalImage.size.width : 1.0
        
        guard let imageData = originalImage.pngData() else {
            throw NSError(domain: "MasjidCloudStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        guard let scaledImage = UIImage(data: imageData, scale: scalingFactor) else {
            throw NSError(domain: "MasjidCloudStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create scaled image"])
        }

        // Write the image to local file for temporary use
        let imageFilePath = NSTemporaryDirectory() + mosque.name.replacing("/", with: "-")
        let imageFileURL = URL(fileURLWithPath: imageFilePath)
        try scaledImage.jpegData(compressionQuality: 0.8)?.write(to: imageFileURL)

        // Create image asset for upload
        let imageAsset = CKAsset(fileURL: imageFileURL)
        record.setValue(imageAsset, forKey: "image")

        // Get the Public iCloud Database
        let publicDatabase = CKContainer.default().publicCloudDatabase

        // Save the record to iCloud using modern async/await API
        do {
            _ = try await publicDatabase.save(record)
            print("✅ Successfully saved mosque to CloudKit: \(mosque.name)")
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: imageFileURL)
        } catch {
            // Clean up temp file even on error
            try? FileManager.default.removeItem(at: imageFileURL)
            throw error
        }
    }
}
