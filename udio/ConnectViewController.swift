//
//  ViewController.swift
//  udio
//
//  Created by Alec Mather on 4/22/20.
//  Copyright © 2020 Alec Mather. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ConnectViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func startLiveStream(_ sender: Any) {
        print("Going Live...")
        
        // Build Request to Mux to create a new stream
        let params: [String:Any] = [
            "playback_policy": ["public"],
            "new_asset_settings": [
                "playback_policy": ["public"]
            ]
        ]
        
        // Extract stream id and stream key from env variables
        let stream_id: String = ProcessInfo.processInfo.environment["stream_id"]!
        let stream_key_secret: String = ProcessInfo.processInfo.environment["stream_key_secret"]!
        
        // Base64 encode our STREAM_ID and STREAM_KEY_SECRET for basic auth
        let base64encoded = Data("\(stream_id):\(stream_key_secret)".utf8).base64EncodedString()
        
        let headers: [String:String] = [
            "Authorization": "Basic \(base64encoded)"
        ]
        
        Alamofire.request("https://api.mux.com/video/v1/live-streams", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
        .response {
            response in
            print(response)
            do {
                
                // Extract stream key from response
                let data = try JSON(data: response.data!)
                let streamKey = data["data"]["stream_key"].string
                guard streamKey != nil else {
                    return
                }
                
                // Navigate to the users streaming view controller
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let userStreamingViewController = storyboard.instantiateViewController(identifier: "UserStreaming") as? UserStreamingViewController
                if let viewController = userStreamingViewController {
                    viewController.streamKey = streamKey
                    self.navigationController?.pushViewController(viewController, animated: true)
                }
                
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

