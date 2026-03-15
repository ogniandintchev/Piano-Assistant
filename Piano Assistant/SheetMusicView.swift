import Foundation
import SwiftUI

struct SheetMusicView : View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var midi : BluetoothMIDI
    @EnvironmentObject private var handler : SongHandler
    
    @Binding var currentItem : Item
    @Binding var showSheetView : Bool
    @State var notes: [CGPoint] = []
    @State private var currentNoteID: Int? = 0
    @State private var scrollPos = ScrollPosition(x: 0, y: 0)
    // var score : NSImage { return NSImage(contentsOf: URL(string: currentItem.filePath![0])!)! }
    @State private var sheetMusic : [NSImage] = []
    @State private var currentImage : NSImage = NSImage()
    @State private var pageNumber : Int = 0
    @State var loadedImages = false
    @State var noteText : Bool = false
    
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    
    
    var body: some View {
        VStack {
            HStack {
                Button("Remove First") {
//                    print(handler.current().notes.first!.posX, handler.current().notes.first!.posY)
                    handler.onInput(bytes: [144, handler.current().notes.first!.midi])
                    
                }
                Button("Back") {
                    showSheetView = false
                }
                Button("Toggle Note Display") {
                    noteText = !noteText
                }
            }
            if noteText { Text(handler.current().description).font(.title) }
            GeometryReader { geo in
                
                ScrollView([.horizontal, .vertical]) {
                    ScrollViewReader { proxy in
                        ZStack {
                            
                            Image(nsImage: currentImage)
                                .resizable()
//                                .scaleEffect(zoomScale)
//                                .gesture(
//                                    MagnificationGesture()
//                                        .onChanged { value in
//                                            zoomScale = lastZoomScale * value
//                                        }
//                                        .onEnded { _ in
//                                            lastZoomScale = zoomScale
//                                        }
//                                )
//                                .frame(
//                                    width: currentImage.size.width * zoomScale,
//                                    height: currentImage.size.height * zoomScale
//                                )
                            
                            if handler.current().notes.count != 0 {
                                ForEach(handler.current().notes) { note in
                                    let colors : [String : Color] = ["bb": .red, "b": .orange, "": .yellow, "#": .blue, "x": .purple, "!": .white]
                                    NoteHighlight(x: CGFloat(note.posX), y: CGFloat(note.posY), color: colors[note.accidental]!)
                                    
                                    
                                    IntervalHighlight(x: CGFloat(note.interval.start), y: CGFloat(note.interval.y), width: note.interval.end - note.interval.start, color: .red)

                                    
                                }
                                
                            }
                            
                        }
                        // Change the Y value to like a mid-line value of the measure rather than the note
                        // The coordinates it receives are the top left corner or tries to set it to top left.
                        .onChange(of: handler.current()) {
                            let firstNote = handler.current().notes.first!
                            print(firstNote.note)
                            withAnimation(.easeInOut(duration: 0.1)) {
                                if firstNote.note == "BREAK" {
                                    pageNumber+=1
                                    currentImage = sheetMusic[pageNumber]
                                    handler.onInput(bytes: [144, handler.current().notes.first!.midi])
                                }
                                else if firstNote.note == "BACK" {
                                    print("Back note found!")
                                    // Only go back to and load the needed page
                                    repeat {
                                        pageNumber-=1
                                        handler.onInput(bytes: [144, handler.current().notes.first!.midi])
                                    } while (handler.current().notes.first!.note == "BACK")
                                    
                                    currentImage = sheetMusic[pageNumber]
                                    
                                }
                                else if handler.current().notes.count != 0 {
                                    
                                    scrollPos = ScrollPosition(x: CGFloat(firstNote.posX) - geo.size.width/2, y: CGFloat(firstNote.measureMidY) - geo.size.height/2)
                                }
                            }
                        }
                        
                    }
                    
                }
                .onAppear() {
                    scrollPos = ScrollPosition(x: CGFloat(handler.current().notes.first!.posX) - geo.size.width/2, y: CGFloat(handler.current().notes.first!.measureMidY) - geo.size.height/2)
                    zoomScale = geo.size.width / currentImage.size.width
                    
                }
                .scrollPosition($scrollPos)
                
            }
            .padding()

        }
        
        .onAppear() {
            if !loadedImages {
                for item in currentItem.filePath {
                    sheetMusic.append(NSImage(contentsOfFile: item.path)!)
                }
                currentImage = sheetMusic[0]
                
                loadedImages = true
                
                
            }
        }

    }
    
}
