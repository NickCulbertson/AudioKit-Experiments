import AudioKit
import AudioKitUI
import AVFoundation
import Keyboard
import SwiftUI
import Tonic
import MIDIKit

class CircularVisualizerConductor: ObservableObject, HasAudioEngine {
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

struct CircularVisualizerView: View {
    @StateObject var conductor = CircularVisualizerConductor()
    var body: some View {
        VStack{
            ZStack {
                // Credit to the image creator, Jason Blackeye on Unsplash (https://unsplash.com/photos/silhouette-of-mountains-during-starry-night-FzURx0rFhUk)
                    Image("visualizerBG")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(0.4)
                FFTView2(conductor.engine.output!, barColor: .white.opacity(0.75), placeMiddle: false, barCount: 80, minAmplitude: -120).aspectRatio(contentMode: .fit)
            }
        }
        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.player.stop()
            conductor.stop()
        }
        .background(Color(red: 0.0, green: 0.0, blue: 0.0))
    }
}
