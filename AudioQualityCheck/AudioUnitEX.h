//
//  AudioUnitEX.h
//  AudioQualityCheck
//
//  Created by YuArai on 2015/11/22.
//  Copyright © 2015年 tenifre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AUiPodTimeProxy.h"

@interface AudioUnitEX : NSObject {
    ExtAudioFileRef _extAudioFile;
    AudioStreamBasicDescription _outputFormat;
    UInt32 _numberOfChannels;
    SInt64 _totalFrames;
    SInt64 _currentFrame;
    
    AUGraph _graph;
    AudioUnit _remoteIOUnit;
    AudioUnit _converterUnit;
    AudioUnit _aUiPodTimeUnit;
    
    AUiPodTimeProxy *_aUiPodTimeProxy;
}

@property (nonatomic) Boolean playing;

- (SInt64)prepareAudioFile:(NSURL*)fileURL;
- (OSStatus)prepareAUGraph;
- (void)start;
- (void)stop;
- (void)changeRate:(Float32)rate;

@end
