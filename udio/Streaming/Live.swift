//
//  Live.swift
//  udio
//
//  Created by Alec Mather on 4/22/20.
//  Copyright © 2020 Alec Mather. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire
import LFLiveKit

// Using Mux Live for testing purposes
public let MuxLiveApiProductionHostname = "api.mux.com"
public let MuxLiveRtmpProductionUrl = "rtmp://global-live.mux.com:5222/app/"

// Stream State
public enum LiveState: Int, CustomStringConvertible {
    case ready
    case pending
    case started
    case stopped
    case failed
    case retrying
    
    public var description: String {
        get {
            switch self {
                case .ready:
                    return "Ready"
                case .pending:
                    return "Pending"
                case .started:
                    return "Started"
                case . stopped:
                    return "Stopped"
                case .failed:
                    return "Failed"
                case .retrying:
                    return "Retrying"
            }
        }
    }
}

// Error Types
public enum LiveError: Error, CustomStringConvertible {
    case unknown
    case streamingInfoFailure
    case connectionFailure
    case verificationFailure
    case timeout
    
    public var code: Int {
        get {
            switch self {
                case .unknown:
                    return 0
                case .streamingInfoFailure:
                    return 202
                case .connectionFailure:
                    return 203
                case .verificationFailure:
                    return 204
                case .timeout:
                    return 205
            }
        }
    }
    
    public var description: String {
        get {
            switch self {
                case .unknown:
                    return "Unknown"
                case .streamingInfoFailure:
                    return "Failure obtaining streaming information"
                case .connectionFailure:
                    return "Connection failure"
                case .verificationFailure:
                    return "Verification failure"
                case .timeout:
                    return "Server timeout"
            }
        }
    }
}

// Live

// Delegate protocol
public protocol LiveDelegate: AnyObject {
    func live(_ live: Live, didChangeState state: LiveState)
    func live(_ live: Live, didFailWithError error: Error)
}

// Live, our streaming SDK for iOS
public class Live: NSObject {
    
    // Delegate properties
    public weak var liveDelegate: LiveDelegate?
    
    // Audio config
    public var audioConfiguration: LiveAudioConfiguration = LiveAudioConfiguration()
    
    // Video config
    public var videoConfiguration: LiveVideoConfiguration = LiveVideoConfiguration()
    
    // Network reachability statuspublic var networkReachable: Bool {
    public var networkReachable: Bool {
        get {
            return self._reachabilityStatus != .notReachable
        }
    }
    
    // Preview of stream, provide a view for rendering
    public var previewView: UIView? {
        didSet {
            if let previewView = self.previewView {
                self._liveSession?.preView = previewView
            }
        }
    }
    
    // Pause/resume local video capture
    public var isRunning: Bool = false {
        didSet {
            self._liveSession?.running = self.isRunning
        }
    }
    
    // Streaming state
    public var liveState: LiveState {
        get {
            if let lfLiveState = self._liveSession?.state {
                return LiveState(rawValue: Int(lfLiveState.rawValue)) ?? .ready
            } else {
                return .ready
            }
        }
    }
    
    // Interal vars
    private var _reachabilityManager: NetworkReachabilityManager?
    private var _reachabilityStatus: NetworkReachabilityManager.NetworkReachabilityStatus = .unknown
    private var _configuration: URLSessionConfiguration?
    private var _clientSession: SessionManager?
    private var _liveSession: LFLiveSession?
    
    // Singleton
    public static let shared = Live()
    
    // Initializer
    public override init() {
        self._reachabilityManager = NetworkReachabilityManager(host: MuxLiveApiProductionHostname)
        super.init()
    }
    
}

// Internal Setup

extension Live {
    
