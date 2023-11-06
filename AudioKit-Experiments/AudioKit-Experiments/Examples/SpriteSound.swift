import SwiftUI
import SpriteKit
import AudioKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    var conductor: SpriteSoundViewConductor?
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        self.backgroundColor = .white
        
        let plat1 = SKShapeNode(rectOf: CGSize(width: 80, height: 10))
        plat1.fillColor = .lightGray
        plat1.strokeColor = .lightGray
        plat1.zRotation = -.pi / 8
        plat1.position = CGPoint(x:490,y:540+75)
        plat1.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 10))
        plat1.physicsBody?.categoryBitMask = 2
        plat1.physicsBody?.contactTestBitMask = 2
        plat1.physicsBody?.affectedByGravity = false
        plat1.physicsBody?.isDynamic = false
        plat1.name = "platform1"
        addChild(plat1)
        
        let plat2 = SKShapeNode(rectOf: CGSize(width: 80, height: 10))
        plat2.fillColor = .lightGray
        plat2.strokeColor = .lightGray
        plat2.zRotation = .pi / 8
        plat2.position = CGPoint(x:590,y:540)
        plat2.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 10))
        plat2.physicsBody?.categoryBitMask = 2
        plat2.physicsBody?.contactTestBitMask = 2
        plat2.physicsBody?.affectedByGravity = false
        plat2.physicsBody?.isDynamic = false
        plat2.name = "platform2"
        addChild(plat2)
        
        let plat3 = SKShapeNode(rectOf: CGSize(width: 80, height: 10))
        plat3.fillColor = .lightGray
        plat3.strokeColor = .lightGray
        plat3.zRotation = -.pi / 8
        plat3.position = CGPoint(x:490,y:540-75)
        plat3.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 10))
        plat3.physicsBody?.categoryBitMask = 2
        plat3.physicsBody?.contactTestBitMask = 2
        plat3.physicsBody?.affectedByGravity = false
        plat3.physicsBody?.isDynamic = false
        plat3.name = "platform3"
        addChild(plat3)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        print(location)
        let box = SKShapeNode(circleOfRadius: 5)
        box.fillColor = .gray
        box.strokeColor = .gray
        box.position = location
        box.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        box.physicsBody?.restitution = 0.55
        box.physicsBody?.categoryBitMask = 2
        box.physicsBody?.contactTestBitMask = 2
        box.physicsBody?.affectedByGravity = true
        box.physicsBody?.isDynamic = true
        box.name = "ball"
        addChild(box)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyB.node?.name == "platform1" || contact.bodyA.node?.name == "platform1" {
            conductor!.instrument.play(noteNumber: MIDINoteNumber(60), velocity: 90, channel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.conductor!.instrument.stop(noteNumber: MIDINoteNumber(60), channel: 0)
            }
        } else if contact.bodyB.node?.name == "platform2" || contact.bodyA.node?.name == "platform2" {
            conductor!.instrument.play(noteNumber: MIDINoteNumber(64), velocity: 90, channel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.conductor!.instrument.stop(noteNumber: MIDINoteNumber(64), channel: 0)
            }
        } else if contact.bodyB.node?.name == "platform3" || contact.bodyA.node?.name == "platform3" {
            conductor!.instrument.play(noteNumber: MIDINoteNumber(67), velocity: 90, channel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.conductor!.instrument.stop(noteNumber: MIDINoteNumber(67), channel: 0)
            }
        }  else if contact.bodyB.node?.name == "ball" && contact.bodyA.node?.name == "ball" {
            //balls hit
        }else{
            contact.bodyB.node?.removeFromParent()
        }
    }
}

class SpriteSoundViewConductor: ObservableObject, HasAudioEngine {
    let engine = AudioEngine()
    @Published var instrument = MIDISampler(name: "Instrument 1")
    init() {
        engine.output = Reverb(instrument)
        try! instrument.samplerUnit.loadSoundBankInstrument(
            at: Bundle.main.url(forResource: "Sounds/PianoMuted", withExtension: "sf2")!,
            program: MIDIByte(0),
            bankMSB: MIDIByte(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: MIDIByte(kAUSampler_DefaultBankLSB)
        )
    }
}

struct SpriteSoundView: View {
    @StateObject var conductor = SpriteSoundViewConductor()
    let screenWidth  = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: 1080, height: 1080)
        scene.scaleMode = .aspectFit
        scene.conductor = conductor
        return scene
    }

    var body: some View {
        VStack {
            SpriteView(scene: scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
    }
}
