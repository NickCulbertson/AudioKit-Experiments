import SwiftUI
struct ContentView: View {
    var body: some View {
        NavigationView {
            MasterView()
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
struct MasterView: View {
    var body: some View {
        Form {
            Section(header: Text("Demos")) {
                Group {
                    NavigationLink("1. SoundFont Player", destination: SoundFontView())
                    NavigationLink("2. Circular Visualizer", destination: CircularVisualizerView())
                    NavigationLink("3. Linear Visualizer", destination: LinearVisualizerView())
                    NavigationLink("4. SpriteKit Audio", destination: SpriteSoundView())
                    NavigationLink("5. Sampler Synth", destination: RecordView())
                    NavigationLink("6. LFO Timer", destination: LFOView())
                    NavigationLink("7. Instrument AUPreset", destination: InstrumentAUPresetView())
                    NavigationLink("8. Instrument SFZ", destination: InstrumentSFZView())
                    NavigationLink("9. Jump Synth", destination: JumpSynthView())
                }
                Group {
                    NavigationLink("10. Arpeggiator", destination: ArpeggiatorView())
                }
            }
        }.navigationBarTitle("AudioKit Experiments")
    }
}

extension NSNotification.Name {
    static let keyNoteOn = Notification.Name("keyNoteOn")
    static let keyNoteOff = Notification.Name("keyNoteOff")
    static let MIDIKey = Notification.Name("MIDIKey")
}

#Preview {
    ContentView()
}
