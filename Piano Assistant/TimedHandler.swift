import SwiftUI
import Combine
import QuartzCore

// Current implementation edits a complete copy of the saved songIntervals
// Currently edits the duration played and wrong intervals and their duration played as notes are played

// In the view, use a TimeView, and call update on a consistent clock. Pass in displayX at that moment and compute

class TimedHandler : ObservableObject {
    var queueObject : TimedQueue
    var startTime : Double = CACurrentMediaTime()
    var current : [Interval] = [];
    var currentPressed : [Int: Double] = [:] // MIDI : Start time
    var songIntervals : [NoteIntervals] = []
    
    
    init(queue: [NoteIntervals]){
        queueObject = TimedQueue(intervals: queue)
    }
    
    func newStart() { startTime = CACurrentMediaTime() }
    
    func setSongIntervals(songIntervals: inout [NoteIntervals]) { self.songIntervals = songIntervals }
    
    func playSong(displayX: Double) {
        
        if displayX >= queueObject.currentX() {
            current = current + queueObject.popAndWalk()!.intervals
        }
        
        current.removeAll {$0.end < displayX }
        
    }
    
    // This is super unoptimized with terible O(), but this can be updated later to also provide data to display
    // Like exact positions of wrong intervals, overlays of correct intervals, etc. to make it justified
    func update() {
        
        let finalIntervals = queueObject.fullSongIntervals()
        var totalSongTime : Double = 0;
        var totalWrongTime : Double = 0;
        var totalCorrectTime : Double = 0;
        
        
        for noteInterval in finalIntervals {
            for interval in noteInterval.intervals {
                totalSongTime += interval.time
                totalCorrectTime += interval.durationPlayed
            }
            
            for wrong in noteInterval.wrongIntervals {
                totalWrongTime += wrong.durationPlayed
            }
            
        }
        
        let finalScore = (totalCorrectTime - totalWrongTime) / totalSongTime
        
        print("Final score is : \(finalScore)")
        
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
