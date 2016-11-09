//
//  ViewController.swift
//  Garage
//
//  Created by Eddie Espinal on 11/8/16.
//  Copyright © 2016 EspinalLab, LLC. All rights reserved.
//

import UIKit
import Alamofire

enum Door: Int {
    case rightDoor = 1
    case leftDoor
}

enum Status: Int {
    case closed
    case opened
    case unknown
}

struct Constants {
    static let electricImpAgentURL = "https://agent.electricimp.com/tbxu6f9JKPOM/"
    static let cameraIPAddress = "10.0.0.19"
    static let cameraAPIUsername = "admin"
    static let cameraAPIPassword = "admin"
}


class ViewController: UIViewController {

    @IBOutlet weak var rightStatusLabel: UILabel!
    @IBOutlet weak var rightDoorButton: UIButton!
    
    @IBOutlet weak var leftStatusLabel: UILabel!
    @IBOutlet weak var leftDoorButton: UIButton!
    
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    var timer: Timer!
    var statusTimer: Timer!
    
    var request: Alamofire.Request?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetUI()
        
        getGarageStatus()
        
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector:#selector(ViewController.loadCameraImage), userInfo: nil, repeats: true)
        
        statusTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector:#selector(ViewController.getGarageStatus), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadCameraImage()
    }
    
    func loadCameraImage() {
        
        // We are calling this func every 3 seconds, cancel any previuos request to prevent the app from performing slow
        if let _request = self.request {
            _request.cancel()
        }
        
        self.activityIndicatorView.startAnimating()
        
        // Get a snapshot image from the Amcrest HD IP Camera - https://amcrest.com/ip-cameras.html
        request = Alamofire.request("http://\(Constants.cameraIPAddress)/cgi-bin/snapshot.cgi").authenticate(user: Constants.cameraAPIUsername, password: Constants.cameraAPIPassword, persistence: .permanent).responseData { response in

            if let data = response.result.value {
                DispatchQueue.main.async {
                    let image = UIImage(data: data)
                    self.cameraImageView.image = image
                    
                    self.activityIndicatorView.stopAnimating()
                }
            }
        }
    }

    
    @IBAction func garageOpenButtonPressed(_ sender: AnyObject) {
        
        let door = sender.tag!
        
        let alertController = UIAlertController(title: "Garage Action", message: "Are you sure you want to open or close the garage #\(door)?", preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "NO", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            print("Cancel")
        }
        let okAction = UIAlertAction(title: "YES", style: UIAlertActionStyle.destructive) { (result : UIAlertAction) -> Void in
            print("YES")
            
            // Send the command to trigger the relay to open the garage.
            Alamofire.request("\(Constants.electricImpAgentURL)?relay=\(door)").response { response in
                
                if response.error != nil {
                    print(response.error ?? String())
                }
                
                DispatchQueue.main.async {
                    self.getGarageStatus()
                }
            }
            

        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func getGarageStatus() {
        
        Alamofire.request("\(Constants.electricImpAgentURL)?status").responseJSON { response in
            
            if let data = response.result.value {
                let JSON = data as! NSDictionary
                print(JSON)
                
                var doorStatus: Status?
                if let d1String = JSON["d1"] as? String {
                    if d1String == "OPENED" {
                        doorStatus = Status(rawValue: 1)
                    } else {
                        doorStatus = Status(rawValue: 0)
                    }
                    
                    self.updateGarageUIWithStatus(doorStatus!, doorButton: self.leftDoorButton, statusLabel: self.leftStatusLabel)
                }
                
                if let d2String = JSON["d2"] as? String {
                    if d2String == "OPENED" {
                        doorStatus = Status(rawValue: 1)
                    } else {
                        doorStatus = Status(rawValue: 0)
                    }
                    
                    self.updateGarageUIWithStatus(doorStatus!, doorButton: self.rightDoorButton, statusLabel: self.rightStatusLabel)
                }
            }
        }
    }


    func updateGarageUIWithStatus(_ status: Status, doorButton: UIButton, statusLabel: UILabel) {
        
        switch status {
        case .closed:
            statusLabel.text = "CLOSED"
            statusLabel.textColor = UIColor.gray
            
            doorButton.setImage(UIImage(named: "door_closed"), for: UIControlState.normal)
        case .opened:
            statusLabel.text = "OPENED"
            statusLabel.textColor = UIColor.orange
            doorButton.setImage(UIImage(named: "door_opened"), for: UIControlState.normal)
        case .unknown:
            statusLabel.text = "UNKNOWN"
            statusLabel.textColor = UIColor.red
            doorButton.setImage(UIImage(named: "door_unknown"), for: UIControlState.normal)
        }
    }
    
    func resetUI() {
        updateGarageUIWithStatus(.closed, doorButton: rightDoorButton, statusLabel: rightStatusLabel)
        updateGarageUIWithStatus(.closed, doorButton: leftDoorButton, statusLabel: leftStatusLabel)
    }

    // format the date using a timestamp
    
    func formatDateTime(_ timestamp: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let date = convertFromTimestamp(timestamp)
        return dateFormatter.string(from: date)
    }
    
    // Convert the timestamp string to an NSDate object

    func convertFromTimestamp(_ seconds: String) -> Date {
        let time = Int(seconds)!
        return Date(timeIntervalSince1970: TimeInterval(time))
    }
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

}

