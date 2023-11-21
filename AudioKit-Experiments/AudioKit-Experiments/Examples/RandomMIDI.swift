import AudioKit
import AudioKitEX
import AudioKitUI
import AVFAudio
import Keyboard
import SwiftUI
import Controls
import Tonic

class RandomMIDIConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    var sequencer: SequencerTrack!
    var midiCallback: CallbackInstrument!
    
    var noteArray = [50, 52, 54, 55, 57, 59, 61]
    var sequencerNoteLength = 1.0
    
    @Published var tempo : Float = 60.0 {
        didSet{
            sequencer.tempo = BPM(tempo)
        }
    }
    
    @Published var noteLength : Float = 1.0 {
        didSet{
            sequencerNoteLength = Double(noteLength)
            sequencer.clear()
            sequencer.add(noteNumber: 60, position: 0.0, duration: max(0.05, sequencerNoteLength * 0.99))
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
    
    func fireTimer() {
        for i in 0...127 {
            self.instrument.stop(noteNumber: MIDINoteNumber(i), channel: 0)
        }
        
        let randomNote = noteArray[Int.random(in: 0..<7)] + 12 * Int.random(in: 0..<3);
        
        if Int.random(in: 0..<3) == 1 {
            instrument.play(noteNumber: MIDINoteNumber(randomNote), velocity: 120, channel: 0)
        }
    }
    
    init() {
        
        midiCallback = CallbackInstrument { status, note, vel in
            if status == 144 { //Note On
                self.fireTimer()
            } else if status == 128 { //Note Off
            //all notes off
                for i in 0...127 {
                    self.instrument.stop(noteNumber: MIDINoteNumber(i), channel: 0)
                }
            }
        }
        let reverb = Reverb(Mixer(instrument, midiCallback), dryWetMix: 1)
        reverb.loadFactoryPreset(.largeChamber)
        
        engine.output = PeakLimiter(reverb, attackTime: 0.001, decayTime: 0.001, preGain: 0)
        
        
        
        do {
            if let fileURL = Bundle.main.url(forResource: "Sounds/Instrument1", withExtension: "aupreset") {
                try instrument.loadInstrument(url: fileURL)
            } else {
                Log("Could not find file")
            }
        } catch {
            Log("Could not load instrument")
        }
        
        attack = 4
        attack2 = 2
        release = 8
        resonance = 30
        cutoff = 80
        instrument.samplerUnit.sendController(1, withValue: UInt8(40), onChannel: 0)
        
        sequencer = SequencerTrack(targetNode: midiCallback)
        sequencer.length = 1.0
        sequencer.loopEnabled = true
        sequencer.add(noteNumber: 60, position: 0.0, duration: 0.99)
        tempo = 60
        
        sequencer?.playFromStart()
    }
}

struct RandomMIDIView: View {
    @StateObject var conductor = RandomMIDIConductor()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack{
            //Image
            //https://unsplash.com/photos/brown-string-instrument-qUpzRaylopM
            Image("visualizerBG2")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.4)
                .ignoresSafeArea()
            FFTView2(conductor.engine.output!, barColor: .white.opacity(0.75), placeMiddle: false, barCount: 100, minAmplitude: -130).aspectRatio(contentMode: .fit)
            VStack{
                Text("This example plays random MIDI notes in a scale.\n\nIt also works as a MIDI AUv3.").multilineTextAlignment(.center).padding(5)
                Spacer()
            }
        }
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