    internal func setupLiveSession(_ orientation: UIInterfaceOrientation) {
        let audioConfiguration = LFLiveAudioConfiguration.default()
        if let channelsCount = self.audioConfiguration.channelsCount {
            audioConfiguration?.numberOfChannels = UInt(channelsCount)
        }
        audioConfiguration?.audioBitrate = self.lfLiveKitAudioBitRate(withBitRate: self.audioConfiguration.bitRate)
        audioConfiguration?.audioSampleRate = self.lfLiveKitAudioSampleRate(withSampleRate: self.audioConfiguration.sampleRate)
        
        let videoConfiguration = LFLiveVideoConfiguration.defaultConfiguration(for: .medium3, outputImageOrientation: orientation)
        if let dimensions = self.videoConfiguration.dimensions {
            videoConfiguration?.videoSize = dimensions
        }
        videoConfiguration?.videoFrameRate = UInt(self.videoConfiguration.frameRate)
        videoConfiguration?.videoMaxFrameRate = UInt(self.videoConfiguration.maxFrameRate)
        videoConfiguration?.videoMinFrameRate = UInt(self.videoConfiguration.minFrameRate)
        videoConfiguration?.videoBitRate = UInt(self.videoConfiguration.bitRate)
        videoConfiguration?.videoMaxBitRate = UInt(self.videoConfiguration.maxBitRate)
        videoConfiguration?.videoMinBitRate = UInt(self.videoConfiguration.minBitRate)
        if let maxKeyFrameInterval = self.videoConfiguration.maxKeyFrameInterval {
            videoConfiguration?.videoMaxKeyframeInterval = UInt(maxKeyFrameInterval)
        }
        
        self._liveSession = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)!
        if let liveSession = self._liveSession {
            liveSession.delegate = self
            liveSession.captureDevicePosition = .front
            
            if let previewView = self.previewView {
                liveSession.preView = previewView
            }
        }
    }
    
}

// Internal LFLIveKit wrappers

extension Live {
    
    // audio type wrappers
    
    internal func lfLiveKitAudioBitRate(withBitRate bitRate: Int) -> LFLiveAudioBitRate {
        var lfBitRate = LFLiveAudioBitRate._Default
        if bitRate <= 32000 {
            lfBitRate = LFLiveAudioBitRate._32Kbps
        } else if bitRate <= 64000 {
            lfBitRate = LFLiveAudioBitRate._64Kbps
        } else if bitRate <= 96000 {
            lfBitRate = LFLiveAudioBitRate._96Kbps
        } else if bitRate <= 128000 {
            lfBitRate = LFLiveAudioBitRate._128Kbps
        }
        return lfBitRate
    }
    
    internal func lfLiveKitAudioSampleRate(withSampleRate sampleRate: Float64) -> LFLiveAudioSampleRate {
        var lfSampleRate = LFLiveAudioSampleRate._Default
        if sampleRate <= 16000 {
            lfSampleRate = LFLiveAudioSampleRate._16000Hz
        } else if sampleRate <= 44100 {
            lfSampleRate = LFLiveAudioSampleRate._44100Hz
        } else if sampleRate <= 48000 {
            lfSampleRate = LFLiveAudioSampleRate._48000Hz
        }
        return lfSampleRate
    }
    
}

// Actions

extension Live {
    
    // Start broadcast
    public func start(withStreamKey streamKey: String, _ orientation: UIInterfaceOrientation) {
        self.setupLiveSession(orientation)
        
        // Check that the stream key is actually a key and not a full address
        var streamUrlString = MuxLiveRtmpProductionUrl + streamKey
        if streamKey.range(of: "rtmp://") != nil {
            streamUrlString = streamKey
        }
        
        let streamInfo = LFLiveStreamInfo()
        streamInfo.url = streamUrlString
        self._liveSession?.startLive(streamInfo)
    }
    
    // Stop broadcast
    public func stop() {
        self._liveSession?.stopLive()
        self._liveSession?.delegate = nil
        self._liveSession = nil
    }
    
}

// LFLiveSessionDelegate

extension Live: LFLiveSessionDelegate {
    
    public func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
        print("Debug callback")
    }
    
    public func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
        let state = LiveState(rawValue: Int(state.rawValue)) ?? .ready
        self.liveDelegate?.live(self, didChangeState: state)
    }
    
    public func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
        var liveError = LiveError.unknown
        switch errorCode {
            case LFLiveSocketErrorCode.getStreamInfo:
                liveError = LiveError.streamingInfoFailure
                break
            case LFLiveSocketErrorCode.connectSocket:
                liveError = LiveError.streamingInfoFailure
                break
            case LFLiveSocketErrorCode.verification:
                liveError = LiveError.verificationFailure
                break
            case LFLiveSocketErrorCode.reConnectTimeOut:
                liveError = LiveError.timeout
                break
            default:
                break
        }
        self.liveDelegate?.live(self, didFailWithError: liveError)
    }
    
}
