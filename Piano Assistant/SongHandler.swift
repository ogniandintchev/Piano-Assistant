import SwiftUI
import Combine

class SongHandler : ObservableObject, Handler {
    
    var queueObject : NoteQueue
    var lastNotePressed : Int = 0
    
    let printOutResult = false
    let printPressed = false
    
    var recordInputs = false
    var recordedTransformed : [[Note]] = []
    var recorded : [[Int]] = []
    var lastUpdated : [Int] = []
    var currentlyHeld : [Int] = []
    
    
    init(queue: NoteQueue){
        queueObject = queue
        
    }
    
    func newSong(new : [Chord]) {
        queueObject.add(input: new)
    }
    
    func current() -> Chord { return queueObject.current }
    
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
            if (!queueObject.current.notes.isEmpty) {
                let out = queueObject.remove(a: bytes[1])
                if (printOutResult) {
                    if (out == -1) { print("Number not found") }
                    if (out == 1) { print("Removed") }
                }
                
                lastNotePressed = bytes[1]
                

            } else if (printOutResult) {
                print("Queue is empty")
            }
        
            if(printPressed) { print(bytes[1]) }
            
//            if (bytes[1] == 21) {
//                if recordInputs {
//                    recordInputs = false
//                    print(recorded)
//                    currentlyHeld = []
//                    recorded = []
//                }
//                else if !recordInputs { recordInputs = true }
//            }
            
        }
        
        
        if (recordInputs) {
            
            if (noteType == NoteType.ON) {
                if (bytes[1] == 21) { return }
                currentlyHeld.append(bytes[1])
                lastUpdated.append(bytes[1])
                print(currentlyHeld)
                print(lastUpdated)
                print(recorded)
                print("\n")
            }
            
            if (noteType == NoteType.OFF) {
                if (bytes[1] == 21) { return }
                if let index = currentlyHeld.firstIndex(of: bytes[1]) {
                    currentlyHeld.remove(at: index)
                }
                
                if (currentlyHeld.isEmpty) {
                    recorded.append(lastUpdated)
                    lastUpdated = []
                }
                
            }
            
        }
        
    }
    
}


protocol Handler: ObservableObject {
    
    func onInput(bytes: [Int])
    
}

