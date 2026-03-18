import SwiftUI
import Combine


class TimedQueue {
    
    var intervals : [NoteIntervals];
    var cursor : Int = 0
    
    
    init() {
        self.intervals = []
    }
    
    init(intervals: [NoteIntervals]) {
        self.intervals = []
        for ni in intervals {
            self.intervals.append(ni.copy())
        }
    
    }
    
    func popAndWalk() -> NoteIntervals? {
        if cursor > self.intervals.count-1 { return nil }
        cursor+=1
        return intervals[cursor-1];
    }
    
    func currentX() -> Double { return intervals[cursor].intervals[0].start }
    
    func endOfSong() -> Bool { return cursor == intervals.count }
    
    
    
}
