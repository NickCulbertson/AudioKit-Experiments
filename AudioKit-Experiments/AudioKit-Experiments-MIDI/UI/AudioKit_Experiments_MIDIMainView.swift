//
//  AudioKit_Experiments_MIDIMainView.swift
//  AudioKit-Experiments-MIDI
//
//  Created by Nick Culbertson on 11/20/23.
//

import SwiftUI

struct AudioKit_Experiments_MIDIMainView: View {
    var parameterTree: ObservableAUParameterGroup
    
    var body: some View {
        VStack {
            Text("This is a basic AUv3 MIDI test. Add as a MIDI processor, hit play, and hear random notes play.").padding(5)
//            ParameterSlider(param: parameterTree.global.midiNoteNumber)
//                .padding()
//            MomentaryButton(
//                "Play note",
//                param: parameterTree.global.sendNote
//            )
        }
    }
}
