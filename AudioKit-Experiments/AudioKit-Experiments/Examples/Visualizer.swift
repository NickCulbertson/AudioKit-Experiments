import AudioKit
import AudioKitUI
import AVFoundation
import Keyboard
import SwiftUI
import Tonic
import MIDIKit

class VisualizerConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var player = AudioPlayer()
    
    
    init() {
        // Make engine connections
        // Engine started in HasAudioEngine
        engine.output = player
        
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

struct VisualizerView: View {
    @StateObject var conductor = VisualizerConductor()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Image("visualizerBG")
                .resizable()
                .aspectRatio(contentMode: .fill)
            FFTView2(conductor.engine.output!, placeMiddle: false, barCount: 120)
        }
        
        .onAppear {
            conductor.start()
            
            
        }
        .onDisappear {
            conductor.player.stop()
            conductor.stop()
        }
        .background(colorScheme == .dark ?
                    Color.clear : Color(red: 0.9, green: 0.9, blue: 0.9))
    }
}
