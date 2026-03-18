import Foundation
import SwiftData
import SwiftUI
import Combine

@Model
final class Item {
    
    
    var songArray: [Chord]
    var songIntervals : [NoteIntervals]
    var orderedIntervals : [NoteIntervals] = []
    
    var title: String?
    
    var filePath : [URL] // TODO: USE THIS LATER WHEN ASSIGNING IMAGES TO SONGS IN LIST
    
    
    init(n: String) {
        title = n
        filePath = []
        self.songArray = []
        self.songIntervals = (0...127).map { index in
            return NoteIntervals();
        }
    }
    
    
    public func deleteFiles() {
        let fileManager = FileManager.default
        let folderPath = filePath.first!.deletingLastPathComponent().standardizedFileURL.resolvingSymlinksInPath()
        var songDir : URL
        do {
            songDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            songDir = songDir.appendingPathComponent("Piano-Assistant/Songs").standardizedFileURL.resolvingSymlinksInPath()
        } catch {
            print("Error occured finding documents dir.")
            return
        }
        
        if folderPath == songDir {
            print("Tried to delete the Songs folder!")
            return
        }
        
        if !folderPath.path.hasPrefix(songDir.path + "/") {
            print("Tried to delete files outside of App's songs folder!")
            return
        }
        
        if fileManager.fileExists(atPath: folderPath.path) {
            do {
                try fileManager.removeItem(at: folderPath)
            } catch { print("Error in deleting Item's files") }
        }
    }
}


@Model
final class Note : CustomStringConvertible, Identifiable, Equatable {
    
    var id : Int
    var midi : Int
    var note : String
    var accidental : String
    var octave : Int
    var posX : Double
    var posY : Double
    var description: String {
        "\(note)\(accidental)\(octave)"
    }
    var measureMidY : Double
    var duration : Double
    var interval : Interval;
    
    init(id: Int, midi: Int, note: String, accidental: String, octave: Int, posX: Double, posY: Double, measureMidY: Double, duration : Double, interval: Interval) {
        self.id = id
        self.midi = midi
        self.note = note
        self.accidental = accidental
        self.octave = octave
        self.posX = posX
        self.posY = posY
        self.measureMidY = measureMidY
        self.duration = duration
        self.interval = interval
    }
    
    public func copy() -> Note {
        return Note(id: id, midi: midi, note: note, accidental: accidental, octave: octave, posX: posX, posY: posY, measureMidY: measureMidY, duration: duration, interval: interval)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id &&
        lhs.midi == rhs.midi &&
        lhs.note == rhs.note &&
        lhs.accidental == rhs.accidental &&
        lhs.octave == rhs.octave &&
        lhs.posX == rhs.posX &&
        lhs.posY == rhs.posY &&
        lhs.measureMidY == rhs.measureMidY
    }
    
}



@Model
final class Chord : CustomStringConvertible, Comparable, CustomDebugStringConvertible {
    var notes: [Note]
    var order: Int = 0
    var description: String {
        var desc : String = ""
        for note in self.notes {
            desc.append("\(note.description) ")
        }
        //desc.append("\(order)")
        return desc
    }
    
    var debugDescription: String {
        return description
    }
    
    init(notes: [Note], order: Int) {
        self.notes = notes
        self.order = order
    }
    
    public func copy() -> Chord {
        var newNotes : [Note] = []
        for note in self.notes {
            newNotes.append(note.copy())
        }
        return Chord(notes: newNotes, order: self.order)
    }
    
    static func < (lhs: Chord, rhs: Chord) -> Bool {
        return lhs.order < rhs.order
    }

}

@Model
final class Interval {
    var start : Double = 0;
    var end : Double = 0;
    var durationPlayed : Double = 0;
    var y : Double = 0;
    var time : Double = 0;
    var timeInSong : Double = 0;
    var midi : Int = 0;
    
    init(start: Double, end: Double, durationPlayed: Double, y: Double, BPM: Double, timeInSong: Double, midi: Int) {
        self.start = start
        self.end = end
        self.durationPlayed = durationPlayed
        self.y = y
        self.time = BPM
        self.timeInSong = timeInSong;
        self.midi = midi
    }
    
    init(start: Double, end: Double, durationPlayed: Double, y: Double, BPM: Double, midi: Int) {
        self.start = start;
        self.end = end;
        self.durationPlayed = durationPlayed;
        self.y = y;
        self.time = BPM;
        self.midi = midi
    }
    
    init(start: Double, end: Double, y: Double, time: Double, midi : Int){
        self.start = start;
        self.end = end;
        self.durationPlayed = 0;
        self.y = y;
        self.time = time
        self.midi = midi
    }
    
    init(durationPlayed: Double) {
        self.durationPlayed = durationPlayed
    }
    
    init() {
        
    }
    
    func copy() -> Interval {
        return Interval(start: start, end: end, durationPlayed: durationPlayed, y: y, BPM: time, timeInSong: timeInSong, midi: midi)
    }
    
}

@Model
final class NoteIntervals {
    var cursor : Int;
    var intervals : [Interval];
    var wrongIntervals : [Interval];
    
    init() {
        self.cursor = 0;
        self.intervals = []
        self.wrongIntervals = []
    }
    
    init(intervals : [Interval]) {
        self.cursor = 0;
        self.intervals = intervals
        self.wrongIntervals = []
    }
    
    init(cursor: Int, intervals : [Interval], wrongIntervals : [Interval]) {
        self.cursor = cursor
        self.intervals = intervals
        self.wrongIntervals = wrongIntervals
    }
    
    func copy() -> NoteIntervals {
        var copiedIntervals : [Interval] = []
        var copiedWrong : [Interval] = []
        
        for i in self.intervals {
            copiedIntervals.append(i.copy())
        }
        
        for i in self.wrongIntervals {
            copiedWrong.append(i.copy())
        }
        
        return NoteIntervals(cursor: cursor, intervals: copiedIntervals, wrongIntervals: copiedWrong)
                
    }
    
    func current() -> Interval {
        return intervals[cursor]
    }
    
}
