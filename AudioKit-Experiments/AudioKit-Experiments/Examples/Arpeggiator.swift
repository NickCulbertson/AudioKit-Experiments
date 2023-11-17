import AudioKit
import AudioKitEX
import AudioKitUI
import AVFAudio
import Keyboard
import SwiftUI
import Controls
import Tonic
import MIDIKit

class ArpeggiatorConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    var sequencer = AppleSequencer()
    var midiCallback = MIDICallbackInstrument()
    
    var heldNotes = [Int]()
    var arpUp = false
    var currentNote = 0
    var sequencerNoteLength = 1.0
    
    // MIDI Manager (MIDI methods are in SoundFont+MIDI)
    let midiManager = MIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    @Published var tempo : Float = 120.0 {
        didSet{
            sequencer.setTempo(Double(tempo))
        }
    }
    
    @Published var noteLength : Float = 1.0 {
        didSet{
            sequencerNoteLength = Double(noteLength)
            sequencer.tracks.first?.clearNote(MIDINoteNumber(60))
            sequencer.tracks.first?.add(noteNumber: MIDINoteNumber(60), velocity: 127, position: Duration(beats: 0), duration: Duration(beats: max(0.02, sequencerNoteLength * 0.24)))
        }
    }
    
    @Published var resonance : Float = 0.0 {
        didSet{
#if targetEnvironment(macCatalyst)
            instrument.samplerUnit.sendController(71, withValue: UInt8(resonance), onChannel: 0)
#else
            let value = resonance / 127 * 25 - 3
            instrument.samplerUnit.setResonance(value: value)
#endif
        }
    }
    
    @Published var cutoff : Float = 127.0 {
        didSet{
            instrument.samplerUnit.sendController(74, withValue: UInt8(max(0,cutoff)), onChannel: 0)
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
        //add notes to an array
        heldNotes.append(max(0,pitch.intValue))
    }
    
    func fireTimer() {
        
        if self.heldNotes.count < 1 {
            return
        }
        
        //UP
        if !arpUp {
            let tempArray = heldNotes
            var arrayValue = 0
            if tempArray.max() != currentNote {
                arrayValue = tempArray.sorted().first(where: { $0 > currentNote }) ?? tempArray.min()!
                currentNote = arrayValue
            }else{
                arpUp = true
                arrayValue = tempArray.sorted().last(where: { $0 < currentNote }) ?? tempArray.max()!
                currentNote = arrayValue
            }
            
        }else{
            //DOWN
            let tempArray = heldNotes
            var arrayValue = 0
            if tempArray.min() != currentNote {
                arrayValue = tempArray.sorted().last(where: { $0 < currentNote }) ?? tempArray.max()!
                currentNote = arrayValue
            }else{
                arpUp = false
                arrayValue = tempArray.sorted().first(where: { $0 > currentNote }) ?? tempArray.min()!
                currentNote = arrayValue
            }
        }
        instrument.play(noteNumber: MIDINoteNumber(currentNote), velocity: 120, channel: 0)
    }
    
    func noteOff(pitch: Pitch) {
        let mynote = pitch.intValue
        
        //remove notes from an array
        for i in heldNotes {
            if i == mynote {
                heldNotes = heldNotes.filter {
                    $0 != mynote
                }
            }
        }
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
        
        //ARP STUFF
        midiCallback.callback = { status, note, velocity in
            if status == 144 { //Note On
                self.fireTimer()
            } else if status == 128 { //Note Off
                //all notes off
                for i in 0...127 {
                    self.instrument.stop(noteNumber: MIDINoteNumber(i), channel: 0)
                }
            }
        }
        
        _ = sequencer.newTrack("Track 1")
        sequencer.setLength(Duration(beats: 0.25))
        sequencer.setGlobalMIDIOutput(midiCallback.midiIn)
        sequencer.enableLooping()
        sequencer.tracks.first?.add(noteNumber: MIDINoteNumber(60), velocity: 127, position: Duration(beats: 0), duration: Duration(beats: max(0.02, sequencerNoteLength * 0.24)))
        sequencer.setTempo(Double(tempo))
        
        sequencer.play()
        
        
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
            noteOn(pitch: Pitch(Int8(payload.note.number.uInt8Value)), point: CGPoint(x: 0, y: 0))
            
            //            instrument.play(noteNumber: MIDINoteNumber(payload.note.number.uInt8Value), velocity: payload.velocity.midi1Value.uInt8Value, channel: 0)
            NotificationCenter.default.post(name: .MIDIKey, object: nil, userInfo: ["info": payload.note.number.uInt8Value, "bool": true])
        case .noteOff(let payload):
            print("Note Off:", payload.note, payload.velocity, payload.channel)
            noteOff(pitch: Pitch(Int8(payload.note.number.uInt8Value)))
            
            //            instrument.stop(noteNumber: MIDINoteNumber(payload.note.number.uInt8Value), channel: 0)
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

struct ArpeggiatorView: View {
    @StateObject var conductor = ArpeggiatorConductor()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack{
            FFTView2(conductor.instrument, barColor: .pink, placeMiddle: true, barCount: 40)
            VStack{
                HStack {
                    CookbookKnob(text: "Attack", parameter: $conductor.attack, range: 0.0...6.0)
                    CookbookKnob(text: "Release", parameter: $conductor.release, range: 0.0...8.0)
                    
                    CookbookKnob(text: "BPM", parameter: $conductor.tempo, range: 20.0...250.0)
                    CookbookKnob(text: "Length", parameter: $conductor.noteLength, range: 0.0...1.0)
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
                         noteOff: conductor.noteOff)
        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
            conductor.sequencer.stop()
        }
        .background(colorScheme == .dark ?
                    Color.clear : Color(red: 0.9, green: 0.9, blue: 0.9))
    }
}
