import Foundation
import CoreMIDI

/// Manages USB and Bluetooth CoreMIDI keyboard connections, Universal MIDI Packets (UMP),
/// and legacy MIDIPacketList stream parsing for Ivory & Steel Native macOS.
public final class MIDIManager: @unchecked Sendable {
    
    public static let shared = MIDIManager()
    
    private var clientRef = MIDIClientRef()
    private var inputPortRef = MIDIPortRef()
    private let lock = NSLock()
    
    private var connectedSources: [MIDIEndpointRef] = []
    private var sourceDeviceNames: [String] = []
    
    // Callbacks for dispatched MIDI events
    public var onNoteOn: (@Sendable (Int, Float) -> Void)?
    public var onNoteOff: (@Sendable (Int) -> Void)?
    public var onDevicesChanged: (@Sendable ([String]) -> Void)?
    
    public var connectedDevices: [String] {
        lock.lock()
        defer { lock.unlock() }
        return sourceDeviceNames
    }
    
    public init() {
        setupMIDIClient()
        refreshSources()
    }
    
    deinit {
        dispose()
    }
    
    public func dispose() {
        lock.lock()
        defer { lock.unlock() }
        
        if inputPortRef != 0 {
            MIDIPortDispose(inputPortRef)
            inputPortRef = 0
        }
        if clientRef != 0 {
            MIDIClientDispose(clientRef)
            clientRef = 0
        }
        connectedSources.removeAll()
        sourceDeviceNames.removeAll()
    }
    
    // MARK: - CoreMIDI Setup
    
    private func setupMIDIClient() {
        var status = MIDIClientCreateWithBlock("com.ivoryandsteel.midi.client" as CFString, &clientRef) { [weak self] notifyPtr in
            self?.handleMIDINotification(notifyPtr)
        }
        guard status == noErr else { return }
        
        // macOS 11+ / macOS 14+ Universal MIDI Packet (UMP) port
        status = MIDIInputPortCreateWithProtocol(
            clientRef,
            "com.ivoryandsteel.midi.input" as CFString,
            ._1_0,
            &inputPortRef
        ) { [weak self] eventListPtr, _ in
            self?.parseMIDIEventList(eventListPtr)
        }
    }
    
    private func handleMIDINotification(_ notifyPtr: UnsafePointer<MIDINotification>) {
        let messageID = notifyPtr.pointee.messageID
        switch messageID {
        case .msgSetupChanged, .msgObjectAdded, .msgObjectRemoved:
            refreshSources()
        default:
            break
        }
    }
    
    // MARK: - Dynamic Device Discovery
    
    /// Scans all active USB and Bluetooth MIDI endpoints and connects them to the input port.
    @discardableResult
    public func refreshSources() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        let sourceCount = MIDIGetNumberOfSources()
        var names: [String] = []
        var endpoints: [MIDIEndpointRef] = []
        
        for i in 0..<sourceCount {
            let endpoint = MIDIGetSource(i)
            guard endpoint != 0 else { continue }
            endpoints.append(endpoint)
            
            var nameRef: Unmanaged<CFString>?
            let err = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &nameRef)
            let deviceName: String
            if err == noErr, let name = nameRef {
                deviceName = name.takeRetainedValue() as String
            } else {
                deviceName = "MIDI Device \(i + 1)"
            }
            names.append(deviceName)
            
