//
//  CoverImageView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 10/9/25.
//

import SwiftUI
import CloudKit

struct CoverImageView: View {
    @State private var cloudStore = MasjidCloudStore()
    @State private var showLoadingIndicator = false
    
    var body: some View {
        
        // MARK: - TabView with Paging
        VStack {
            
            if let latestMasjids = sortedLatestMasjids(limit: 5), !latestMasjids.isEmpty {
                TabView {
                    // 🔹 Page 1: Horizontal Image Scroll (HStack)
                    ForEach(latestMasjids, id: \.recordID) { masjid in
                        
                        AsyncImage(url: getImageURL(masjid: masjid)){ image in
                            image
                                .resizable()
                                .background(.black.opacity(0.7))
                                .overlay {
                                    Text(masjid.object(forKey: "name") as! String)
                                        .font(.title)
                                        .foregroundStyle(.white)
                                        .bold()
                                        .shadow(radius: 30)
                                    
                                }
                            
                        } placeholder: {
                            ProgressView()
                            
                            
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottomLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                        
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                
            }
            
        }
        .task {
            if cloudStore.cloudMosques.isEmpty {
                await cloudStore.fetchCloudMosques()
            }
        }
        .onAppear {
            showLoadingIndicator = false
        }
        .refreshable {
            await cloudStore.refreshData()
        }
        if showLoadingIndicator {
            ProgressView()
            
            
        }
        
    }
    
    // MARK: - Helper for Image URL
    private func getImageURL(masjid: CKRecord) -> URL? {
        guard let image = masjid.object(forKey: "image"),
              let imageAsset = image as? CKAsset else {
            return nil
        }
        
        return imageAsset.fileURL
    }
    private func sortedLatestMasjids(limit: Int) -> [CKRecord]? {
        let sorted = cloudStore.cloudMosques.sorted(by: isLatestFirst)
        return Array(sorted.prefix(limit))
    }
    
    private func isLatestFirst(_ lhs: CKRecord, _ rhs: CKRecord) -> Bool {
        (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
    }
    
    private func formattedDate(masjid: CKRecord) -> String {
        guard let date = masjid.creationDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
}



#Preview {
    CoverImageView()
}
