import SwiftUI
import AudioKit
import AVFoundation
import AudioKitEX
import Keyboard
import Waveform
import MIDIKit

extension AVAudioFile {
    /// converts to Swift friendly Float array
    public func toFloatChannelData2() -> [[Float]]? {
        guard let pcmBuffer = toAVAudioPCMBuffer(),
              let data = pcmBuffer.toFloatChannelData() else { return nil }
        return data
    }
}

class WaveformDemoModel2: ObservableObject {
    var samples: SampleBuffer
    
    init(file: AVAudioFile) {
        let stereo = file.toFloatChannelData2()!
        samples = SampleBuffer(samples: stereo[0])
    }
    
    func updateWaveform(file: AVAudioFile) {
        let stereo = file.toFloatChannelData2()!
        samples = SampleBuffer(samples: stereo[0])
    }
}

func getFile() -> AVAudioFile {
    let url = Bundle.main.url(forResource: "Sounds/mute", withExtension: "wav")!
    return try! AVAudioFile(forReading: url)
}

struct RecorderData {
    var isRecording = false
    var isPlaying = false
}
class RecorderViewConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var instrument = MIDISampler(name: "Instrument 1")
    var recorder: NodeRecorder2?
    let player = AudioPlayer()
    var silencer: Fader?
    let mixer = Mixer()
    var AUString = ""
    
    // MIDI Manager (MIDI methods are in SoundFont+MIDI)
    let midiManager = MIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    @Published var data = RecorderData() {
        didSet {
            if data.isRecording {
                do {
                    try recorder?.record()
                } catch let err {
                    print(err)
                }
            } else {
                recorder?.stop()
                if let file = recorder?.audioFile {
                    try? player.load(file: file)
                    makeInstrument()
                }
                
            }
            
            //            if data.isPlaying {
            //                if let file = recorder?.audioFile {
            //                    try? player.load(file: file)
            //                    player.play()
            //                    print(file)
            //                }
            //            } else {
            //                player.stop()
            //            }
        }
    }
    func makeInstrument() {
        setString()
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("myPreset.aupreset")
        let data = Data(AUString.utf8)
        do {
            try data.write(to: url!, options: .atomic)
            print("saved")
        } catch {
            print(error)
        }
        print("here")
        
        //reading
        
        do {
            try instrument.loadInstrument(url: (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("myPreset.aupreset"))!)
            instrument.volume = 12
            Log("instrument loaded")
            
        } catch {
            Log("Could not load instrument")
        }
    }
    
    func noteOn(pitch: Pitch, point _: CGPoint) {
        instrument.play(noteNumber: MIDINoteNumber(pitch.midiNoteNumber), velocity: 90, channel: 0)
    }
    
    func noteOff(pitch: Pitch) {
        instrument.stop(noteNumber: MIDINoteNumber(pitch.midiNoteNumber), channel: 0)
    }
    
    init() {
        
        guard let input = engine.input else {
            fatalError()
        }
        let rev = Reverb(input)
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let documentDirectory = URL(fileURLWithPath: path)
            recorder = try NodeRecorder2(node: rev, fileDirectoryURL: documentDirectory)
        } catch let err {
            fatalError("\(err)")
        }
        let silencer = Fader(rev, gain: 0)
        self.silencer = silencer
        //        mixer.addInput(silencer)
        //        engine.output = mixer
        
        engine.output = Mixer(player, silencer, instrument)
        
        // Load EXS file (you can also load SoundFonts and WAV files too using the AppleSampler Class)
        //        do {
        //            if let fileURL = Bundle.main.url(forResource: "Sounds/Sampler Instruments/sawPiano1", withExtension: "exs") {
        //                try instrument.loadInstrument(url: fileURL)
        //            } else {
        //                Log("Could not find file")
        //            }
        //        } catch {
        //            Log("Could not load instrument")
        //        }
        do {
            try engine.start()
        } catch {
            Log("AudioKit did not start!")
        }
        
        // Set up MIDI
        MIDIConnect()
    }
    
    //    func getDocumentsDirectory() -> URL {
    //        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    //        return paths[0]
    //    }
    func setString() {
        AUString = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AU version</key>
    <real>1</real>
    <key>Instrument</key>
    <dict>
        <key>Layers</key>
        <array>
            <dict>
                <key>Amplifier</key>
                <dict>
                    <key>ID</key>
                    <integer>0</integer>
                    <key>enabled</key>
                    <true/>
                </dict>
                <key>Connections</key>
                <array>
                    <dict>
                        <key>ID</key>
                        <integer>0</integer>
                        <key>control</key>
                        <integer>0</integer>
                        <key>destination</key>
                        <integer>816840704</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <false/>
                        <key>scale</key>
                        <real>12800</real>
                        <key>source</key>
                        <integer>300</integer>
                        <key>transform</key>
                        <integer>1</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>1</integer>
                        <key>control</key>
                        <integer>0</integer>
                        <key>destination</key>
                        <integer>1343225856</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <true/>
                        <key>scale</key>
                        <real>-96</real>
                        <key>source</key>
                        <integer>301</integer>
                        <key>transform</key>
                        <integer>2</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>2</integer>
                        <key>control</key>
                        <integer>0</integer>
                        <key>destination</key>
                        <integer>1343225856</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <true/>
                        <key>scale</key>
                        <real>-96</real>
                        <key>source</key>
                        <integer>7</integer>
                        <key>transform</key>
                        <integer>2</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>3</integer>
                        <key>control</key>
                        <integer>0</integer>
                        <key>destination</key>
                        <integer>1343225856</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <true/>
                        <key>scale</key>
                        <real>-96</real>
                        <key>source</key>
                        <integer>11</integer>
                        <key>transform</key>
                        <integer>2</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>4</integer>
                        <key>control</key>
                        <integer>0</integer>
                        <key>destination</key>
                        <integer>1344274432</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <false/>
                        <key>max value</key>
                        <real>0.50800001621246338</real>
                        <key>min value</key>
                        <real>-0.50800001621246338</real>
                        <key>source</key>
                        <integer>10</integer>
                        <key>transform</key>
                        <integer>1</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>7</integer>
                        <key>control</key>
                        <integer>241</integer>
                        <key>destination</key>
                        <integer>816840704</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <false/>
                        <key>max value</key>
                        <real>12800</real>
                        <key>min value</key>
                        <real>-12800</real>
                        <key>source</key>
                        <integer>224</integer>
                        <key>transform</key>
                        <integer>1</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>8</integer>
                        <key>control</key>
                        <integer>0</integer>
                        <key>destination</key>
                        <integer>816840704</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <false/>
                        <key>max value</key>
                        <real>100</real>
                        <key>min value</key>
                        <real>-100</real>
                        <key>source</key>
                        <integer>242</integer>
                        <key>transform</key>
                        <integer>1</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>6</integer>
                        <key>control</key>
                        <integer>1</integer>
                        <key>destination</key>
                        <integer>816840704</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <false/>
                        <key>max value</key>
                        <real>50</real>
                        <key>min value</key>
                        <real>-50</real>
                        <key>source</key>
                        <integer>268435456</integer>
                        <key>transform</key>
                        <integer>1</integer>
                    </dict>
                    <dict>
                        <key>ID</key>
                        <integer>5</integer>
                        <key>control</key>
                        <integer>0</integer>
                        <key>destination</key>
                        <integer>1343225856</integer>
                        <key>enabled</key>
                        <true/>
                        <key>inverse</key>
                        <true/>
                        <key>scale</key>
                        <real>-96</real>
                        <key>source</key>
                        <integer>536870912</integer>
                        <key>transform</key>
                        <integer>1</integer>
                    </dict>
                </array>
                <key>Envelopes</key>
                <array>
                    <dict>
                        <key>ID</key>
                        <integer>0</integer>
                        <key>Stages</key>
                        <array>
                            <dict>
                                <key>curve</key>
                                <integer>20</integer>
                                <key>stage</key>
                                <integer>0</integer>
                                <key>time</key>
                                <real>0.0</real>
                            </dict>
                            <dict>
                                <key>curve</key>
                                <integer>22</integer>
                                <key>stage</key>
                                <integer>1</integer>
                                <key>time</key>
                                <real>0.0</real>
                            </dict>
                            <dict>
                                <key>curve</key>
                                <integer>20</integer>
                                <key>stage</key>
                                <integer>2</integer>
                                <key>time</key>
                                <real>0.0</real>
                            </dict>
                            <dict>
                                <key>curve</key>
                                <integer>20</integer>
                                <key>stage</key>
                                <integer>3</integer>
                                <key>time</key>
                                <real>0.0</real>
                            </dict>
                            <dict>
                                <key>level</key>
                                <real>1</real>
                                <key>stage</key>
                                <integer>4</integer>
                            </dict>
                            <dict>
                                <key>curve</key>
                                <integer>20</integer>
                                <key>stage</key>
                                <integer>5</integer>
                                <key>time</key>
                                <real>0.0</real>
                            </dict>
                            <dict>
                                <key>curve</key>
                                <integer>20</integer>
                                <key>stage</key>
                                <integer>6</integer>
                                <key>time</key>
                                <real>0.004999999888241291</real>
                            </dict>
                        </array>
                        <key>enabled</key>
                        <true/>
                    </dict>
                </array>
                <key>Filters</key>
                <dict>
                    <key>ID</key>
                    <integer>0</integer>
                    <key>cutoff</key>
                    <real>20000</real>
                    <key>enabled</key>
                    <false/>
                    <key>resonance</key>
                    <real>-3</real>
                </dict>
                <key>ID</key>
                <integer>0</integer>
                <key>LFOs</key>
                <array>
                    <dict>
                        <key>ID</key>
                        <integer>0</integer>
                        <key>enabled</key>
                        <true/>
                    </dict>
                </array>
                <key>Oscillator</key>
                <dict>
                    <key>ID</key>
                    <integer>0</integer>
                    <key>enabled</key>
                    <true/>
                </dict>
                <key>Zones</key>
                <array>
                    <dict>
                        <key>ID</key>
                        <integer>1</integer>
                        <key>enabled</key>
                        <true/>
                        <key>loop enabled</key>
                        <false/>
                        <key>root key</key>
                        <integer>60</integer>
                        <key>waveform</key>
                        <integer>268435458</integer>
                    </dict>
                </array>
            </dict>
        </array>
        <key>name</key>
        <string>Default Instrument</string>
    </dict>
    <key>coarse tune</key>
    <integer>0</integer>
    <key>data</key>
    <data>
    AAAAAAAAAAAAAAAEAAADhAAAAAAAAAOFAAAAAAAAA4YAAAAAAAADhwAAAAA=
    </data>
    <key>file-references</key>
    <dict>
        <key>Sample:268435458</key>
        <string>\(String(describing: NodeRecorder2.recordedFiles[NodeRecorder2.recordedFiles.count-1]))</string>
    </dict>
    <key>fine tune</key>
    <real>0.0</real>
    <key>gain</key>
    <real>0.0</real>
    <key>manufacturer</key>
    <integer>1634758764</integer>
    <key>name</key>
    <string>samplerbase</string>
    <key>output</key>
    <integer>0</integer>
    <key>pan</key>
    <real>0.0</real>
    <key>subtype</key>
    <integer>1935764848</integer>
    <key>type</key>
    <integer>1635085685</integer>
    <key>version</key>
    <integer>0</integer>
    <key>voice count</key>
    <integer>64</integer>
</dict>
</plist>
"""
        ///Users/nickculbertson/Documents/arcade-synth/wavetablesynth/Sounds/sound3.wav
        print("Here")
        print(String(describing: NodeRecorder2.recordedFiles[NodeRecorder2.recordedFiles.count-1]))
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

struct RecordView: View {
    @StateObject var model = WaveformDemoModel2(file: getFile())
    @State var start = 0.0
    @State var length = 0.3
    @StateObject var conductor = RecorderViewConductor()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            VStack {
                FFTView2(conductor.instrument, barColor: .cyan, placeMiddle: true, barCount: 40)
                Text(conductor.data.isRecording ? "STOP RECORDING" : "RECORD")
                    .foregroundColor(.cyan)
                    .onTapGesture {
                        conductor.data.isRecording.toggle()
                        if !conductor.data.isRecording && NodeRecorder2.recordedFiles.count > 0 {
                            //let file = NodeRecorder2.currentFileURL
                            try? model.updateWaveform(file: AVAudioFile(forReading: NodeRecorder2.recordedFiles[NodeRecorder2.recordedFiles.count-1]))
                        }
                    }
            }
            ZStack(alignment: .leading) {
                Waveform(samples: model.samples).foregroundColor(.cyan)
                    .padding(.vertical, 5)
            }
            .frame(height: 200)
            .padding()
            SwiftUIKeyboard( firstOctave: 1
                             ,octaveCount: 4,noteOn: conductor.noteOn,
                             noteOff: conductor.noteOff)
        }

        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
        .background(.black)
    }
}
