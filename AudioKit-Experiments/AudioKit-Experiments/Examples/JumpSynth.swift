import AudioKit
import DunneAudioKit
import AudioKitEX
import AudioKitUI
import AVFAudio
import Keyboard
import SwiftUI
import Controls
import Tonic
import MIDIKit

class PolyphonicSynthConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var instrument = Synth()

    // MIDI Manager (MIDI methods are in SoundFont+MIDI)
    let midiManager = MIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    func noteOn(pitch: Pitch, point _: CGPoint) {
        instrument.play(noteNumber: MIDINoteNumber(pitch.midiNoteNumber), velocity: 120, channel: 0)
    }

    func noteOff(pitch: Pitch) {
        instrument.stop(noteNumber: MIDINoteNumber(pitch.midiNoteNumber), channel: 0)
    }

    init() {
        engine.output = PeakLimiter(instrument, attackTime: 0.001, decayTime: 0.001, preGain: 0)
        
        //Remove pops
        instrument.releaseDuration = 0.01
        instrument.filterReleaseDuration = 10.0
        
        instrument.filterStrength = 40.0
        
        // Set up MIDI
        MIDIConnect()
    }
    
    // Connect MIDI on init
    func MIDIConnect() {
        do {
            print("Starting MIDI services.")
            try midiManager.start()
        } catch {
            print("Error starting MIDI services:", error.localizedDescription)
        }
        
        do {
            try midiManager.addInputConnection(
                to: .allOutputs, // no need to specify if we're using .allEndpoints
                tag: "Listener",
                filter: .owned(), // don't allow self-created virtual endpoints
                receiver: .events { [weak self] events in
                    // Note: this handler will be called on a background thread
                    // so call the next line on main if it may result in UI updates
                    DispatchQueue.main.async {
                        events.forEach { self?.received(midiEvent: $0) }
                    }
                }
            )
        } catch {
            print(
                "Error setting up managed MIDI all-listener connection:",
                error.localizedDescription
            )
        }
    }
    
    // MIDI Events
    private func received(midiEvent: MIDIKit.MIDIEvent) {
        switch midiEvent {
        case .noteOn(let payload):
            print("Note On:", payload.note, payload.velocity, payload.channel)
            instrument.play(noteNumber: MIDINoteNumber(payload.note.number.uInt8Value), velocity: payload.velocity.midi1Value.uInt8Value, channel: 0)
            NotificationCenter.default.post(name: .MIDIKey, object: nil, userInfo: ["info": payload.note.number.uInt8Value, "bool": true])
        case .noteOff(let payload):
            print("Note Off:", payload.note, payload.velocity, payload.channel)
            instrument.stop(noteNumber: MIDINoteNumber(payload.note.number.uInt8Value), channel: 0)
            NotificationCenter.default.post(name: .MIDIKey, object: nil, userInfo: ["info": payload.note.number.uInt8Value, "bool": false])
        case .cc(let payload):
            print("CC:", payload.controller, payload.value, payload.channel)
        case .programChange(let payload):
            print("Program Change:", payload.program, payload.channel)
        default:
            break
        }
    }
}

struct PolyphonicSynthView: View {
    @StateObject var conductor = PolyphonicSynthConductor()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack{
            FFTView2(conductor.instrument, barColor: .blue, placeMiddle: true, barCount: 40)
            VStack{
                HStack {
                    ForEach(0...6, id: \.self){
                        ParameterRow(param: conductor.instrument.parameters[$0])
                    }
                }.padding(5)
                HStack {
                    ForEach(7...13, id: \.self){
                        ParameterRow(param: conductor.instrument.parameters[$0])
                    }
                }.padding(5)
            }.padding(5)
        }
        SwiftUIKeyboard( firstOctave: 1
                         ,octaveCount: 4,noteOn: conductor.noteOn,
                         noteOff: conductor.noteOff, color: .blue)
            .onAppear {
                conductor.start()
            }
            .onDisappear {
                conductor.stop()
            }
            .background(colorScheme == .dark ?
                         Color.clear : Color(red: 0.9, green: 0.9, blue: 0.9))
    }
}


