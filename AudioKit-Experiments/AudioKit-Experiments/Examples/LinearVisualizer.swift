import AudioKit
import AudioKitUI
import AVFoundation
import Keyboard
import SwiftUI
import Tonic
import MIDIKit

class LinearVisualizerConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var player = AudioPlayer()
    let mixer: Mixer!
    
    init() {
        // Make engine connections
        // Engine started in HasAudioEngine
        mixer = Mixer(player)
        engine.output = mixer
        
        let url = Bundle.main.resourceURL?.appendingPathComponent(
            "Sounds/Piano.mp3")
        loadFile(url: url!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.player.play()
        }
    }
    
    // Player functions
    func loadFile(url: URL) {
        do {
            try player.load(url: url)
        } catch {
            Log(error.localizedDescription, type: .error)
        }
    }
}

struct LinearVisualizerView: View {
    @StateObject var conductor = LinearVisualizerConductor()
    @Environment(\.colorScheme) var colorScheme
    @State private var hueVal = 0
    func hueValIncrease() {
        hueVal += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.hueValIncrease()
        }
    }
    
    var body: some View {
        VStack{
            ZStack {
                // Credit to the image creator, Jason Blackeye on Unsplash (https://unsplash.com/photos/silhouette-of-mountains-during-starry-night-FzURx0rFhUk)
                Image("visualizerBG")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.4)
                FFTView2(conductor.mixer, barColor: .blue, placeMiddle: true, barCount: 40)
            }
        }.hueRotation(.degrees(Double(hueVal)))
            .onAppear {
                conductor.start()
                hueValIncrease()
            }
            .onDisappear {
                conductor.player.stop()
                conductor.stop()
            }
            .background(Color(red: 0.0, green: 0.0, blue: 0.0))
    }
}
