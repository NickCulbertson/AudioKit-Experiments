//
//  AudioKit_Experiments_MIDIAudioUnit.mm
//  AudioKit-Experiments-MIDI
//
//  Created by Nick Culbertson on 11/20/23.
//

#import "AudioKit_Experiments_MIDIAudioUnit.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>
#import <CoreMIDI/CoreMIDI.h>

#import "AudioKit_Experiments_MIDIAUProcessHelper.hpp"
#import "AudioKit_Experiments_MIDIDSPKernel.hpp"


// Define parameter addresses.

@interface AudioKit_Experiments_MIDIAudioUnit ()

@property (nonatomic, readwrite) AUParameterTree *parameterTree;
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;
@property (nonatomic, readonly) AUAudioUnitBus *outputBus;
@end


@implementation AudioKit_Experiments_MIDIAudioUnit {
    // C++ members need to be ivars; they would be copied on access if they were properties.
    AudioKit_Experiments_MIDIDSPKernel _kernel;
    std::unique_ptr<AUProcessHelper> _processHelper;
}

@synthesize parameterTree = _parameterTree;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) { return nil; }
    
    [self setupAudioBuses];
    
    return self;
}

#pragma mark - AUAudioUnit Setup

- (void)setupAudioBuses {
    // Create the output bus first
    AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:nil];
    _outputBus.maximumChannelCount = 8;
    
    // then an array with it
    _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                             busType:AUAudioUnitBusTypeOutput
                                                              busses: @[_outputBus]];
}

- (void)setupParameterTree:(AUParameterTree *)parameterTree {
    _parameterTree = parameterTree;
    
    // Send the Parameter default values to the Kernel before setting up the parameter callbacks, so that the defaults set in the Kernel.hpp don't propagate back to the AUParameters via GetParameter
    for (AUParameter *param in _parameterTree.allParameters) {
        _kernel.setParameter(param.address, param.value);
    }
    
    [self setupParameterCallbacks];
}

- (void)setupParameterCallbacks {
    // Make a local pointer to the kernel to avoid capturing self.
    
    __block AudioKit_Experiments_MIDIDSPKernel *kernel = &_kernel;
    
    // implementorValueObserver is called when a parameter changes value.
    _parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        kernel->setParameter(param.address, value);
    };
    
    // implementorValueProvider is called when the value needs to be refreshed.
    _parameterTree.implementorValueProvider = ^(AUParameter *param) {
        return kernel->getParameter(param.address);
    };
    
    // A function to provide string representations of parameter values.
    _parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
        AUValue value = valuePtr == nil ? param.value : *valuePtr;
        
        return [NSString stringWithFormat:@"%.f", value];
    };
}

#pragma mark - AUAudioUnit Overrides

- (AUAudioFrameCount)maximumFramesToRender {
    return _kernel.maximumFramesToRender();
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
    _kernel.setMaximumFramesToRender(maximumFramesToRender);
}

// If an audio unit has input, an audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

- (void)setShouldBypassEffect:(BOOL)shouldBypassEffect {
    _kernel.setBypass(shouldBypassEffect);
}

- (BOOL)shouldBypassEffect {
    return _kernel.isBypassed();
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    [super allocateRenderResourcesAndReturnError:outError];
    
    // Set block on kernel..
    _kernel.setMIDIOutputEventBlock(self.MIDIOutputEventListBlock);
    _kernel.setMusicalContextBlock(self.musicalContextBlock);
    _kernel.initialize(_outputBus.format.sampleRate);
    _processHelper = std::make_unique<AUProcessHelper>(_kernel);
    return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    
    // Deallocate your resources.
    _kernel.deInitialize();
    
    [super deallocateRenderResources];
}

#pragma mark - MIDI

- (NSArray<NSString *>*) MIDIOutputNames {
    return @[@"midiOut"];
}

- (MIDIProtocolID)AudioUnitMIDIProtocol {
    return _kernel.AudioUnitMIDIProtocol();
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)
int previousNote = -1;
// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    /*
     Capture in locals to avoid ObjC member lookups. If "self" is captured in
     render, we're doing it wrong.
     */
    // Specify captured objects are mutable.
    __block AudioKit_Experiments_MIDIDSPKernel *kernel = &_kernel;
    __block std::unique_ptr<AUProcessHelper> &processHelper = _processHelper;
    
    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags 				*actionFlags,
                              const AudioTimeStamp       				*timestamp,
                              AVAudioFrameCount           				frameCount,
                              NSInteger                   				outputBusNumber,
                              AudioBufferList            				*outputData,
                              const AURenderEvent        				*realtimeEventListHead,
                              AURenderPullInputBlock __unsafe_unretained pullInputBlock) {
        
        if (frameCount > kernel->maximumFramesToRender()) {
            return kAudioUnitErr_TooManyFramesToProcess;
        }
        
        
        // Check Cem Olcay's AUv3 MIDI Example for more details
        // https://github.com/cemolcay/MIDISequencerAUv3/blob/fe44425dbeab679295272bfce633991facf204e3/AUv3/AUv3AudioUnit.mm#L128
        
        // Check AUv3 support
        if (self.MIDIOutputEventListBlock == NULL || self.transportStateBlock == NULL || self.musicalContextBlock == NULL) {
            return noErr;
        }
        
        // Get tempo from host
        double currentTempo;
        double currentBeat;
        if (self->_kernel.mMusicalContextBlock( &currentTempo, NULL, NULL, &currentBeat, NULL, NULL ) ) {
            int currentNote = currentBeat;
            if (currentNote != previousNote) {
                NSLog(@"beat %f", currentBeat);
                previousNote = currentNote;
                for (int i = 0; i <= 127; i++)
                {
                    self->_kernel.sendNoteOff(AUEventSampleTimeImmediate, i, kMaxVelocity);
                }
                NSArray *array = @[@50, @52, @54, @55, @57, @59, @61];
                int randomNote = [array[arc4random_uniform(6)] intValue] + 12 * arc4random_uniform(2);
                
                int randomPlay = arc4random_uniform(2);
                if (randomPlay == 1) {
                    self->_kernel.sendNoteOn(AUEventSampleTimeImmediate, randomNote, kMaxVelocity);
                }
            }
        }
        
        // Check if it is playing
        AUHostTransportStateFlags transportStateFlags;
        if (self.transportStateBlock(&transportStateFlags, NULL, NULL, NULL)) {
            // Check if transport moving
            if ((transportStateFlags & AUHostTransportStateMoving) != AUHostTransportStateMoving) {
                // Transport not moving, stop.
                for (int i = 0; i <= 127; i++)
                {
                    self->_kernel.sendNoteOff(AUEventSampleTimeImmediate, i, kMaxVelocity);
                }
                
                //Use internal sequencer?
                
                //_isPlaying = false;
                return noErr;
            } else { // Transport is moving.
                
                
            }
        } else {
            return noErr;
        }
        
        // TODO: potentially add some documentation text around rendering here?
        
        processHelper->processWithEvents(timestamp, frameCount, realtimeEventListHead);
        
        return noErr;
    };
    
}

@end

