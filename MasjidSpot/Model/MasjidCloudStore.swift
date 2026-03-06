//
//  MasjidCloudStore.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/7/25.
//

import CloudKit
import SwiftUI


@Observable class MasjidCloudStore {
    var cloudMosques: [CKRecord] = []
    var isLoading = false
    var errorMessage: String?
    
    func fetchCloudMosques() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            cloudMosques.removeAll() // Clear existing data to prevent duplicates
        }
        
        do {
            // Fetch data using Convenience API with proper sorting
            let cloudContainer = CKContainer.default()
            let publicDatabase = cloudContainer.publicCloudDatabase
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "Masjid", predicate: predicate)
            
            // Sort by creation date (newest first) to show recent data
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let results = try await publicDatabase.records(matching: query)
            
            // Process results directly without intermediate variable
            let processedMosques = try results.matchResults.map { result in
                try result.1.get()
            }
            
            await MainActor.run {
                self.cloudMosques = processedMosques
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("Failed to fetch cloud mosques: \(error)")
        }
    }
    
    func refreshData() async {
        await fetchCloudMosques()
    }
    
    func saveRecordToCloud(mosque: Masjid) {

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
                return
            }
            
            let scaledImage = UIImage(data: imageData, scale: scalingFactor)!

            // Write the image to local file for temporary use
            let imageFilePath = NSTemporaryDirectory() + mosque.name
            let imageFileURL = URL(fileURLWithPath: imageFilePath)
            try? scaledImage.jpegData(compressionQuality: 0.8)?.write(to: imageFileURL)

            // Create image asset for upload
            let imageAsset = CKAsset(fileURL: imageFileURL)
            record.setValue(imageAsset, forKey: "image")

            // Get the Public iCloud Database
            let publicDatabase = CKContainer.default().publicCloudDatabase

            // Save the record to iCloud
            publicDatabase.save(record, completionHandler: { (record, error) -> Void  in

                if error != nil {
                    print(error.debugDescription)
                }

                // Remove temp file
                try? FileManager.default.removeItem(at: imageFileURL)
            })
        }
}
