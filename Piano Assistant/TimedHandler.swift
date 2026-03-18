import SwiftUI
import Combine
import QuartzCore

// Current implementation edits a complete copy of the saved songIntervals
// Currently edits the duration played and wrong intervals and their duration played as notes are played
// At the end of playSong(), iterate through all intervals, correct and incorrect, to get totals of the two
// I dont think playSong() is going to work as expected, gonna have to be asynchronus
// displayX NEEDS to be set via setDisplayPointer() so displayX updates in accordance to the UI

class TimedHandler : ObservableObject {
    var queueObject : TimedQueue
    var startTime : Double = CACurrentMediaTime()
    var current : [Interval] = [];
    var displayX : Double = 0;
    var currentPressed : [Int: Double] = [:] // MIDI : Start time
    var songIntervals : [NoteIntervals] = []
    
    
    init(queue: [NoteIntervals]){
        queueObject = TimedQueue(intervals: queue)
    }
    
    func setDisplayPointer(displayX : inout Double ) { self.displayX = displayX }
    
    func newStart() { startTime = CACurrentMediaTime() }
    
    func setSongIntervals(songIntervals: inout [NoteIntervals]) { self.songIntervals = songIntervals }
    
    func playSong() {
        
        while !queueObject.endOfSong() {
            if displayX >= queueObject.currentX() {
                current = current + queueObject.popAndWalk()!.intervals
            }
            
            for i in 0..<current.count {
                if current[i].end < displayX {
                    current.remove(at: i)
                }
                
            }
            
        }
        
        
        
        
    }
    
    func onInput(bytes: [Int]) {
        // Currently only on/off inputs are being passed in
        
        enum NoteType : Encodable {
            case ON
            case OFF
            case CONTROL
            case STATUS
            case OTHER
        }
        
        var noteType : NoteType
        switch bytes[0] {
        case 128...143: noteType = .OFF
        case 144...153: noteType = .ON
        default: noteType = .OTHER
        }
        
        
        if (noteType == NoteType.ON) { // If the input is a key being pressed
            currentPressed[bytes[1]] = CACurrentMediaTime()
        }
        
        if (noteType == NoteType.OFF) {
            
            guard let currentDur = currentPressed[bytes[1]] else { return }
            
            let durationPlayed = currentDur - CACurrentMediaTime() // Start press - end press
            
            var interval : Interval? = nil
            for i in current {
                if i.midi == bytes[1] {
                    interval = i
                }
            }
            
            if interval == nil {
                songIntervals[bytes[1]].wrongIntervals.append(Interval(durationPlayed: durationPlayed))
                return;
            }
            
            else {
                let timeDif = interval!.time - durationPlayed
                
                if timeDif < 0 {
                    interval!.durationPlayed = interval!.time
                    songIntervals[bytes[1]].wrongIntervals.append(Interval(durationPlayed: -timeDif))
                    songIntervals[bytes[1]].cursor+=1
                }
                else if timeDif >= 0 {
                    interval!.durationPlayed = durationPlayed
                    songIntervals[bytes[1]].cursor+=1
                }
                
                
            }
            
            
        }
        
    }
    
}
