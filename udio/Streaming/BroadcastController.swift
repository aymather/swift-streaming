//
//  BroadcastController.swift
//  udio
//
//  Created by Alec Mather on 4/22/20.
//  Copyright © 2020 Alec Mather. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import NextLevel

// BroadcasterDelegate
public protocol BroadcasterDelegate: AnyObject {
    func broadcaster(_ broadcaster: BroadcastViewController, didChangeState state: LiveState)
}

// BroadcastViewController, simple user interface for handling permissions and live streaming
public class BroadcastViewController: UIViewController {
    public var broadcasterDelegate: BroadcasterDelegate?
    
    public var liveState: LiveState {
        get {
            return self._live.liveState
        }
    }
    
    internal var _previewView: UIView?
    internal var _live: Live = Live()
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?){
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder){
        fatalError("not supported")
    }
    
    public override func viewDidLoad(){
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Setup Live and Preview
        self._previewView = UIView(frame: self.view.bounds)
        if let previewView = self._previewView {
            self._live.liveDelegate = self
            self._live.previewView = previewView
            self.view.addSubview(previewView)
        }
        
        // Check permissions
        self.checkAndRequestCameraPermission()
        self.checkAndRequestMicrophonePermission()
    }
    
    private func getInterfaceOrientationMask() -> UIInterfaceOrientationMask {
        switch self.interfaceOrientation {
            case .unknown:
                return .portrait
        case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .portrait:
                return .portrait
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self._live.isRunning = true
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self._live.isRunning = false
        self._live.stop()
    }
    
}

// Status Bar

extension BroadcastViewController {
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
}

// Live Delegate

extension BroadcastViewController: LiveDelegate {
    
    public func live(_ live: Live, didChangeState state: LiveState) {
        self.broadcasterDelegate?.broadcaster(self, didChangeState: state)
    }
    
    public func live(_ live: Live, didFailWithError error: Error) {
        #if DEBUG
            print("Live encountered an error, \(error)")
        #endif
    }
    
}

// Actions

extension BroadcastViewController {
    
    // Start a live stream
    public func start(withStreamKey streamKey: String, interfaceOrientation: UIInterfaceOrientation) {
        self._live.start(withStreamKey: streamKey, interfaceOrientation)
    }
    
    // Stop Live Stream
    public func stop() {
        self._live.stop()
    }
    
}


// Permissions

extension BroadcastViewController {
    
    open func launchAppSettings(withTitle title: String = NSLocalizedString("Settings", comment: "Settings"), message: String = NSLocalizedString("Would you like to open settings?", comment: "Would you like to open settings?")) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("open", comment: "open"), style: UIAlertAction.Style.default) {
            (action: UIAlertAction) in print("UIAlertAction open completion handler")
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: UIAlertAction.Style.cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // Check and request camera permission
    open func checkAndRequestCameraPermission() {
        let status = NextLevel.authorizationStatus(forMediaType: AVMediaType.video)
        if status == .notAuthorized {
            // looks like they previously denied access, prompt to open settings
            self.launchAppSettings(withTitle: NSLocalizedString("Camera access denied", comment: "Camera access denied"),
                                   message: NSLocalizedString("Would you like to open settings?", comment: "Would you like to open settings?"))
        } else {
            NextLevel.requestAuthorization(forMediaType: AVMediaType.video, completionHandler: { (AVMediaType, NextLevelAuthorizationStatus) in
                print("NextLevel.requestAuthorization video completion handler")
            })
        }
    }
    
    // Check and request mic permission
    open func checkAndRequestMicrophonePermission() {
        let status = NextLevel.authorizationStatus(forMediaType: AVMediaType.audio)
        if status == .notAuthorized {
            // Looks like they previously denied access, prompt to open settings
            self.launchAppSettings(withTitle: NSLocalizedString("Mic Access denied", comment: "Mic access denied"), message: NSLocalizedString("Would you like to open settings?", comment: "Would you like to open settings?"))
        } else {
            NextLevel.requestAuthorization(forMediaType: AVMediaType.audio, completionHandler: { (AVMediaType, NextLevelAuthorizationStatus) in
                print("NextLevel.requestAuthorization audio completion handler")
            })
        }
    }
    
}
