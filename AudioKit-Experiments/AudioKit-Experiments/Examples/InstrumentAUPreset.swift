import AudioKit
import AudioKitEX
import AudioKitUI
import AVFAudio
import Keyboard
import SwiftUI
import Controls
import Tonic
import MIDIKit

class InstrumentAUPresetConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var instrument = AppleSampler()

    // MIDI Manager (MIDI methods are in SoundFont+MIDI)
    let midiManager = MIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    @Published var resonance : Float = 0.0 {
        didSet{
#if targetEnvironment(macCatalyst)
            instrument.samplerUnit.sendController(71, withValue: UInt8(resonance), onChannel: 0)
#else
            let value = resonance / 127 * 25 - 3
            print(value)
            instrument.samplerUnit.setResonance(value: value)
#endif
        }
    }
    
    @Published var cutoff : Float = 127.0 {
        didSet{
            instrument.samplerUnit.sendController(74, withValue: UInt8(cutoff), onChannel: 0)
        }
    }
    
    @Published var attack : Float = 0.0 {
        didSet{
            instrument.samplerUnit.setAttack(value: attack)
        }
    }
    
    @Published var decay : Float = 0.0 {
        didSet{
            instrument.samplerUnit.setDecay(value: decay)
        }
    }
    
    
    @Published var sustain : Float = 1.0 {
        didSet{
//            print("log \(log(sustain*1000)/log(1000))")
//            print(sustain)
            instrument.samplerUnit.setSustain(value: max(0,log(sustain*1000)/log(1000)))
        }
    }
    
    @Published var release : Float = 0.0 {
        didSet{
            instrument.samplerUnit.setRelease(value: release)
        }
    }
    
    @Published var attack2 : Float = 0.0 {
        didSet{
            instrument.samplerUnit.setAttack2(value: attack2)
        }
    }
    
    @Published var decay2 : Float = 0.0 {
        didSet{
            instrument.samplerUnit.setDecay2(value: decay2)
        }
    }
    
    @Published var sustain2 : Float = 1.0 {
        didSet{
            instrument.samplerUnit.setSustain2(value: max(0,log10(sustain2*10)))
        }
    }
    
    @Published var release2 : Float = 8.0 {
        didSet{
            instrument.samplerUnit.setRelease2(value: release2)
        }
    }
    
    func noteOn(pitch: Pitch, point _: CGPoint) {
        instrument.play(noteNumber: MIDINoteNumber(pitch.midiNoteNumber), velocity: 120, channel: 0)
    }

    func noteOff(pitch: Pitch) {
        instrument.stop(noteNumber: MIDINoteNumber(pitch.midiNoteNumber), channel: 0)
    }

    init() {
        engine.output = PeakLimiter(instrument, attackTime: 0.001, decayTime: 0.001, preGain: 0)
        do {
            if let fileURL = Bundle.main.url(forResource: "Sounds/Instrument1", withExtension: "aupreset") {
                try instrument.loadInstrument(url: fileURL)
            } else {
                Log("Could not find file")
            }
        } catch {
            Log("Could not load instrument")
        }
        attack = 0
        release = 0
        resonance = 0
        cutoff = 127
        
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
            if payload.controller == 74 {
                instrument.samplerUnit.sendController(74, withValue: payload.value.midi1Value.uInt8Value, onChannel: 0)
            }
        case .programChange(let payload):
            print("Program Change:", payload.program, payload.channel)
        default:
            break
        }
    }
}

struct InstrumentAUPresetView: View {
    @StateObject var conductor = InstrumentAUPresetConductor()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack{
            FFTView2(conductor.instrument, barColor: .green, placeMiddle: true, barCount: 40)
            VStack{
                HStack {
                    CookbookKnob(text: "Attack", parameter: $conductor.attack, range: 0.0...6.0)
                    CookbookKnob(text: "Decay", parameter: $conductor.decay, range: 0.0...6.0)
                    CookbookKnob(text: "Sustain", parameter: $conductor.sustain, range: 0.0...1.0)
                    CookbookKnob(text: "Release", parameter: $conductor.release, range: 0.0...8.0)
                    CookbookKnob(text: "Cutoff", parameter: $conductor.cutoff, range: 0.0...127.0)
                }
                HStack {
                    CookbookKnob(text: "Attack", parameter: $conductor.attack2, range: 0.0...6.0)
                    CookbookKnob(text: "Decay", parameter: $conductor.decay2, range: 0.0...6.0)
                    CookbookKnob(text: "Sustain", parameter: $conductor.sustain2, range: 0.0...1.0)
                    CookbookKnob(text: "Release", parameter: $conductor.release2, range: 0.0...8.0)
                    CookbookKnob(text: "Resonance", parameter: $conductor.resonance, range: 0.0...127.0)
                }.padding(5)
            }
        }
        SwiftUIKeyboard( firstOctave: 2
                         ,octaveCount: 4,noteOn: conductor.noteOn,
                         noteOff: conductor.noteOff, color: .green)
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

extension AVAudioUnit {
    func setResonance(value: Float) {
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = value
            AudioUnitSetProperty(
                self.audioUnit,
                4162,
                kAudioUnitScope_LayerItem,
                0x40000000 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setAttack(value: Float) {
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = max(0.001, value)
            AudioUnitSetProperty(
                self.audioUnit,
                4172,
                kAudioUnitScope_LayerItem,
                0x20000000 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setDecay(value: Float) {
        // https://infinum.com/blog/ausampler-missing-documentation/
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = value
            AudioUnitSetProperty(
                self.audioUnit,
                4174,
                kAudioUnitScope_LayerItem,
                0x20000000 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setSustain(value: Float) {
        // https://infinum.com/blog/ausampler-missing-documentation/
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = value
            AudioUnitSetProperty(
                self.audioUnit,
                4176,
                kAudioUnitScope_LayerItem,
                0x20000000 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setRelease(value: Float) {
        // https://infinum.com/blog/ausampler-missing-documentation/
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = max(0.001, value)
            AudioUnitSetProperty(
                self.audioUnit,
                4175,
                kAudioUnitScope_LayerItem,
                0x20000000 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setAttack2(value: Float) {
        // https://infinum.com/blog/ausampler-missing-documentation/
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = value
            AudioUnitSetProperty(
                self.audioUnit,
                4172,
                kAudioUnitScope_LayerItem,
                0x20000001 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setDecay2(value: Float) {
        // https://infinum.com/blog/ausampler-missing-documentation/
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = value
            AudioUnitSetProperty(
                self.audioUnit,
                4174,
                kAudioUnitScope_LayerItem,
                0x20000001 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setSustain2(value: Float) {
        // https://infinum.com/blog/ausampler-missing-documentation/
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = value
            AudioUnitSetProperty(
                self.audioUnit,
                4176,
                kAudioUnitScope_LayerItem,
                0x20000001 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
    
    func setRelease2(value: Float) {
        // https://infinum.com/blog/ausampler-missing-documentation/
        let instrument = auAudioUnit.fullState?["Instrument"] as? NSDictionary
        guard let layers = instrument?["Layers"] as? NSArray else { return }
        for layerIndex in 0..<UInt32(layers.count) {
            var value = value
            AudioUnitSetProperty(
                self.audioUnit,
                4175,
                kAudioUnitScope_LayerItem,
                0x20000001 + (0x100 * layerIndex),
                &value,
                UInt32(MemoryLayout<Float>.size)
            )
        }
    }
}
