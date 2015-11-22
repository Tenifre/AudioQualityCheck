//
//  AudioIO.swift
//  AudioQualityCheck
//
//  Created by YuArai on 2015/11/22.
//  Copyright © 2015年 tenifre. All rights reserved.
//

import UIKit
import AVFoundation

class AudioIO: NSObject {
    var extAudioFile = ExtAudioFileRef()
    var outputFormat = AudioStreamBasicDescription()
    var numberOfChannels: UInt32!
    var totalFrames: Int64!
    var currentFrame: Int64!
    var remoteIOUnit = AudioUnit()
    var converterUnit = AudioUnit()
    var aUiPodTimeUnit = AudioUnit()
}
