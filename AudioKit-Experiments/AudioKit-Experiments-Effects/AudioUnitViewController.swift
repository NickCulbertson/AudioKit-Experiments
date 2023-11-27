//
//  AudioUnitViewController.swift
//  AudioKit-Experiments-Effects
//
//  Created by Nick Culbertson on 11/21/23.
//

import Combine
import CoreAudioKit
import os
import SwiftUI
import AudioKit
import AudioKitEX
import DunneAudioKit
import SoundpipeAudioKit
import CSoundpipeAudioKit
import CDunneAudioKit

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    
//    @IBOutlet weak var ParamSlider1: UISlider!
//    @IBOutlet weak var ParamSlider2: UISlider!
//    @IBOutlet weak var ParamSlider3: UISlider!
//    @IBOutlet weak var ParamSlider4: UISlider!
    @IBOutlet weak var Knob1: UIKitKnob!
    @IBOutlet weak var Knob2: UIKitKnob!
    @IBOutlet weak var Knob3: UIKitKnob!
    @IBOutlet weak var Knob4: UIKitKnob!
    @IBOutlet weak var Knob1Label: UILabel!
    @IBOutlet weak var Knob2Label: UILabel!
    @IBOutlet weak var Knob3Label: UILabel!
    @IBOutlet weak var Knob4Label: UILabel!
    var AUParam1: AUParameter?
    var AUParam2: AUParameter?
    var AUParam3: AUParameter?
    var AUParam4: AUParameter?
    private var observation: NSKeyValueObservation?

    var Knob1Updating = false
    var Knob2Updating = false
    var Knob3Updating = false
    var Knob4Updating = false
    
    var firstRun = true
        
	deinit {
	}
    
    private var parameterObserverToken: AUParameterObserverToken?
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        Knob1.knobValue=0.05
        Knob2.knobValue=0.0
        Knob3.knobValue=0.5
        Knob4.knobValue=0.0
        Knob1.value=0.05
        Knob2.value=0.0
        Knob3.value=0.5
        Knob4.value=0.0
        
        Knob1.callback = { value in
            self.AUParam1?.value = AUValue(self.Knob1.value * 2.0)
            DispatchQueue.main.async {
                self.Knob1Label.text = String(format: " %.2f", self.Knob1.value * 2.0)
            }
        }
        Knob1.callbackBool = { value in
            
            DispatchQueue.main.async {
                        self.Knob1Label.text = "Delay"
            }
        }
        Knob2.callback = { value in
            
            self.AUParam2?.value = AUValue(self.Knob2.value)
            DispatchQueue.main.async {
                self.Knob2Label.text = String(format: " %.2f", self.Knob2.value)
            }
        }
        Knob2.callbackBool = { value in
            DispatchQueue.main.async {
                        self.Knob2Label.text = "Feedback"
            }
        }
        Knob3.callback = { value in
            
            self.AUParam3?.value = AUValue(self.Knob3.value)
            DispatchQueue.main.async {
                self.Knob3Label.text = String(format: " %.2f", self.Knob3.value)
            }
        }
        Knob3.callbackBool = { value in
            DispatchQueue.main.async {
                        self.Knob3Label.text = "Mix"
            }
        }
        Knob4.callback = { value in
            
            self.AUParam4?.value = AUValue(self.Knob4.value)
            DispatchQueue.main.async {
                self.Knob4Label.text = String(format: " %.2f", self.Knob4.value)
            }
        }
        Knob4.callbackBool = { value in
            DispatchQueue.main.async {
                        self.Knob4Label.text = "Stereo"
            }
        }
        
        
        
        
        Knob1.presetKnobValue = Double(0.05)
        Knob3.presetKnobValue = Double(0.5)
        
        // Accessing the `audioUnit` parameter prompts the AU to be created via createAudioUnit(with:)
        guard let audioUnit = self.audioUnit else {
            return
        }
    }
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        
        //It's Magic!
        audioUnit = StereoDelay(Mixer()).au
        
        guard let audioUnit = self.audioUnit else {
            log.error("Unable to create AudioKit_Experiments_EffectsAudioUnit")
            return audioUnit!
        }
        
        let paramTree = audioUnit.parameterTree
        
        guard paramTree != nil else {
            log.error("Unable to access AU ParameterTree")
            return audioUnit
        }
        
                
        AUParam1 = paramTree!.value(forKey: "time") as? AUParameter
        AUParam2 = paramTree!.value(forKey: "feedback") as? AUParameter
        AUParam3 = paramTree!.value(forKey: "dryWetMix") as? AUParameter
        AUParam4 = paramTree!.value(forKey: "pingPong") as? AUParameter
        
        self.observation = audioUnit.observe(\.allParameterValues, options: [.new]) { object, change in
            guard let tree = audioUnit.parameterTree else { return }
            // This insures the Audio Unit gets initial values from the host.
            for param in tree.allParameters { param.value = param.value }
            
            
            DispatchQueue.main.async {
                
                let val = AUValue(self.AUParam1?.value ?? 0)
                let val2 = val * 0.5
                self.Knob1.value = Double(val2)
                
                self.Knob2.value = Double(self.AUParam2?.value ?? 0)
                
                self.Knob3.value = Double(self.AUParam3?.value ?? 0)
                
                self.Knob4.value = Double(self.AUParam4?.value ?? 0)
            }
        }
        
        parameterObserverToken =
        paramTree!.token(byAddingParameterObserver: { [weak self] address, value in
            guard let self = self else { return }
            
            if ([self.AUParam1?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    let val = AUValue(self.AUParam1?.value ?? 0)
                    let val2 = val * 0.5
                    self.Knob1.value = Double(val2)
                }
            }
            if ([self.AUParam2?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    self.Knob2.value = Double(self.AUParam2?.value ?? 0)
                }
            }
            if ([self.AUParam3?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    self.Knob3.value = Double(self.AUParam3?.value ?? 0)
                }
            }
            if ([self.AUParam4?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    self.Knob4.value = Double(self.AUParam4?.value ?? 0)
                }
            }
        })
        
        return audioUnit
    }
    
    private let log = Logger(subsystem: "com.MobyPixel.AudioKit-Experiments.AudioKit-Experiments-Effects", category: "AudioUnitViewController")
}
