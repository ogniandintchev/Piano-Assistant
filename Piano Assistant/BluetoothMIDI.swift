import SwiftUI
import CoreMIDI
import Combine

class BluetoothMIDI: ObservableObject {
    
    private var client = MIDIClientRef() // Client (the app) for MIDI
    private var inputPort = MIDIPortRef() // Where input is recieved
    var handler : SongHandler
    
    init(_ h: SongHandler) {
        
        handler = h
        MIDIClientCreate("MIDI Client" as CFString, nil, nil, &client) // Create a MIDI client to vairable client
        
        // Create an input that calls midiReadCallback on input and sets a reference to self to update the class
        // Unmanaged.passUnretained(self).toOpaque() turns self into an opaque object to interact with C based MIDI module
        MIDIInputPortCreate(client, "Input Port" as CFString, midiReadCallback, Unmanaged.passUnretained(self).toOpaque(), &inputPort)

        
        print(MIDIGetNumberOfSources())
        
        // Loop to connect to all MIDI sources
        for i in 0..<MIDIGetNumberOfSources() {
            MIDIPortConnectSource(inputPort, MIDIGetSource(i), nil)
            print(MIDIGetSource(i))
        }
        
        
        
    }
}

private func midiReadCallback(
    packetList: UnsafePointer<MIDIPacketList>,
    readProcRefCon: UnsafeMutableRawPointer?,
    srcConnRefCon: UnsafeMutableRawPointer?) {
        
        
    guard let refCon = readProcRefCon else {
        print("refcon but is nil")
        return
    } // exit if readProcRefCon if nil
    
    // Unpackage the input reference back into a Swift class BluetoothMIDI
    let midiManager = Unmanaged<BluetoothMIDI>.fromOpaque(refCon).takeUnretainedValue()
        
    var packet = packetList.pointee.packet // get first packet of packet list
    for _ in 0 ..< packetList.pointee.numPackets { // for every packet
        
        let bytes = packetToInt(packet)
        var j = 0
        while j < bytes.count { // while there is data in the packet
            
            // Only accept on or off packets,
            var currentPacket : [Int] = []
            if (128 <= bytes[j] && bytes[j] <= 159 && j+2 < bytes.count) {
                currentPacket = [bytes[j], bytes[j+1], bytes[j+2]]
                j+=3
                
                DispatchQueue.main.async {
                    midiManager.handler.onInput(bytes: currentPacket)
                }
            } else {
                j+=1
            }
            
        }
        packet = MIDIPacketNext(&packet).pointee // set packet to the next packet
    }
        
}

func packetToInt(_ pkt: MIDIPacket) -> [Int] {
    /// Cast a MIDIPacket into an [Int]
    let converted: [Int] = withUnsafeBytes(of: pkt.data) { rawPtr in
        let buffer = rawPtr.bindMemory(to: UInt8.self)
        return Array(buffer.prefix(Int(pkt.length)).map { Int($0) })
    }
    return converted
}


// 128-143 Note off
// 144-159 Note On
// 21-127 Key number
// 176 control
// <On/Off>, <Key>, <Velocity>
