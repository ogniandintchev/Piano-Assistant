import SwiftUI
import Combine

class NoteQueue : ObservableObject {
    
    /// Create a queue of Array<Int> to represent how notes should be played in order.
    /// Int is used because MIDI returns an array of integers, where the note is denoted by a number
    /// Array<Int> is used because at the same time multiple notes might need to be played so multiple notes can act as 1 item in the queue.
    
    var chords : [Chord] = []
    var pointer : Int = 0
    @Published var current : Chord = Chord(notes: [], order: 0)
    
    init() {}
    
    init(queue: [Chord]) {
        // If an Array<Array<Int>> already exists and needs to be turned into a queue
        chords = queue
        current = chords[0].copy()
    }
    
    func peak() -> Chord {
        /// Return the first item in the queue which is an Array<Int>
        return current
    }
    
    func reachedEnd() -> Bool { pointer == chords.count - 1 }
    
    func remove(a: Int) -> Int {
        
        if pointer >= chords.count-1 { return 0 }
        
        if let index = current.notes.firstIndex(where: { $0.midi == a }) {
            current.notes.remove(at: index)
        }
        
        if current.notes.isEmpty {
            pointer+=1
            current = self.chords[self.pointer].copy()
            
        }
        
        return 1
    }
    
    func add(input: Chord) {
        chords.append(input);

    }
    
    func add(input: [Chord]) {
        self.chords = input//.sorted() { $0.order < $1.order};
        pointer = 0;
        self.current = self.chords[0].copy()
    }
    
    
    
}
