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
    
    func updateCurrent(displayX: Double) -> [Interval] {
        var new : [Interval] = []
        
        for interval in self.intervals[cursor].intervals {
            if displayX < interval.end {
                new.append(interval)
            }
        }
        
        return new
    }
    
    func currentX() -> Double { print(intervals.count); return intervals[cursor].intervals[0].start }
    
    func nextX() -> Double {
        if cursor < intervals.count-1 {
            print(intervals[cursor+1].intervals.count);
            return intervals[cursor+1].intervals[0].start
        } else {
            return -1
        }
        
    }
    
    func endOfSong() -> Bool { return cursor == intervals.count }
    
    func fullSongIntervals() -> [NoteIntervals] { return self.intervals }
    
    
}