            if inputPortRef != 0 {
                MIDIPortConnectSource(inputPortRef, endpoint, nil)
            }
        }
        
        self.connectedSources = endpoints
        self.sourceDeviceNames = names
        
        let reportedNames = names
        DispatchQueue.main.async { [weak self] in
            self?.onDevicesChanged?(reportedNames)
        }
        
        return names
    }
    
    // MARK: - Universal MIDI Packet (UMP) Parser (macOS 14+)
    
    /// Parses macOS 14 Universal MIDI Packets (UMP / MIDIEventList)
    public func parseMIDIEventList(_ eventListPtr: UnsafePointer<MIDIEventList>) {
        let packetCount = Int(eventListPtr.pointee.numPackets)
        guard packetCount > 0 else { return }
        
        withUnsafePointer(to: eventListPtr.pointee.packet) { firstPacket in
            var currentPacket: UnsafePointer<MIDIEventPacket> = firstPacket
            for _ in 0..<packetCount {
                let packet = currentPacket.pointee
                let wordCount = Int(packet.wordCount)
                if wordCount > 0 {
                    withUnsafePointer(to: packet.words) { wordsPtr in
                        let rawWords = UnsafeRawPointer(wordsPtr).assumingMemoryBound(to: UInt32.self)
                        let word0 = rawWords[0]
                        parseUMPWord(word0)
                    }
                }
                currentPacket = UnsafePointer(MIDIEventPacketNext(UnsafeMutablePointer(mutating: currentPacket)))
            }
        }
    }
    
    /// Decodes a 32-bit MIDI 1.0 Channel Voice UMP word:
    /// Bits 28..31: Message Type (0x2 = MIDI 1.0 Voice)
    /// Bits 20..23: Status Nibble (0x9 = Note On, 0x8 = Note Off)
    /// Bits 16..19: Channel (0x0..0xF)
    /// Bits 8..15:  MIDI Note (0..127)
    /// Bits 0..7:   Velocity (0..127)
    public func parseUMPWord(_ word: UInt32) {
        let messageType = (word >> 28) & 0x0F
        guard messageType == 0x2 else { return } // 0x2 = MIDI 1.0 Channel Voice
        
        let statusNibble = (word >> 20) & 0x0F
        let note = Int((word >> 8) & 0x7F)
        let velocityByte = UInt8(word & 0x7F)
        let velocity = Float(velocityByte) / 127.0
        
        if statusNibble == 0x9 { // Note On
            if velocityByte == 0 {
                // Running status / Note On with zero velocity is Note Off
                dispatchNoteOff(note: note)
            } else {
                dispatchNoteOn(note: note, velocity: velocity)
            }
        } else if statusNibble == 0x8 { // Note Off
            dispatchNoteOff(note: note)
        }
    }
    
    // MARK: - Legacy MIDIPacketList Parser
    
    /// Parses standard legacy `MIDIPacketList` for backward compatibility.
    public func parseMIDIPacketList(_ packetListPtr: UnsafePointer<MIDIPacketList>) {
        let packetCount = Int(packetListPtr.pointee.numPackets)
        guard packetCount > 0 else { return }
        
        withUnsafePointer(to: packetListPtr.pointee.packet) { firstPacket in
            var currentPacket: UnsafePointer<MIDIPacket> = firstPacket
            for _ in 0..<packetCount {
                let packet = currentPacket.pointee
                let length = Int(packet.length)
                if length >= 3 {
                    withUnsafePointer(to: packet.data) { dataPtr in
                        let bytes = UnsafeRawPointer(dataPtr).assumingMemoryBound(to: UInt8.self)
                        let status = bytes[0] & 0xF0
                        let note = Int(bytes[1] & 0x7F)
                        let velocityByte = bytes[2] & 0x7F
                        let velocity = Float(velocityByte) / 127.0
                        
                        if status == 0x90 { // Note On
                            if velocityByte == 0 {
                                dispatchNoteOff(note: note)
                            } else {
                                dispatchNoteOn(note: note, velocity: velocity)
                            }
                        } else if status == 0x80 { // Note Off
                            dispatchNoteOff(note: note)
                        }
                    }
                }
                currentPacket = UnsafePointer(MIDIPacketNext(UnsafeMutablePointer(mutating: currentPacket)))
            }
        }
    }
    
    // MARK: - Event Dispatching & Simulation
    
    public func dispatchNoteOn(note: Int, velocity: Float) {
        let clampedVel = max(0.0, min(1.0, velocity))
        onNoteOn?(note, clampedVel)
    }
    
    public func dispatchNoteOff(note: Int) {
        onNoteOff?(note)
    }
    
    /// Simulates a Note On event (useful for unit testing without physical MIDI keyboard).
    public func simulateNoteOn(note: Int, velocity: Float) {
        dispatchNoteOn(note: note, velocity: velocity)
    }
    
    /// Simulates a Note Off event.
    public func simulateNoteOff(note: Int) {
        dispatchNoteOff(note: note)
    }
}
