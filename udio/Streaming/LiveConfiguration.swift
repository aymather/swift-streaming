//
//  LiveConfiguration.swift
//  udio
//
//  Created by Alec Mather on 4/22/20.
//  Copyright © 2020 Alec Mather. All rights reserved.
//

import Foundation
import AVFoundation
import CoreGraphics

// Audio configuration
public class LiveAudioConfiguration {
    
    /// Audio bitrate (kbps), AV dictionary key AVEncoderBitRateKey
    public var bitRate: Int = 96000
    
    /// Sample rate in hertz, AV dictionary key AVSampleRateKey
    public var sampleRate: Float64 = 44100
    
    /// Number of channels, AV dictionary key AVNumberOfChannelsKey
    public var channelsCount: Int?
    
}

// Video Configuration

public class LiveVideoConfiguration {
    
    /// Video frame rate
    public var frameRate: CMTimeScale = 30
    
    /// Max video frame rate
    public var maxFrameRate: CMTimeScale = 30
    
    // Min video frame rate
    public var minFrameRate: CMTimeScale = 15
    
    /// Video bit rate (kbps)
    public var bitRate: Int = 800000
    
    /// Max video bit rate (kbps)
    public var maxBitRate: Int = 96000
    
    /// Min video bit rate (kbps)
    public var minBitRate: Int = 600000
    
    /// Dimension for video output, AV dictionary keys AVVideoWidthKey, AVVideoHeightKey
    public var dimensions: CGSize?
    
    // Maximum interval between key frames, 1 meaning key frames only, AV dictionary key AVVideoMaxKeyFrameIntervalKey
    public var maxKeyFrameInterval: Int?
    
}

