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
    
    @IBOutlet weak var ParamSlider1: UISlider!
    @IBOutlet weak var ParamSlider2: UISlider!
    @IBOutlet weak var ParamSlider3: UISlider!
    @IBOutlet weak var ParamSlider4: UISlider!
    var AUParam1: AUParameter?
    var AUParam2: AUParameter?
    var AUParam3: AUParameter?
    var AUParam4: AUParameter?
    private var observation: NSKeyValueObservation?

	deinit {
	}
    
    private var parameterObserverToken: AUParameterObserverToken?
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        ParamSlider1.minimumValue = 0.0
        ParamSlider1.maximumValue = 1.0
        ParamSlider1.addTarget(self, action: #selector(self.slider1ValueDidChange(_:)), for: .valueChanged)
        
        ParamSlider2.minimumValue = 0.0
        ParamSlider2.maximumValue = 1.0
        ParamSlider2.addTarget(self, action: #selector(self.slider1ValueDidChange(_:)), for: .valueChanged)
        
        ParamSlider3.minimumValue = 12.0
        ParamSlider3.maximumValue = 20000.0
        ParamSlider3.addTarget(self, action: #selector(self.slider1ValueDidChange(_:)), for: .valueChanged)
        
        ParamSlider4.minimumValue = 0.10
        ParamSlider4.maximumValue = 10.0
        ParamSlider4.addTarget(self, action: #selector(self.slider1ValueDidChange(_:)), for: .valueChanged)
        
        ParamSlider4.isHidden = true
        
        // Accessing the `audioUnit` parameter prompts the AU to be created via createAudioUnit(with:)
        guard let audioUnit = self.audioUnit else {
            return
        }
    }
    
    @objc func slider1ValueDidChange(_ sender:UISlider!)
    {
        if sender.tag == 1 {
            AUParam1?.value = self.ParamSlider1.value
        }
        if sender.tag == 2 {
            AUParam2?.value = self.ParamSlider2.value
        }
        if sender.tag == 3 {
            AUParam3?.value = self.ParamSlider3.value
        }
        if sender.tag == 4 {
            AUParam4?.value = self.ParamSlider4.value
        }
    }
    
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        
        //It's Magic!
        audioUnit = CostelloReverb(Mixer()).au
        
        guard let audioUnit = self.audioUnit else {
            log.error("Unable to create AudioKit_Experiments_EffectsAudioUnit")
            return audioUnit!
        }
        
        let paramTree = audioUnit.parameterTree
        
        
//        for param in paramTree!.allParameters {
////            param.value = param.value
//            print("this is \(param.address)")
//            AUParam1 = param
//        }
        
        AUParam1 = paramTree!.value(forKey: "balance") as? AUParameter
        AUParam2 = paramTree!.value(forKey: "feedback") as? AUParameter
        AUParam3 = paramTree!.value(forKey: "cutoffFrequency") as? AUParameter
//        AUParam4 = paramTree!.value(forKey: "ringModBalanceDef") as? AUParameter
//        ParamSlider4.isHidden = true
        
        self.observation = audioUnit.observe(\.allParameterValues, options: [.new]) { object, change in
            guard let tree = audioUnit.parameterTree else { return }
            // This insures the Audio Unit gets initial values from the host.
            
            
            for param in tree.allParameters { param.value = param.value }
        }
        
        parameterObserverToken =
        paramTree!.token(byAddingParameterObserver: { [weak self] address, value in
            guard let self = self else { return }
            
            if ([self.AUParam1?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    self.ParamSlider1.value = self.AUParam1?.value ?? 0
                }
            }
            if ([self.AUParam2?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    self.ParamSlider2.value = self.AUParam2?.value ?? 0
                }
            }
            if ([self.AUParam3?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    self.ParamSlider3.value = self.AUParam3?.value ?? 0
                }
            }
            if ([self.AUParam4?.address].contains(address)){
                DispatchQueue.main.async {
                    Log("Update GUI")
                    self.ParamSlider4.value = self.AUParam4?.value ?? 0
                }
            }
        })
        
        guard audioUnit.parameterTree != nil else {
            log.error("Unable to access AU ParameterTree")
            return audioUnit
        }
        
        return audioUnit
    }
    
    private let log = Logger(subsystem: "com.MobyPixel.AudioKit-Experiments.AudioKit-Experiments-Effects", category: "AudioUnitViewController")
}
