//
//  ContentView.swift
//  Piano Assistant
//
//  Created by Og D on 11/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var midi : BluetoothMIDI
    @EnvironmentObject private var handler : SongHandler
    private var scanner : MusicScanner
    
    @Query private var items: [Item]
    @State private var name: String
    @State private var song : [Chord] = []
    @State private var currentItem : Item = Item(n: "")
    @State private var songName : String = ""
    
    @State private var showSheetView = false
    
    // THESE ALERT STATES CAN BE TURNED INTO AN ENUM LATER :)
    @State private var typeAlert : Bool = false
    @State private var showingAlert: Bool = false
    @State private var emptyName : Bool = false
    @State private var nameOverlap : Bool = false
    @State private var specChar : Bool = false
    
    // Testing input that only converts a scanned PDF to PNGs, does not sacn them
    @State private var onlyPDF : Bool = false
    
    
    public init() {
        self.showingAlert = false
        name = ""
        scanner = MusicScanner()
    }
    
    var body: some View {
        Group {
            if showSheetView {
                SheetMusicView(currentItem: $currentItem, showSheetView: $showSheetView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NavigationSplitView {
                    List {
                        ForEach(items, id: \.id) { item in
                            NavigationLink {
                                VStack {
                                    HStack {
                                        
                                        Button("Scan Song") {
                                            typeAlert = true
                                        }
                                        .alert("Please enter the name of song", isPresented: $typeAlert) {
                                            TextField("Song name", text: $songName)
                                            Button("OK") {
                                                
                                                for i in items {
                                                    if i.title == songName {
                                                        nameOverlap = true
                                                        typeAlert = false
                                                    }
                                                }
                                                
                                                if songName == "" {
                                                    emptyName = true
                                                    typeAlert = false
                                                }
                                                else if !scanner.isAlphanumeric(string: songName) {
                                                    specChar = true
                                                    typeAlert = false
                                                }
                                                else if !nameOverlap {
                                                    
                                                    let test = Item(n: songName)
                                                    
                                                    Task {
                                                        let temp : Bool = onlyPDF
                                                        await scanner.scan(item: test, onlyPDF: temp)
                                                    }
                                                    
                                                    withAnimation {
                                                        modelContext.insert(test)
                                                    }
                                                    typeAlert = false
                                                    songName = ""
                                                }
                                            }
                                            
                                            Button("Cancel") {
                                                typeAlert = false
                                            }
                                        } message: { Text("Please enter a name for the song") }
                                        
                                        .alert("Please try again and enter a name", isPresented: $emptyName) {
                                            Button("OK") {
                                                emptyName = false
                                                typeAlert = true
                                            }
                                        }
                                        
                                        .alert("You already have a song named that. Please try again.", isPresented: $nameOverlap) {
                                            Button("OK") {
                                                emptyName = false
                                                typeAlert = true
                                            }
                                        }
                                        
                                        .alert("Please only use alphanumeric characters in the name!", isPresented: $specChar) {
                                            Button("OK") {
                                                specChar = false
                                                typeAlert = true
                                            }
                                        }
                                        
//                                        Button("Run Audiveris") {
//                                            scanner.runAudiveris()
//                                            let newItem = Item(n: "Audiveris Output")
//                                            newItem.songArray = scanner.parseXML()
//                                            withAnimation {
//                                                modelContext.insert(newItem)
//                                            }
//                                        }
                                        Button("Select TestXml") {
                                            _ = scanner.testXMLFiles(item: item)
                                        }
                                        Button("Get PDFs Only") {
                                            if (onlyPDF == false) { onlyPDF = true }
                                            else { onlyPDF = false }
                                        }
                                        Button("Select Song") {
                                            item.songArray.sort()
                                            handler.newSong(new: item.songArray)
                                            print(item.filePath)
                                        }
                                        
                                        Button("Play Song") {
                                            item.songArray.sort()
                                            handler.newSong(new: item.songArray)
                                            currentItem = item
                                            showSheetView = true
                                        }
                                        
                                        Button("Delete Item") {
                                            withAnimation {
                                                item.deleteFiles()
                                                modelContext.delete(item)
                                            }
                                        }
                                        Button("Force Delete Item") {
                                            withAnimation {
                                                modelContext.delete(item)
                                            }
                                        }
                                    }
                                    
                                    List {
                                        ForEach(item.songArray.indices, id:\.self) { i in
                                            Text(item.songArray[i].notes.map(\.description).joined(separator: ", "))
                                        }
                                    }
                                    
                                    Text("Item at \(item.title ?? "No Name")")
                                }
                                
                            } label: {
                                if let n = item.title { Text(n) }
                            }
                            
                            
                        }
                        
                    }
#if os(macOS)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
                    .toolbar {
#if os(iOS)
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
#endif
                        
                        ToolbarItem {
                            Button(action: addItem) {
                                Label("Add Item", systemImage: "plus")
                            }
                        }
//
//                        ToolbarItem {
//                            let iset = IndexSet([0,1])
//                            Button(action: {deleteItems(offsets: iset)}) {
//                                Image(systemName: "minus")
//                                    .foregroundColor(.red)
//                            }
//                            
//                        }
                        
                    }
                }
                detail: {
                    Text("Select an item")
                }
            }
        }

    }


    private func addItem() {
        let newItem = Item(n: "testing")
        newItem.songArray = song
        withAnimation {
            modelContext.insert(newItem)
        }
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}


