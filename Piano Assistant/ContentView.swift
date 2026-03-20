import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var midi : BluetoothMIDI
    @EnvironmentObject private var handler : SongHandler
    @EnvironmentObject private var timedHandler : TimedHandler
    
    private var scanner : MusicScanner
    
    @Query private var items: [Item]
    @State private var name: String
    @State private var song : [Chord] = []
    @State private var currentItem : Item = Item(n: "")
    @State private var songName : String = ""
    
    @State private var showSheetView = false
    @State private var showTimedView = false
    
    @State private var typeAlert : Bool = false
    
    // Store array of booleans to indicate errors. isPresented checks do not allow computing a boolean
    // 0 = No Error, 1 = Empty Name, 2 = Name Overlap, 3 = Special Character
    @State private var scanErr : [Bool] = [false, false, false, false]
    
    // Testing input that only converts a scanned PDF to PNGs, does not sacn them
    @State private var onlyPNG : Bool = false
    
    
    public init() {
        
        name = ""
        scanner = MusicScanner()
    }
    
    var body: some View {
        Group {
            if showSheetView {
                SheetMusicView(currentItem: $currentItem, showSheetView: $showSheetView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else if showTimedView {
                TimedMusicView(currentItem: $currentItem, showTimedView: $showTimedView)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                NavigationSplitView {
                    List {
                        Button("Scan Song") {
                            typeAlert = true
                        }
                        .alert("Please enter the name of song", isPresented: $typeAlert) {
                            TextField("Song name", text: $songName)
                            
                            Button("Custom Import") {
                                let err : Int = scanner.checkScanErrors(items: items, songName: songName)
                                scanErr[err] = true
                                
                                if scanErr[0] {
                                    let new = Item(n: songName)
                                    
                                    Task {
                                        let temp : Bool = onlyPNG
                                        await scanner.scan(item: new, onlyPNG: temp, customImport: true)
                                    }
                                    
                                    withAnimation {
                                        modelContext.insert(new)
                                    }
                                    typeAlert = false
                                    songName = ""
                                    scanErr[0] = false
                                } else {
                                    typeAlert = false
                                }
                                
                                
                            }
                            Button("OK") {
                                let err : Int = scanner.checkScanErrors(items: items, songName: songName)
                                scanErr[err] = true
                                
                                if scanErr[0] {
                                    let new = Item(n: songName)
                                    
                                    Task {
                                        let temp : Bool = onlyPNG
                                        await scanner.scan(item: new, onlyPNG: temp)
                                    }
                                    
                                    withAnimation {
                                        modelContext.insert(new)
                                    }
                                    typeAlert = false
                                    songName = ""
                                    scanErr[0] = false
                                } else {
                                    typeAlert = false
                                }
                                
                            }
                            
                            Button("Cancel") {
                                typeAlert = false
                            }
                        } message: { Text("Please enter a name for the song") }
                        
                            .alert("Please try again and enter a name", isPresented: (
                                $scanErr[1])
                            ) {
                            Button("OK") {
                                typeAlert = true
                                scanErr[1] = false
                            }
                        }
                        
                            .alert("You already have a song named that. Please try again.", isPresented: $scanErr[2]) {
                            Button("OK") {
                                typeAlert = true
                                scanErr[2] = false
                            }
                        }
                        
                            .alert("Please only use alphanumeric characters in the name!", isPresented: $scanErr[3]) {
                            Button("OK") {
                                typeAlert = true
                                scanErr[3] = false
                            }
                        }
                        
                        // When scanning sheet music, will only convert PDF to PNGs and will not scan.
                        Button("Get PNGs Only") {
                            if (onlyPNG == false) { onlyPNG = true }
                            else { onlyPNG = false }
                        }
                        
                        ForEach(items, id: \.id) { item in
                            NavigationLink {
                                VStack {
                                    HStack {
                                        

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
                                        
                                        Button("Play Timed Song") {
                                            item.songArray.sort()
                                            timedHandler.newSong(item: item)
                                            currentItem = item
                                            showTimedView = true
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


