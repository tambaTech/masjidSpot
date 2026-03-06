//
//  MasjidDetailView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/27/25.
//

import SwiftUI
import SwiftData

struct MasjidDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    var masjid: Masjid
    
    
    var body: some View {
        ScrollView(showsIndicators: false){
            
            VStack(alignment: .leading) {
                Image(uiImage: masjid.image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 445)
                    .overlay {
                        VStack {
                            Image(systemName: masjid.isVisited ? "checkmark.seal.fill" : "checkmark.seal" )
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topTrailing)
                                .padding()
                                .font(.system(size: 30))
                                .foregroundColor(masjid.isVisited ? .green : .white)
                                .padding(.top, 40)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(masjid.name)
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundStyle(.white)
                                    .shadow(radius: 100)
                                    .padding(.all, 8)
                                    
                                
                                
                                Text(masjid.location)
                                    .font(.system(.headline, design: .rounded))
                                    .padding(.all, 5)
                                    .background(Color.black)
                                
                                
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottomLeading)
                            .foregroundStyle(.white)
                            .padding()
                            
                        }
                    }
                
                ActionButtonHStack(masjid: masjid)
                
                Text(masjid.summary)
                    .minimumScaleFactor(0.75)
                    .padding()
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("ADDRESS")
                            .font(.subheadline)
                        HStack {
                            Label(masjid.location, systemImage: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text("PHONE")
                            .font(.subheadline)
                        
                        HStack {
                            Label(masjid.phone, systemImage: "phone")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                NavigationLink(destination: MapView(location: masjid.location, masjid: masjid)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .edgesIgnoringSafeArea(.all)
                ) {
                    ZStack {
                        MapView(location: masjid.location, interactionMode: [], masjid: masjid)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 200)
                            .cornerRadius(20)
                            .allowsHitTesting(false)
                        
                        // Overlay to capture taps
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                    }
                    .padding()
                    .padding(.bottom, 85)
                }
                
            }
            
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Text("\(Image(systemName: "chevron.left"))")
                    
                }
            }
        }
        .ignoresSafeArea()
        .tint(.mSPrimary)
    }
}


fileprivate struct ActionButtonHStack: View {
    var masjid: Masjid
    @State private var showMyMasjid = false
    @State private var showWebsite = false
    @State private var showingLocationAlert = false
    @State private var showingCallAlert = false
    @State private var showingMyMasjidUrlAlert = false
    
    var body: some View {
        
        HStack(spacing: 20) {
            
            Button {
                showMyMasjid = true
                
            } label: {
                VStack {
                    STActionButton(color: .pink, imageName: "clock.fill")
                    
                    Text("Salah Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
            }
            .sheet(isPresented: $showMyMasjid) {
                if masjid.myMasjidUrl != ""  {
                    WebView(url: masjid.myMasjidUrl)
                } else {
                    EmptyView()
                }
            }
            .accessibilityRemoveTraits(.isButton)
            .accessibilityLabel(Text("Go to my-masjid website"))
            
            
            Button {
                
                print(masjid.location)
                
                openMaps()
                
            } label: {
                VStack {
                    STActionButton(color: .orange, imageName: "location.fill")
                    Text("Location")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel(Text("Get directions"))
            .alert(isPresented: $showingLocationAlert) {
                Alert(title: Text("Something went wrong ❌"), message: Text("No address found"), dismissButton: .default(Text("Got it!")))
            }
            
            
            Button {
                
                openCall(phone: masjid.phone)
                
            } label: {
                VStack {
                    STActionButton(color: .green, imageName: "phone.fill")
                    Text("Call")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                }
            }
            .accessibilityLabel(Text("Call location"))
            .alert(isPresented: $showingCallAlert) {
                Alert(title: Text("Something went wrong 📵"), message: Text("No phone number found"), dismissButton: .default(Text("Got it!")))
            }
            
            
            Button {
                showWebsite = true
            } label: {
                VStack {
                    STActionButton(color: .blue, imageName: "network")
                    Text("Website")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityRemoveTraits(.isButton)
            .accessibilityLabel(Text("Go to website"))
            
        }
        .padding(EdgeInsets(top: 15, leading: 25, bottom: 15, trailing: 25))
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .padding()
        .sheet(isPresented: $showWebsite) {
            if masjid.website != ""  {
                SafariView(url: masjid.website)
            } else {
                EmptyView()
                
            }
        }
        
    }
    
    func openMaps() {
        
        guard let url = URL(string: "maps://q?address=\(masjid.location.replacingOccurrences(of: " ", with: ","))") else {
            print(masjid.location)
            showingLocationAlert = true
            return
        }
        print(masjid.location)
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
    }
    
    
    func openCall(phone: String) {
        guard let url = URL(string: "tel://\(masjid.phone.replacingOccurrences(of: " ", with: ""))") else {
            showingCallAlert = true
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
}

#Preview {
    let sampleMasjid = Masjid(
        name: "Masjid al-Haram",
        location: "Mecca, Saudi Arabia",
        phone: "+966 12 250 0000",
        description: "The largest mosque in the world and the holiest site in Islam, surrounding the Kaaba.",
        image: UIImage(named: "mosquealmasjidalharam") ?? UIImage(),
        website: "https://www.saudiembassy.net/masjid-al-haram",
        myMasjidUrl: "https://www.my-masjid.com",
        isVisited: false
    )
    
    NavigationStack {
        MasjidDetailView(masjid: sampleMasjid)
            .modelContainer(for: Masjid.self, inMemory: true)
    }
}


