//
//  AudioKit_Experiments_EffectMainView.swift
//  AudioKit-Experiments-Effect
//
//  Created by Nick Culbertson on 11/20/23.
//

import SwiftUI

struct AudioKit_Experiments_EffectMainView: View {
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {
        ParameterSlider(param: parameterTree.global.gain)
    }
}
