//
//  CKRecord+Mosque.swift
//  MosquePin
//
//  Created by Assistant
//

import CloudKit
import UIKit

/// Type-safe extension for accessing Mosque record fields
extension CKRecord {
    
    // MARK: - Field Keys
    
    enum MosqueField {
        static let name = "name"
        static let location = "location"
        static let description = "description"
        static let phone = "phone"
        static let website = "website"
        static let myMasjidUrl = "myMasjidUrl"
        static let image = "image"
    }
    
    // MARK: - Typed Accessors
    
    var mosqueName: String? {
        get { self[MosqueField.name] as? String }
        set { self[MosqueField.name] = newValue as? CKRecordValue }
    }
    
    var mosqueLocation: String? {
        get { self[MosqueField.location] as? String }
        set { self[MosqueField.location] = newValue as? CKRecordValue }
    }
    
    var mosqueDescription: String? {
        get { self[MosqueField.description] as? String }
        set { self[MosqueField.description] = newValue as? CKRecordValue }
    }
    
    var mosquePhone: String? {
        get { self[MosqueField.phone] as? String }
        set { self[MosqueField.phone] = newValue as? CKRecordValue }
    }
    
    var mosqueWebsite: String? {
        get { self[MosqueField.website] as? String }
        set { self[MosqueField.website] = newValue as? CKRecordValue }
    }
    
    var mosqueMyMasjidUrl: String? {
        get { self[MosqueField.myMasjidUrl] as? String }
        set { self[MosqueField.myMasjidUrl] = newValue as? CKRecordValue }
    }
    
    var mosqueImage: CKAsset? {
        get { self[MosqueField.image] as? CKAsset }
        set { self[MosqueField.image] = newValue }
    }
    
    // MARK: - Convenience Methods
    
    /// Load the mosque image from the CKAsset
    func loadMosqueImage() -> UIImage? {
        guard let imageAsset = mosqueImage,
              let imageURL = imageAsset.fileURL,
              let imageData = try? Data(contentsOf: imageURL) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    /// Check if the mosque record has all required fields
    var isValidMosqueRecord: Bool {
        return mosqueName != nil && mosqueLocation != nil
    }
}
