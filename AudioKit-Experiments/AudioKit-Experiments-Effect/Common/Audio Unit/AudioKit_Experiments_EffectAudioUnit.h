//
//  AudioKit_Experiments_EffectAudioUnit.h
//  AudioKit-Experiments-Effect
//
//  Created by Nick Culbertson on 11/20/23.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioKit_Experiments_EffectAudioUnit : AUAudioUnit
- (void)setupParameterTree:(AUParameterTree *)parameterTree;
@end
