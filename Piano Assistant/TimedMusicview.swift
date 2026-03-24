import Foundation
import SwiftUI
import QuartzCore

struct TimedMusicView : View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var midi : BluetoothMIDI
    @EnvironmentObject private var timedHandler : TimedHandler
    
    @Binding var currentItem : Item
    @Binding var showTimedView : Bool
    @State var notes: [CGPoint] = []
    @State private var currentNoteID: Int? = 0
    @State private var scrollPos = ScrollPosition(x: 0, y: 0)
    @State private var sheetMusic : [NSImage] = []
    @State private var currentImage : NSImage = NSImage()
    @State private var pageNumber : Int = 0
    @State var loadedImages = false
    @State var noteText : Bool = false
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var startDate : Date = Date()
    @State private var displayX : Double = 0;
    @State private var now : Double = CACurrentMediaTime();
    
    var body: some View {
        VStack {
            HStack {
                Button("Back") {
                    showTimedView = false
                }
                Button("Toggle Note Display") {
                    noteText = !noteText
                }
            }
            if noteText { Text(timedHandler.currentNotes.description).font(.title) }
            GeometryReader { geo in
                
                ScrollView([.horizontal, .vertical]) {
                    ScrollViewReader { proxy in
                        ZStack {
                            
                            Image(nsImage: currentImage)
                                .resizable()
                            
                            if timedHandler.currentIntervals.count != 0 {
                                ForEach(timedHandler.currentIntervals) { interval in
                                    let colors : [String : Color] = ["bb": .red, "b": .orange, "": .yellow, "#": .blue, "x": .purple, "!": .white]
                                    
                                    IntervalHighlight(
                                        x: CGFloat(interval.start),
                                        y: CGFloat(interval.y),
                                        width: interval.end - interval.start,
                                        color: colors[interval.note!.accidental] ?? .orange
                                    )

                                }
                                
                            } else {
                                // if currentIntervals IS 0
                            }
                            
                            //printMessage(m: "\n")
                            
                            ForEach (0..<timedHandler.count) { i in
                                
                                let interval : Interval = timedHandler.speedIntervals.sorted()[i];
                                
                                IntervalHighlight(x: CGFloat(interval.start), y: CGFloat(interval.y), width: interval.end - interval.start, color: .green)
                                
                                //printMessage(m: "#\(i): Interval X, \(interval.start), Interval Y, \(interval.y)")
                            
                            }
                            
                            //printMessage(m: "\n")
                            
                            TimelineView(.animation) { context in
                                timedHandler.getCurrentMediaTime(time: &now)
                            }
                            .onChange(of: now) {
                                displayX += timedHandler.update(x: displayX, time: now)
                            }
                            
                        }
                        // Change the Y value to like a mid-line value of the measure rather than the note
                        // The coordinates it receives are the top left corner or tries to set it to top left.
                        .onChange(of: timedHandler.currentNotes) {
                            let firstNote = timedHandler.currentNotes.notes.first!
                            print(firstNote.note)
                            withAnimation(.easeInOut(duration: 0.1)) {
                                if firstNote.note == "BREAK" {
                                    pageNumber+=1
                                    currentImage = sheetMusic[pageNumber]
                                    timedHandler.onInput(bytes: [144, timedHandler.currentNotes.notes.first!.midi])
                                }
                                else if firstNote.note == "BACK" {
                                    print("Back note found!")
                                    // Only go back to and load the needed page
                                    repeat {
                                        pageNumber-=1
                                        timedHandler.onInput(bytes: [144, timedHandler.currentNotes.notes.first!.midi])
                                    } while (timedHandler.currentNotes.notes.first!.note == "BACK")
                                    
                                    currentImage = sheetMusic[pageNumber]
                                    
                                }
                                else if timedHandler.currentNotes.notes.count != 0 {
                                    
                                    scrollPos = ScrollPosition(x: CGFloat(firstNote.posX) - geo.size.width/2, y: CGFloat(firstNote.measureMidY) - geo.size.height/2)
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                .onAppear() {
                    scrollPos = ScrollPosition(x: CGFloat(timedHandler.currentNotes.notes.first!.posX) - geo.size.width/2, y: CGFloat(timedHandler.currentNotes.notes.first!.measureMidY) - geo.size.height/2)
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
                
                timedHandler.update(x: displayX, time: now)
                
            }
        }

    }
    
}
