// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AudioKit
import SwiftUI

class FFTModel2: ObservableObject {
    @Published var amplitudes: [Float?] = Array(repeating: nil, count: 50)
    var nodeTap: FFTTap!
    var node: Node?
    var numberOfBars: Int = 50
    var maxAmplitude: Float = 0.0
    var minAmplitude: Float = -70.0
    var referenceValueForFFT: Float = 12.0

    func updateNode(_ node: Node, fftValidBinCount: FFTValidBinCount? = nil) {
        if node !== self.node {
            self.node = node
            nodeTap = FFTTap(node, fftValidBinCount: fftValidBinCount, callbackQueue: .main) { fftData in
                self.updateAmplitudes(fftData)
            }
            nodeTap.isNormalized = false
            nodeTap.start()
        }
    }

    func updateAmplitudes(_ fftFloats: [Float]) {
        var fftData = fftFloats
        for index in 0 ..< fftData.count {
            if fftData[index].isNaN { fftData[index] = 0.0 }
        }

        var one = Float(1.0)
        var zero = Float(0.0)
        var decibelNormalizationFactor = Float(1.0 / (maxAmplitude - minAmplitude))
        var decibelNormalizationOffset = Float(-minAmplitude / (maxAmplitude - minAmplitude))

        var decibels = [Float](repeating: 0, count: fftData.count)
        vDSP_vdbcon(fftData, 1, &referenceValueForFFT, &decibels, 1, vDSP_Length(fftData.count), 0)

        vDSP_vsmsa(decibels,
                   1,
                   &decibelNormalizationFactor,
                   &decibelNormalizationOffset,
                   &decibels,
                   1,
                   vDSP_Length(decibels.count))

        vDSP_vclip(decibels, 1, &zero, &one, &decibels, 1, vDSP_Length(decibels.count))

        // swap the amplitude array
        DispatchQueue.main.async {
            self.amplitudes = decibels
        }
    }

    func mockAudioInput() {
        var mockFloats = [Float]()
        for _ in 0...65 {
            mockFloats.append(Float.random(in: 0...0.1))
        }
        updateAmplitudes(mockFloats)
        let waitTime: TimeInterval = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
            self.mockAudioInput()
        }
    }
}

public struct FFTView2: View {
    @StateObject var fft = FFTModel2()
    private var barColor: Color
    private var paddingFraction: CGFloat
    private var placeMiddle: Bool
    private var node: Node
    private var barCount: Int
    private var fftValidBinCount: FFTValidBinCount?
    private var minAmplitude: Float
    private var maxAmplitude: Float
    private let defaultBarCount: Int = 64
    private let maxBarCount: Int = 128
    private var backgroundColor: Color

    public init(_ node: Node,
                barColor: Color = Color.white.opacity(0.5),
                paddingFraction: CGFloat = 0.2,
                placeMiddle: Bool = true,
                validBinCount: FFTValidBinCount? = nil,
                barCount: Int? = nil,
                maxAmplitude: Float = -10.0,
                minAmplitude: Float = -150.0,
                backgroundColor: Color = Color.clear)
    {
        self.node = node
        self.barColor = barColor
        self.paddingFraction = paddingFraction
        self.placeMiddle = placeMiddle
        self.maxAmplitude = maxAmplitude
        self.minAmplitude = minAmplitude
        fftValidBinCount = validBinCount
        self.backgroundColor = backgroundColor

        if maxAmplitude < minAmplitude {
            fatalError("Maximum amplitude cannot be less than minimum amplitude")
        }
        if minAmplitude > 0.0 || maxAmplitude > 0.0 {
            fatalError("Amplitude values must be less than zero")
        }

        if let requestedBarCount = barCount {
            self.barCount = requestedBarCount
        } else {
            if let fftBinCount = fftValidBinCount {
                if Int(fftBinCount.rawValue) > maxBarCount - 1 {
                    self.barCount = maxBarCount
                } else {
                    self.barCount = Int(fftBinCount.rawValue)
                }
            } else {
                self.barCount = defaultBarCount
            }
        }
    }

    @State private var degress: Double = 0
    @State private var isRotating = 0.0
    @State var currentDate = Date.now
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public var body: some View {
        
        GeometryReader { geometry in
            if !placeMiddle {
                ZStack() {
                    
                    ForEach(0 ..< barCount, id: \.self) { i in
                        if i < fft.amplitudes.count {
                            if let amplitude = fft.amplitudes[i] {
                                
                                
                                AmplitudeBar2(amplitude: amplitude,
                                              barCount: barCount,
                                              barColor: barColor,
                                              paddingFraction: paddingFraction,
                                              placeMiddle: placeMiddle)
                                .rotationEffect(.degrees(Double(i)/Double(barCount)*360.0), anchor: .center)
                                
                                
                                
                            }
                        } else {
                            AmplitudeBar2(amplitude: 0.0,
                                          barCount: barCount,
                                          barColor: barColor,
                                          paddingFraction: paddingFraction,
                                          placeMiddle: placeMiddle,
                                          backgroundColor: backgroundColor)
                        }
                    }
                }.padding(geometry.size.width*0.35)
                    
            } else {
                HStack(spacing: 0) {
                    
                    ForEach(0 ..< barCount, id: \.self) { i in
                        if i < fft.amplitudes.count {
                            if let amplitude = fft.amplitudes[i] {
                                
                                //barColor opacity set by amplitude
                                AmplitudeBar2(amplitude: amplitude,
                                              barCount: barCount,
                                              barColor: barColor.opacity(Double(amplitude)*0.8),
                                              paddingFraction: paddingFraction,
                                              placeMiddle: placeMiddle)
                                
                                
                                
                            }
                        } else {
                            AmplitudeBar2(amplitude: 0.0,
                                          barCount: barCount,
                                          barColor: barColor,
                                          paddingFraction: paddingFraction,
                                          placeMiddle: placeMiddle,
                                          backgroundColor: backgroundColor)
                        }
                    }
                }.padding(20)
            }
        }.onReceive(timer) {_ in
            isRotating += 2
                    }
        .rotationEffect(.degrees(placeMiddle ? 0 :isRotating))
        .animation(.linear(duration: 1), value: isRotating)
            
        
        .onAppear {
            fft.updateNode(node, fftValidBinCount: self.fftValidBinCount)
            fft.maxAmplitude = self.maxAmplitude
            fft.minAmplitude = self.minAmplitude
        }
        .onDisappear() {
            timer.upstream.connect().cancel()
        }
        .drawingGroup() // Metal powered rendering
//        .background(backgroundColor)
    }
}

struct AmplitudeBar2: View {
    var amplitude: Float
    var barCount: Int
    var barColor: Color
    var paddingFraction: CGFloat = 0.2
    var placeMiddle: Bool = false
    var backgroundColor: Color = .black

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Dynamic black mask padded from bottom in relation to the amplitude
                VStack{
                    Spacer()
                    Rectangle()
                        .fill(barColor)
                        .cornerRadius(3.0)

                        .frame(height: geometry.size.height * CGFloat(amplitude) * 0.4)
                        .animation(.easeOut(duration: 0.15), value: amplitude)
                        .shadow(color: .white.opacity(0.5), radius: 20)
                    if placeMiddle {
                        Spacer()
                    }
                }
                .rotationEffect(.degrees(placeMiddle ? 0 : 225), anchor: .bottom)
            }.frame(maxWidth:placeMiddle ? 100 : geometry.size.width/CGFloat(barCount)*2.5)
            .padding(geometry.size.width * paddingFraction / 2)
        }
    }
}
