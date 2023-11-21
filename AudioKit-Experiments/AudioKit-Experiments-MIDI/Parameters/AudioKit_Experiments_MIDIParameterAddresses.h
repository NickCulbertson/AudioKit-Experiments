//
//  AudioKit_Experiments_MIDIParameterAddresses.h
//  AudioKit-Experiments-MIDI
//
//  Created by Nick Culbertson on 11/20/23.
//

#pragma once

#include <AudioToolbox/AUParameters.h>

#ifdef __cplusplus
namespace AudioKit_Experiments_MIDIParameterAddress {
#endif

typedef NS_ENUM(AUParameterAddress, AudioKit_Experiments_MIDIParameterAddress) {
    sendNote = 0,
    midiNoteNumber = 1
};

#ifdef __cplusplus
}
#endif
