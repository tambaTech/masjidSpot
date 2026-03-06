//
//  ContentView.swift
//  MasjidSpot
//
//  Created by Lamin Tamba on 9/21/25.
//

import SwiftUI
import SwiftData

struct MasjidListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasViewedWalkthrough") var hasViewedWalkthrough: Bool = false
    
    @Query var masjids: [Masjid]
    
    @State private var showNewMasjid = false
    @State private var searchText = ""
    @State private var searchResult: [Masjid] = []
    @State private var isSearchActive = false
    @State private var showWalkthrough = false
    
    var body: some View {
        NavigationStack {
            List {
                if masjids.count == 0 {
                    VStack {
                        Image("emptydata")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300)
                            .shadow(radius: 5)
                        
                        Text(searchText.isEmpty ? "No masjids found" : "No search results")
                            .font(.title3)
                            .foregroundColor(.mSPrimary)
                            .padding(.top)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(masjids, id: \.id) { masjid in
                        ZStack(alignment: .leading) {
                            NavigationLink(destination: MasjidDetailView(masjid: masjid)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            BasicTextImageRow(masjid: masjid)
                        }
                    }
                    .onDelete(perform: deleteRecord)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("MasjidSpot")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                Button(action: {
                    self.showNewMasjid = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .tint(.mSPrimary)
        .sheet(isPresented: $showNewMasjid) {
            NewMasjidView()
        }
        .sheet(isPresented: $showWalkthrough) {
            TutorialView()
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search masjids by name or location")
        .searchSuggestions {
            if searchText.isEmpty {
                Text("name")
                Text("location")
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            let predicate = #Predicate<Masjid> { $0.name.localizedStandardContains(newValue) || $0.location.localizedStandardContains(newValue) }
            
            let descriptor = FetchDescriptor<Masjid>(predicate: predicate)
            
            if let result = try? modelContext.fetch(descriptor) {
                searchResult = result
            }
        }
        .onAppear() {
            showWalkthrough = hasViewedWalkthrough ? false : true
        }
    }
    
    private func deleteRecord(indexSet: IndexSet) {
        withAnimation {
            for index in indexSet {
                let itemToDelete = masjids[index]
                modelContext.delete(itemToDelete)
            }
        }
    }
}



#Preview {
    MasjidListView()
}

#Preview("Dark mode") {
    MasjidListView()
        .preferredColorScheme(.dark)
}



struct BasicTextImageRow: View {
    // MARK: - Binding
    @Bindable var masjid: Masjid
    
    // MARK: - State variables
    @State private var showOptions = false
    @State private var showError = false
    
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            
            Image(uiImage: masjid.image)
                .resizable()
                .scaledToFill()
                .frame(width:90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            
            VStack(alignment: .leading) {
                Text(masjid.name)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.brandPrimary)
                    .lineLimit(1)
                
                
                // Show the mosque location/address
                Text(masjid.location.isEmpty ? "No address provided" : masjid.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                   
                
                // Show the masjid description/summary
                //Text(masjid.summary.isEmpty ? "No description available" : masjid.summary)
                //    .font(.caption)
                //    .lineLimit(3)
                //    .padding(.top, 2)
                //    .padding(.bottom, 4)
                //    .background(Color(.systemGray6).opacity(0.1))
                //    .clipShape(RoundedRectangle(cornerRadius: 5))
                //    .padding(.trailing, 10)
            }
            
            if masjid.isVisited {
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
            
            
        }
        
        .contextMenu{
            
            Button(action: {
                self.showError.toggle()
            }) {
                HStack {
                    Text("Reserve a Spot")
                    Image(systemName: "phone")
                }
            }
            
            
            Button(action: {
                masjid.isVisited.toggle()
            }) {
                HStack {
                    Text(masjid.isVisited ? "Unmark as Visited" : "Mark as Visited")
                    Image(systemName: "checkmark.seal.fill")
                }
            }
            
        }
        .alert("Not yet available", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Sorry, this feature is not available yet. ")
        }
        .sheet(isPresented: $showOptions) {
            let defaultText = "Check out this mosque I found on MasjidSpot!"
            
            ActivityView(activityItems: [defaultText, masjid.image])
        }
        
    }
    
}




struct FullImageRow: View {
    // MARK: - Binding
    @Bindable var masjid: Masjid
    
    // MARK: - State variables
    @State private var showOptions = false
    @State private var showError = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Image(uiImage: masjid.image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            HStack(alignment: .top) {
                
                VStack(alignment: .leading) {
                    Text(masjid.name)
                        .font(.system(.title2, design: .rounded))
                    
                    Text(masjid.phone)
                        .font(.system(.body, design: .rounded))
                    
                    Text(masjid.location)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.gray)
                    
                }
                
                if masjid.isVisited {
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
            }
            .padding(.horizontal)
            .padding(.bottom)
            
        }
        .onTapGesture {
            showOptions.toggle()
        }
        .confirmationDialog("What would you like to do?", isPresented: $showOptions, titleVisibility: .visible) {
            
            Button ("Reserve a Spot") {
                self.showError.toggle()
                
            }
            
            Button (masjid.isVisited ? "Unmark as Visited" : "Mark as Visited") {
                masjid.isVisited.toggle()
            }
            
        }
        .alert("Unable to Reserve", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Sorry, this feature is not available yet. ")
            
        }
        .sheet(isPresented: $showOptions) {
            let defaultText = "Check out this mosque I found on MasjidSpot!"
            
            ActivityView(activityItems: [defaultText, masjid.image])
        }
        
    }
    
}


#Preview("BasicTextImageRow", traits: .sizeThatFitsLayout) {
    BasicTextImageRow(masjid: Masjid(name: "Masjid al-Nabawi", location: "Al Haram, Madinah 42311, Saudi Arabia", phone: "+966 14 823 2400", description: "The Prophet's Mosque is the second mosque built by the Islamic prophet Muhammad in Medina, after the Quba Mosque, as well as the second largest mosque and holiest site in Islam, after the Masjid al-Haram in Mecca, in the Saudi region of the Hejaz.", image: UIImage(named: "mosquealmasjidalharam") ?? UIImage(), website: "https://haramain.com", myMasjidUrl: "https://time.my-masjid.com", isVisited: false))
}

#Preview("FullImageRow", traits: .sizeThatFitsLayout) {
    FullImageRow(masjid: Masjid(name: "Masjid al-Nabawi", location: "Al Haram, Madinah 42311, Saudi Arabia", phone: "+966 14 823 2400", description: "The Prophet's Mosque is the second mosque built by the Islamic prophet Muhammad in Medina, after the Quba Mosque, as well as the second largest mosque and holiest site in Islam, after the Masjid al-Haram in Mecca, in the Saudi region of the Hejaz.", image: UIImage(named: "mosquealmasjidalharam") ?? UIImage(), website: "https://haramain.com", myMasjidUrl: "https://time.my-masjid.com", isVisited: false))
}
