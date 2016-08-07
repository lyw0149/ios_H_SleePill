//
//  ViewController.swift
//  iOS_H_pillow
//
//  Created by yangwoo lee on 2016. 5. 15..
//  Copyright © 2016년 yangwoo lee. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

class mainViewController: UIViewController , AVAudioRecorderDelegate{
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    
    var button : UIButton!
    var statusLabel  : UILabel!
    
    var recordState = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("main view active")
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record
                    }
                }
            }
        } catch {
            // failed to record
        }
    }
    
    
    func loadRecordingUI(){
        
        button = UIButton(type: .Custom)
        button.frame = CGRectMake(0, 0, 150, 150)
        button.center = self.view.center
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(recordButtonPressed), forControlEvents: .TouchUpInside)
        statusLabel = UILabel(frame: CGRectMake(0, 0, 100, 100))
        statusLabel.textColor = hexStringToUIColor("#43A7DF")

        statusLabel.clipsToBounds = true
        statusLabel.center.x = self.view.center.x
        statusLabel.textAlignment = NSTextAlignment.Center
        statusLabel.center.y = self.view.center.y-100
        
        view.addSubview(statusLabel)
        view.addSubview(button)
        
        
        
        if(!recordState){
            statusLabel.text = "준비"
            button.setImage(UIImage(named:"startRBtn.png"), forState: .Normal)
        }
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(cString.startIndex.advancedBy(1))
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.grayColor()
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func recordButtonPressed() {
        print("record button pressed")
        recordState = !recordState;
        if(recordState){
            statusLabel.text = "녹음 중..."
            button.setImage(UIImage(named:"stopRBtn.png"), forState: .Normal)
            startRecording()
            //start record
        }else{
            statusLabel.text = "녹음 종료 중.."
            button.setImage(UIImage(named:"startRBtn.png"), forState: .Normal)
            finishRecording(success: true)
            statusLabel.text = "서버에 업로드 중..."
            myAudioUploadRequest();
            statusLabel.text = "준비"
        }
        
        
    }
    
    func startRecording() {
//        let audioFilename = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("instagram.igo")
        let audioURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("record.m4a")
        print(audioURL)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: audioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            //recordButton.setTitle("Tap to Stop", forState: .Normal)
        } catch {
            finishRecording(success: false)
            
        }
    }
    
    func finishRecording(success success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            print ("record succeed");
            statusLabel.text = "녹음 성공"
        } else {
            statusLabel.text = "녹음 실패"
            button.setImage(UIImage(named:"startRBtn.png"), forState: .Normal)
            print ("record failed");
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }

    func myAudioUploadRequest()
    {
        
        let myUrl = NSURL(string: "https://haxmax-pillow-leeyangwoo.c9users.io/upload");
        //let myUrl = NSURL(string: "http://www.boredwear.com/utils/postImage.php");
        
        let request = NSMutableURLRequest(URL:myUrl!);
        request.HTTPMethod = "POST";
        
        //let param = []
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let data: NSData! = NSData(contentsOfURL:NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("record.m4a") )!
        
        if(data==nil)  { return; }
        
        request.HTTPBody = createBodyWithParameters("file", imageDataKey: data, boundary: boundary)
        print("-----------body = \(request.HTTPBody)")
        
        
        //myActivityIndicator.startAnimating();
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                return
            }
            
            // You can print out response object
            print("******* response = \(response)")
            
            // Print out reponse body
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("****** response data = \(responseString!)")
            
        //    _: NSError?
            
//            do{
//            var json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
//            }catch{
//            
//            }
            
            
//            dispatch_async(dispatch_get_main_queue(),{
//                self.myActivityIndicator.stopAnimating()
//                self.myImageView.image = nil;
//            });
//            
            /*
             if let parseJSON = json {
             var firstNameValue = parseJSON["firstName"] as? String
             println("firstNameValue: \(firstNameValue)")
             }
             */
            
        }
        
        task.resume()
        
    }
    
    
    func createBodyWithParameters( filePathKey: String?, imageDataKey: NSData, boundary: String) -> NSData {
        let body = NSMutableData();
        
//        if parameters != nil {
//            for (key, value) in parameters! {
//                body.appendString("--\(boundary)\r\n")
//                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
//                body.appendString("\(value)\r\n")
//            }
//        }
        
        
        let filename = "record.m4a"
        let mimetype = "audio/m4a"
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.appendData(imageDataKey)
        body.appendString("\r\n")
        
        
        
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    
//    func fileUpload(){
//        let url = NSURL(string:"")
//        let cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
//        var request = NSMutableURLRequest(URL: url!, cachePolicy: cachePolicy, timeoutInterval: 2.0)
//        request.HTTPMethod = "POST"
//        
//        // set Content-Type in HTTP header
//        let boundaryConstant = "----------V2ymHFg03esomerandomstuffhbqgZCaKO6jy";
//        let contentType = "multipart/form-data; boundary=" + boundaryConstant
//        NSURLProtocol.setProperty(contentType, forKey: "Content-Type", inRequest: request)
//        
//        // set data
//        var dataString = ""
//        let requestBodyData = (dataString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
//        request.HTTPBody = requestBodyData
//        
//        // set content length
//        //NSURLProtocol.setProperty(requestBodyData.length, forKey: "Content-Length", inRequest: request)
//        
//        var response: NSURLResponse? = nil
//        var error: NSError? = nil
//        let reply = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&error)
//        
//        let results = NSString(data:reply!, encoding:NSUTF8StringEncoding)
//        println("API Response: \(results)")
//
//    
//    }


}


extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
