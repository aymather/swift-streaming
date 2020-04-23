//
//  UserStreamingViewController.swift
//  udio
//
//  Created by Alec Mather on 4/22/20.
//  Copyright © 2020 Alec Mather. All rights reserved.
//

import Foundation
import UIKit
import RPCircularProgress
import Alamofire
import SwiftyJSON

class UserStreamingViewController: UIViewController {
    
    var broadcastViewController: BroadcastViewController?
    var closeButton: UIButton?
    var statusIcon: RPCircularProgress?
    var streamKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("User streaming view loaded")
        self.view.backgroundColor = .black
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Set up brodcaster
        self.broadcastViewController = BroadcastViewController()
        if let broadcastViewController = self.broadcastViewController {
            
            // Assign self as the delegate to the broadcaster
            broadcastViewController.broadcasterDelegate = self
            
            self.addChild(broadcastViewController)
            self.view.addSubview(broadcastViewController.view)
            broadcastViewController.didMove(toParent: self)
        }
        
        let margin: CGFloat = 15.0
        
        // Status icon
        self.statusIcon = RPCircularProgress()
        if let statusIcon = self.statusIcon {
            statusIcon.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
            statusIcon.roundedCorners = true
            statusIcon.thicknessRatio = 0.4
            statusIcon.trackTintColor = UIColor(hex: "#221e1f")
            statusIcon.isUserInteractionEnabled = false
            statusIcon.center = CGPoint(x: self.view.bounds.width - (statusIcon.frame.height * 0.5) - margin, y: (statusIcon.frame.width * 0.5) + margin + 75)
            self.view.addSubview(statusIcon)
        }
        
        // If a valid stream key is passed to the view controller, start the broadcast
        if let streamKey = self.streamKey {
            self.broadcastViewController?.start(withStreamKey: streamKey, interfaceOrientation: .portrait)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.statusIcon?.enableIndeterminate(false, completion: nil)
    }
    
}


extension UserStreamingViewController: BroadcasterDelegate {
    
    public func broadcaster(_ broadcaster: BroadcastViewController, didChangeState state: LiveState){
        print("Did change state, \(state.description)")
        
        switch state {
            case .ready:
                fallthrough
            case .stopped:
                // solid off-black ring
                self.statusIcon?.progressTintColor = UIColor(hex: "#fb3064")
                self.statusIcon?.updateProgress(0, animated: true, initialDelay: 0, completion: nil)
                self.statusIcon?.enableIndeterminate(false, completion: nil)
                break
            case .pending:
                fallthrough
            case .retrying:
                // spinning red ring
                self.statusIcon?.progressTintColor = UIColor(hex: "#fb3064")
                self.statusIcon?.updateProgress(0.3, animated: true, initialDelay: 0, completion: nil)
                self.statusIcon?.enableIndeterminate(true, completion: nil)
                break
            case .started:
                // solid red ring
                self.statusIcon?.progressTintColor = UIColor(hex: "#fb3064")
                self.statusIcon?.updateProgress(1.0, animated: true, initialDelay: 0, completion: nil)
                self.statusIcon?.enableIndeterminate(false, completion: nil)
                break
            case .failed:
                // solid yellow ring
                self.statusIcon?.progressTintColor = UIColor(hex: "#f7df48")
                self.statusIcon?.updateProgress(1.0, animated: true, initialDelay: 0, completion: nil)
                self.statusIcon?.enableIndeterminate(false, completion: nil)
                break
        }
    }
    
}


extension UIColor {

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) { cString.removeFirst() }

        if ((cString.count) != 6) {
          self.init(hex: "ff0000") // return red color for wrong hex input
          return
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }

}
