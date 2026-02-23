//
//  Queue.swift
//  Piano Assistant
//
//  Created by Og D on 11/15/25.
//

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
    
    // TODO: CHANGE THIS FUNCTION SINCE IM NOT REMOVING ELEMENTS
    func reachedEnd() -> Bool { pointer == chords.count - 1 }
    
    // Removing works, but walking through the array with pointers is better
//    func remove(a: Int) -> Int {
//        /// Return 1 if the item is removed. If the queue is empty, return 0. If the item is not found return -1
//        
//        if q.first == nil { return 0 } // empty queue
//        
//        // If a is in the array then remove it from the first item
//        if let index = q[0].notes.firstIndex(where: { $0.midi == a }) {
//            q[0].notes.remove(at: index)
//        }
//        
//        // If top array is empty then remove it
//        if q[0].notes.isEmpty { q.remove(at: 0) }
//        
//        // Prevents crash on updating current if q is empty
//        if (q.isEmpty) {
//            current = Chord(notes: [], order:0)
//        } else { current = q[0]}
//        
//        return 1
//    }
    
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
