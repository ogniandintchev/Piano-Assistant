import SwiftUI
import SwiftData

@main
struct Piano_AssistantApp: App {
    
    var testQueue : [Chord] = []
    let testNotes = [[21,22,23],[24,25,26],[27]]

    
    
    let test : NoteQueue
    private var handler : SongHandler
    @ObservedObject private var midi : BluetoothMIDI
    
    
    
    init() {
        var i = 0
        for noteArr in testNotes {
            var chord : [Note] = []
            for value in noteArr {
                chord.append(Note(id:value, midi: value, note:"", accidental:"", octave:-100, posX:0, posY:0, measureMidY: CGFloat(100), duration: 1, interval: Interval()))
            }
            testQueue.append(Chord(notes: chord, order: i))
            i+=1
        }
        test = NoteQueue(queue: testQueue)
        handler = SongHandler(queue: test)
        midi = BluetoothMIDI(handler)

    }
    
    
    
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        
        // isStoredInMemoryOnly false for persistent data
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(midi)
                .environmentObject(handler)
        }
        .modelContainer(sharedModelContainer)
    }
}
