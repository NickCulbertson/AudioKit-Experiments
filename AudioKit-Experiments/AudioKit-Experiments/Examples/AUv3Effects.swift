import AudioKit
import DunneAudioKit
import AVFoundation
import Keyboard
import SwiftUI
import Tonic
import MIDIKit

class AUv3EffectsConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var player = AudioPlayer()
    let delay: StereoDelay
    
    init() {
        // Make engine connections
        // Engine started in HasAudioEngine
        delay = StereoDelay(player, time: 0.33, feedback: 0.33, pingPong: true)
        engine.output = delay
        
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

struct AUv3EffectsView: View {
    @StateObject var conductor = AUv3EffectsConductor()
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some View {
        VStack{
            ZStack {
                // Credit to the image creator, Jason Blackeye on Unsplash (https://unsplash.com/photos/silhouette-of-mountains-during-starry-night-FzURx0rFhUk)
                Image("visualizerBG2")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.5)
                HStack {
                    ForEach(conductor.delay.parameters) {
                        ParameterRow(param: $0)
                    }
                }
            }
        }.onAppear {
                conductor.start()
            }
            .onDisappear {
                conductor.player.stop()
                conductor.stop()
            }
            .background(Color(red: 0.0, green: 0.0, blue: 0.0))
    }
}
