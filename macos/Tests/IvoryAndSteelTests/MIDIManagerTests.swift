import XCTest
import CoreMIDI
@testable import IvoryAndSteel

private final class SafeBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T
    
    init(_ value: T) {
        self._value = value
    }
    
    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}

final class MIDIManagerTests: XCTestCase {
    
    func testSimulateNoteOnAndOff() {
        let midiManager = MIDIManager()
        
        let receivedNoteOn = SafeBox<(note: Int, velocity: Float)?>(nil)
        let receivedNoteOff = SafeBox<Int?>(nil)
        
        midiManager.onNoteOn = { note, vel in
            receivedNoteOn.value = (note, vel)
        }
        midiManager.onNoteOff = { note in
            receivedNoteOff.value = note
        }
        
        // Test Note On
        midiManager.simulateNoteOn(note: 60, velocity: 0.82)
        XCTAssertEqual(receivedNoteOn.value?.note, 60)
        XCTAssertEqual(receivedNoteOn.value?.velocity ?? 0.0, 0.82, accuracy: 0.001)
        
        // Test Note Off
        midiManager.simulateNoteOff(note: 60)
        XCTAssertEqual(receivedNoteOff.value, 60)
    }
    
    func testUniversalMIDIPacketParsing() {
        let midiManager = MIDIManager()
        
        let dispatchedNotes = SafeBox<[(type: String, note: Int, velocity: Float)]>([])
        midiManager.onNoteOn = { note, vel in
            var list = dispatchedNotes.value
            list.append(("ON", note, vel))
            dispatchedNotes.value = list
        }
        midiManager.onNoteOff = { note in
            var list = dispatchedNotes.value
            list.append(("OFF", note, 0.0))
            dispatchedNotes.value = list
        }
        
        // Construct UMP 32-bit Word:
        // Message Type 0x2 (MIDI 1.0 Channel Voice): (0x2 << 28)
        // Group 0x0
        // Status 0x9 (Note On): (0x9 << 20)
        // Channel 0x0
        // Note 64 (E4): (64 << 8)
        // Velocity 127: 127
        let noteOnWord: UInt32 = (0x2 << 28) | (0x9 << 20) | (64 << 8) | 127
        midiManager.parseUMPWord(noteOnWord)
        
        XCTAssertEqual(dispatchedNotes.value.count, 1)
        XCTAssertEqual(dispatchedNotes.value.first?.type, "ON")
        XCTAssertEqual(dispatchedNotes.value.first?.note, 64)
        XCTAssertEqual(dispatchedNotes.value.first?.velocity ?? 0.0, 1.0, accuracy: 0.01)
        
        // Running status: Note On with zero velocity should convert to Note Off
        let noteOnZeroVelWord: UInt32 = (0x2 << 28) | (0x9 << 20) | (64 << 8) | 0
        midiManager.parseUMPWord(noteOnZeroVelWord)
        
        XCTAssertEqual(dispatchedNotes.value.count, 2)
        XCTAssertEqual(dispatchedNotes.value.last?.type, "OFF")
        XCTAssertEqual(dispatchedNotes.value.last?.note, 64)
        
        // Explicit Note Off word (Status 0x8)
        let noteOffWord: UInt32 = (0x2 << 28) | (0x8 << 20) | (72 << 8) | 64
        midiManager.parseUMPWord(noteOffWord)
        
        XCTAssertEqual(dispatchedNotes.value.count, 3)
        XCTAssertEqual(dispatchedNotes.value.last?.type, "OFF")
        XCTAssertEqual(dispatchedNotes.value.last?.note, 72)
    }
    
    func testLegacyMIDIPacketParsing() {
        let midiManager = MIDIManager()
        
        let receivedNoteOn = SafeBox<(note: Int, velocity: Float)?>(nil)
        let receivedNoteOff = SafeBox<Int?>(nil)
        
        midiManager.onNoteOn = { note, vel in
            receivedNoteOn.value = (note, vel)
        }
        midiManager.onNoteOff = { note in
            receivedNoteOff.value = note
        }
        
        // Allocate a raw buffer for MIDIPacketList
        var packetList = MIDIPacketList()
        packetList.numPackets = 1
        
        // Note On: 0x90, note 67 (G4), velocity 100
        packetList.packet.length = 3
        packetList.packet.timeStamp = 0
        packetList.packet.data.0 = 0x90
        packetList.packet.data.1 = 67
        packetList.packet.data.2 = 100
        
        withUnsafePointer(to: &packetList) { listPtr in
            midiManager.parseMIDIPacketList(listPtr)
        }
        
        XCTAssertEqual(receivedNoteOn.value?.note, 67)
        XCTAssertEqual(receivedNoteOn.value?.velocity ?? 0.0, Float(100) / 127.0, accuracy: 0.01)
        
        // Note Off: 0x80, note 67, velocity 0
        packetList.packet.data.0 = 0x80
        packetList.packet.data.1 = 67
        packetList.packet.data.2 = 0
        
        withUnsafePointer(to: &packetList) { listPtr in
            midiManager.parseMIDIPacketList(listPtr)
        }
        
        XCTAssertEqual(receivedNoteOff.value, 67)
    }
    
    func testRefreshSourcesSafety() {
        let midiManager = MIDIManager()
        let sources = midiManager.refreshSources()
        // Should return array without crashing (may be empty on headless test runner)
        XCTAssertNotNil(sources)
    }
}
