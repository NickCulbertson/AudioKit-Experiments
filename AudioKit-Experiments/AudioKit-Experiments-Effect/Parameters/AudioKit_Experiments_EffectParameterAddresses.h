//
//  AudioKit_Experiments_EffectParameterAddresses.h
//  AudioKit-Experiments-Effect
//
//  Created by Nick Culbertson on 11/20/23.
//

#pragma once

#include <AudioToolbox/AUParameters.h>

#ifdef __cplusplus
namespace AudioKit_Experiments_EffectParameterAddress {
#endif

typedef NS_ENUM(AUParameterAddress, AudioKit_Experiments_EffectParameterAddress) {
    gain = 0
};

#ifdef __cplusplus
}
#endif
