import AudioKit
import AudioKitUI
import AVFoundation
import Keyboard
import SwiftUI
import Tonic
import MIDIKit

class SoundFontConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    var currentPreset = 0
    
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
        // Make engine connections
        // Engine started in HasAudioEngine
        engine.output = instrument
        
        // Load SoundFont file
        do {
            if let fileURL = Bundle.main.url(forResource: "Sounds/PianoMuted", withExtension: "sf2") {
                var isPreset = false
                for i in 0...127 {
                    print(i)
                    isPreset = true
                    do {
                        try instrument.samplerUnit.loadSoundBankInstrument(
                            at: fileURL,
                            program: MIDIByte(i),
                            bankMSB: MIDIByte(kAUSampler_DefaultMelodicBankMSB),
                            bankLSB: MIDIByte(kAUSampler_DefaultBankLSB)
                        )
                    } catch {
                        Log("Could not load instrument")
                        isPreset = false
                    }
                    if isPreset {
                        print(try instrument.samplerUnit.audioUnit.getPropertyInfo(propertyID: kAUSamplerProperty_BankAndPreset))
                        currentPreset = i
                        break
                    }
                }
                
            } else {
                Log("Could not find file")
            }
        } catch {
            Log("Could not load instrument")
        }
        
        // Set up MIDI
        MIDIConnect()
    }
}

struct SoundFontView: View {
    @State private var showFileImporter: Bool = false
    @State var imported = false
    @State var fileName = ""
    @State var musicFiles: [URL] = []
    @State var currentPreset = 0
    @StateObject var conductor = SoundFontConductor()
    @Environment(\.colorScheme) var colorScheme
    @State var files : Array<String> = []
    
    var body: some View {
        FFTView(conductor.instrument)
        VStack {
            HStack {
                Button("Prev") {
                    do {
                        if let fileURL = Bundle.main.url(forResource: "Sounds/PianoMuted", withExtension: "sf2") {
                            
                            var isPreset = false
                            currentPreset-=1
                            if currentPreset<0 {
                                currentPreset = 127
                            }
                            for i in 0...127 {
                                let offsetInt = currentPreset - i
                                print(offsetInt)
                                isPreset = true
                                do {
                                    try conductor.instrument.samplerUnit.loadSoundBankInstrument(
                                        at: fileURL,
                                        program: MIDIByte(offsetInt),
                                        bankMSB: MIDIByte(kAUSampler_DefaultMelodicBankMSB),
                                        bankLSB: MIDIByte(kAUSampler_DefaultBankLSB)
                                    )
                                } catch {
                                    Log("Could not load instrument")
                                    isPreset = false
                                }
                                if isPreset {
                                    print(try conductor.instrument.samplerUnit.audioUnit.getPropertyInfo(propertyID: kAUSamplerProperty_BankAndPreset))
                                    currentPreset = offsetInt
                                    break
                                }
                            }
                        } else {
                            Log("Could not find file")
                        }
                    } catch {
                        Log("Could not load instrument")
                    }
                }
                Button("Next") {
                    do {
                        if let fileURL = Bundle.main.url(forResource: "Sounds/PianoMuted", withExtension: "sf2") {
                            
                            var isPreset = false
                            currentPreset+=1
                            if currentPreset>127 {
                                currentPreset = 0
                            }
                            for i in currentPreset...127 {
                                print(i)
                                isPreset = true
                                do {
                                    try conductor.instrument.samplerUnit.loadSoundBankInstrument(
                                        at: fileURL,
                                        program: MIDIByte(i),
                                        bankMSB: MIDIByte(kAUSampler_DefaultMelodicBankMSB),
                                        bankLSB: MIDIByte(kAUSampler_DefaultBankLSB)
                                    )
                                } catch {
                                    Log("Could not load instrument")
                                    isPreset = false
                                }
                                if isPreset {
                                    print(try conductor.instrument.samplerUnit.audioUnit.getPropertyInfo(propertyID: kAUSamplerProperty_BankAndPreset))
                                    currentPreset = i
                                    break
                                }
                                if i == 127 {
                                    //Run again
                                    for ii in 0...127 {
                                        print(ii)
                                        isPreset = true
                                        do {
                                            try conductor.instrument.samplerUnit.loadSoundBankInstrument(
                                                at: fileURL,
                                                program: MIDIByte(ii),
                                                bankMSB: MIDIByte(kAUSampler_DefaultMelodicBankMSB),
                                                bankLSB: MIDIByte(kAUSampler_DefaultBankLSB)
                                            )
                                        } catch {
                                            Log("Could not load instrument")
                                            isPreset = false
                                        }
                                        if isPreset {
                                            print(try conductor.instrument.samplerUnit.audioUnit.getPropertyInfo(propertyID: kAUSamplerProperty_BankAndPreset))
                                            currentPreset = ii
                                            break
                                        }
                                        if ii == 127 {
                                            currentPreset = -1
                                        }
                                    }
                                }
                            }
                            
                        } else {
                            Log("Could not find file")
                        }
                    } catch {
                        Log("Could not load instrument")
                    }
                }
            }
        }
        SwiftUIKeyboard( firstOctave: 0
                         ,octaveCount: 4,noteOn: conductor.noteOn,
                         noteOff: conductor.noteOff)
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
