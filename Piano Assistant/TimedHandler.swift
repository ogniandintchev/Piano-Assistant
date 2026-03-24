import SwiftUI
import Combine
import QuartzCore

// Current implementation edits a complete copy of the saved songIntervals
// Currently edits the duration played and wrong intervals and their duration played as notes are played

// In the view, use a TimeView, and call update on a consistent clock. Pass in displayX at that moment and compute

// Check duration handling of Tuplets

// Some spaces are missing a timing interval, they are either WAYYY shorter or do not exist at all
// This might tie into the logic for when an interval needs to be replaced? Might have to go back in the loop to
// make sure it itterates over everything or something idk fiddle around with that stuff

// Item has 4 arrays
// songArray - [Chord], houses all the chords to be played in order
// songIntervals - [NoteIntervals], size of 128, each index for each midi input, used to do correct/incorrect
// orderedIntervals - [NoteIntervals], basically songArray casted to [NoteIntervals], used for displaying current
// speedIntervals - [Interval], array of speeds for the cursor to move over on the page


// noteQ - songArray, same as other handler, a queue of all the notes to play in order
// timedQ - orderedIntervals, array of Intervals to be played in order
//

// SWIFT REORDERS ARRAYS THAT ARE FROM PERSISTENT DATA!
// Copying things from persistent data is not only necessary to prevent editing the original data, but also makes
// sure that whatever swift memory shanigans is going on isn't propogated into runtime logic

// Current implementation will break for slurs that go over multiple lines, fix this at some point

class TimedHandler : ObservableObject, Observable {
    var timedQ : TimedQueue
    var startTime : Double = CACurrentMediaTime()
    var lastFrame : Double = CACurrentMediaTime()
    
    
    var currentIntervals : [Interval] = [];
    var currentNotes : Chord = Chord(notes: [], order: 0);
    var currentPressed : [Int: Double] = [:] // MIDI : Start time
    var songIntervals : [NoteIntervals] = []
    var speedIntervals : [Interval] = []
    var speedCursor : Int = 0;
    var noteQ : NoteQueue;
    var count : Int = 0;
    
    
    init(queue: [NoteIntervals], songNotes : [Chord]){
        timedQ = TimedQueue(intervals: queue)
        noteQ = NoteQueue(queue: songNotes)
        
    }
    
    func newStart() { startTime = CACurrentMediaTime() }
    
    
    func setSongIntervals(songIntervals: inout [NoteIntervals]) { self.songIntervals = songIntervals }
    
    func newSong(item: Item) {
        self.songIntervals = item.songIntervals
        self.noteQ = NoteQueue(queue: item.songArray)
        self.timedQ = TimedQueue(intervals: item.orderedIntervals)
        
        self.currentIntervals = timedQ.popAndWalk()!.intervals
        
        self.currentNotes = noteQ.current
    
        for interval in item.speedIntervals {
            self.speedIntervals.append(interval.copy())
        }
        self.count = self.speedIntervals.count-1
        
    }
    
    func update(x: Double, time: Double) -> Double {
        // THIS FUNCTION WILL RETURN THE CHANGE IN X NEEDED FOR THE CURSOR SINCE THE LAST FRAME
        // ADD A VARIABLE TO TRACK WHEN THE LAST FRAME WAS
        
        
        // If the current display X has completely passed an interval, remove it
        currentIntervals.removeAll {$0.end < x }
        
        // If the current display X is over a current interval, it must stay in current
        
        // If the display X has crossed into a new interval, add it to current
        if x > timedQ.nextX() {
            let next = timedQ.popAndWalk()
            if next != nil { currentIntervals += next!.intervals }
            else {
                // End of song or something went majorly wrong
            }
        }
        
        // Calculate change in X based on current speedInterval,
        
        
        
        currentNotes = noteQ.current
        
        return 5;
        
    }
    
    // This is super unoptimized with terible O(), but this can be updated later to also provide data to display
    // Like exact positions of wrong intervals, overlays of correct intervals, etc. to make it justified
    func finishSong() {
        
        let finalIntervals = timedQ.fullSongIntervals()
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
            _ = noteQ.remove(a: bytes[1])
        }
        
        if (noteType == NoteType.OFF) {
            
            guard let currentDur = currentPressed[bytes[1]] else { return }
            
            let durationPlayed = currentDur - CACurrentMediaTime() // Start press - end press
            
            var interval : Interval? = nil
            for i in currentIntervals {
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
    
    func getCurrentMediaTime(time: inout Double) -> EmptyView {
        let temp = CACurrentMediaTime()
        time = temp
        lastFrame = temp
        return EmptyView()
    }
    
    
    
    
    
}

struct printMessage : View {
    
    var body : some View {
        
    }
    
    
    init(m: String) {
        print(m)
    }
    
}
