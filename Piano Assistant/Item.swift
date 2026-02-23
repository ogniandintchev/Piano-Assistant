//
//  Item.swift
//  Piano Assistant
//
//  Created by Og D on 11/2/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@Model
final class Item {
    
    
    var songArray: [Chord]
    
    var title: String?
    
    var filePath : [URL] // TODO: USE THIS LATER WHEN ASSIGNING IMAGES TO SONGS IN LIST
    
    
    init(n: String) {
        title = n
        filePath = []
        self.songArray = []
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
    
    init(id: Int, midi: Int, note: String, accidental: String, octave: Int, posX: Double, posY: Double, measureMidY: Double) {
        self.id = id
        self.midi = midi
        self.note = note
        self.accidental = accidental
        self.octave = octave
        self.posX = posX
        self.posY = posY
        self.measureMidY = measureMidY
    }
    
    public func copy() -> Note {
        return Note(id: id, midi: midi, note: note, accidental: accidental, octave: octave, posX: posX, posY: posY, measureMidY: measureMidY)
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
