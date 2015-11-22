//
//  AudioUnitEX.m
//  AudioQualityCheck
//
//  Created by YuArai on 2015/11/22.
//  Copyright © 2015年 tenifre. All rights reserved.
//

#import "AudioUnitEX.h"

@implementation AudioUnitEX

- (instancetype)init {
    self = [super init];
    
    _playing = NO;
    
    return self;
}

- (AudioStreamBasicDescription) AUCanonicalASBD:(Float64)sampleRate channel:(UInt32)channel {
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate = sampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    audioFormat.mChannelsPerFrame = channel;
    audioFormat.mBytesPerPacket = sizeof(Float32);
    audioFormat.mBytesPerFrame = sizeof(Float32);
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBitsPerChannel = 8 * sizeof(Float32);
    audioFormat.mReserved = 0;
    return audioFormat;
}

- (SInt64)prepareAudioFile:(NSURL*)fileURL
{
    // ExAudioFileの作成
    ExtAudioFileOpenURL((__bridge CFURLRef)fileURL, &_extAudioFile);
    
    // ファイルフォーマットを取得
    AudioStreamBasicDescription inputFormat;
    UInt32 size = sizeof(AudioStreamBasicDescription);
    ExtAudioFileGetProperty(_extAudioFile,
                            kExtAudioFileProperty_FileDataFormat,
                            &size,
                            &inputFormat);
    
    // Audio Unit正準形のASBDにサンプリングレート、チャンネル数を設定
    _numberOfChannels = inputFormat.mChannelsPerFrame;
    _outputFormat = [self AUCanonicalASBD:inputFormat.mSampleRate channel:inputFormat.mChannelsPerFrame];
    
    // 読み込むフォーマットをAudio Unit正準形に設定
    ExtAudioFileSetProperty(_extAudioFile,
                            kExtAudioFileProperty_ClientDataFormat,
                            sizeof(AudioStreamBasicDescription),
                            &_outputFormat);
    
    // トータルフレーム数を取得しておく
    SInt64 fileLengthFrames = 0;
    size = sizeof(SInt64);
    ExtAudioFileGetProperty(_extAudioFile,
                            kExtAudioFileProperty_FileLengthFrames,
                            &size,
                            &fileLengthFrames);
    _totalFrames = fileLengthFrames;
    
    ExtAudioFileSeek(_extAudioFile, 0);
    _currentFrame = 0;
    
    return fileLengthFrames;
}

- (OSStatus)prepareAUGraph
{
    NewAUGraph(&_graph);
    AUGraphOpen(_graph);
    
    // AUNodeの作成
    AudioComponentDescription cd;
    
    cd.componentType = kAudioUnitType_FormatConverter;
    cd.componentSubType = kAudioUnitSubType_AUConverter;
    cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    cd.componentFlags = 0;
    cd.componentFlagsMask = 0;
    AUNode converterNode;
    AUGraphAddNode(_graph, &cd, &converterNode);
    AUGraphNodeInfo(_graph, converterNode, NULL, &_converterUnit);
    
    cd.componentType = kAudioUnitType_FormatConverter;
    cd.componentSubType = kAudioUnitSubType_AUiPodTimeOther;
    cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    cd.componentFlags = 0;
    cd.componentFlagsMask = 0;
    AUNode aUiPodTimeNode;
    AUGraphAddNode(_graph, &cd, &aUiPodTimeNode);
    AUGraphNodeInfo(_graph, aUiPodTimeNode, NULL, &_aUiPodTimeUnit);
    
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    cd.componentFlags = 0;
    cd.componentFlagsMask = 0;
    AUNode remoteIONode;
    AUGraphAddNode(_graph, &cd, &remoteIONode);
    AUGraphNodeInfo(_graph, remoteIONode, NULL, &_remoteIOUnit);
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    AUGraphSetNodeInputCallback(_graph,
                                converterNode,
                                0,  // bus number
                                &callbackStruct);
    
    AudioStreamBasicDescription asbd = {0};
    UInt32 size = sizeof(asbd);
    
    AudioUnitSetProperty(_converterUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, 0,
                         &_outputFormat, size);
    
    AudioUnitSetProperty(_converterUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output, 0,
                         &_outputFormat, size);
    
    AudioUnitSetProperty(_aUiPodTimeUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output, 0,
                         &_outputFormat, size);
    
    AudioUnitSetProperty(_aUiPodTimeUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, 0,
                         &_outputFormat, size);
    
    AudioUnitSetProperty(_remoteIOUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, 0,
                         &_outputFormat, size);
    
    AUGraphConnectNodeInput(_graph,
                            converterNode, 0,
                            aUiPodTimeNode, 0);
    
    AUGraphConnectNodeInput(_graph,
                            aUiPodTimeNode, 0,
                            remoteIONode, 0);
    
    _aUiPodTimeProxy = [[AUiPodTimeProxy alloc] initWithAudioUnit:_aUiPodTimeUnit];
    
    OSStatus ret = AUGraphInitialize(_graph);
    
    return ret;
}

OSStatus renderCallback(void *inRefCon,
                        AudioUnitRenderActionFlags *ioActionFlags,
                        const AudioTimeStamp *inTimeStamp,
                        UInt32 inBusNumber,
                        UInt32 inNumberFrames,
                        AudioBufferList *ioData)
{
    OSStatus err = noErr;
    AudioUnitEX *def = (__bridge AudioUnitEX *)inRefCon;
    
    UInt32 ioNumberFrames = inNumberFrames;
    err = ExtAudioFileRead(def->_extAudioFile, &ioNumberFrames, ioData);
    
    return err;
}

- (void)start
{
    if (_graph) {
        AUGraphStart(_graph);
        AUGraphIsRunning(_graph, &_playing);
    }
}

- (void)stop
{
    if (_graph) {
        AUGraphStop(_graph);
        AUGraphIsRunning(_graph, &_playing);
    }
}

- (void)changeRate:(Float32)rate
{
    _aUiPodTimeProxy.playbackRate = rate;
}

@end
