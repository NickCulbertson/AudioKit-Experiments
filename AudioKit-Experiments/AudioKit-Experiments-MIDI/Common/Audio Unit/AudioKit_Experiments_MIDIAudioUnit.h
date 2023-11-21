//
//  AudioKit_Experiments_MIDIAudioUnit.h
//  AudioKit-Experiments-MIDI
//
//  Created by Nick Culbertson on 11/20/23.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioKit_Experiments_MIDIAudioUnit : AUAudioUnit
- (void)setupParameterTree:(AUParameterTree *)parameterTree;
@end
