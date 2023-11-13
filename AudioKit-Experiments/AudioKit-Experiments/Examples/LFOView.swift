import AudioKit
import SporthAudioKit
import AudioKitUI
import AVFoundation
import Keyboard
import SwiftUI
import Tonic
import MIDIKit
import Controls

class LFOConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    
    var timer: Timer?
    var tickCount = 0.0
    var lfoAmount: Float = 1.0
    var lfoRate: Float = 0.15
    
    @Published var lfoValue = 0.0 {
        didSet{
            instrument.tuning = AUValue(lfoValue)
        }
    }
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            self.tickCount += Double(self.lfoRate)
            self.lfoValue = sin(Double(self.tickCount))*Double(self.lfoAmount)
            print(self.lfoValue)
        }
        
        engine.output = instrument
        
    }
}
    
struct LFOView: View {
    @StateObject var conductor = LFOConductor()
    var body: some View {
        VStack{
            HStack{
                VStack{
                    Text("Amount: \(conductor.lfoAmount)")
                    SmallKnob(value: $conductor.lfoAmount, range: 0...2)
                }
                VStack{
                    Text("Rate: \(conductor.lfoRate)")
                    SmallKnob(value: $conductor.lfoRate, range: 0.01...1)
                }
            }.frame(maxHeight: 300)
        }
            .onAppear {
            conductor.start()
                conductor.instrument.play(noteNumber: MIDINoteNumber(60), velocity: 90, channel: 0)
        }
        .onDisappear {
            conductor.instrument.stop(noteNumber: MIDINoteNumber(60), channel: 0)
            conductor.stop()
            conductor.timer?.invalidate()
        }
    }
        
}

#Preview {
    LFOView()
}
