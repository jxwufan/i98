//
//  ReplyEditorViewController.swift
//  i98
//
//  Created by fan wu on 12/12/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit
import Alamofire
import p2_OAuth2
import JLToast
import SwiftyJSON

class ReplyEditorViewController: UIViewController {
    var topicID: String!
    @IBOutlet weak var topicTextField: UITextField!
    var oauth2: OAuth2CodeGrant!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var contentTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let settings = [
            "client_id": "dc50f411-24b7-4e2e-814e-df9adaf4353e",
            "client_secret": "caf80982-731e-4621-b082-b6adc8f2d09c",
            "authorize_uri": "https://login.cc98.org/OAuth/Authorize",
            "token_uri": "https://login.cc98.org/OAuth/Token",
            "scope": "all",
            "redirect_uris": ["myapp://callback"],   // don't forget to register this scheme
            "keychain": true,     // if you DON'T want keychain integration
            "title": "My Service"  // optional title to show in views
            ] as OAuth2JSON            // the "as" part may or may not be needed
        
        
        oauth2 = OAuth2CodeGrant(settings: settings)
        
        oauth2.onAuthorize = { parameters in
            print("Did authorize with parameters: \(parameters)")
        }
        oauth2.onFailure = { error in        // `error` is nil on cancel
            if nil != error {
                print("Authorization went wrong: \(error.debugDescription)")
            }
        }
        
        oauth2.authConfig.authorizeEmbedded = true
        oauth2.authConfig.ui.useSafariView = false
        oauth2.authConfig.authorizeContext = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendButtonPushed(sender: AnyObject) {
        oauth2.afterAuthorizeOrFailure = { wasFailure, error in
            if (wasFailure == false) {
                var topic: String = " "
                if self.topicTextField.text != nil {
                    topic = self.topicTextField.text!
                }
                var content: String = " "
                if self.contentTextView.text != nil {
                    content = self.contentTextView.text!
                }
                print("https://api.cc98.org/Post/Topic/\(self.topicID!)")
                
                self.oauth2.request(.POST, "https://api.cc98.org/Post/Topic/\(self.topicID!)",
                    parameters: ["title": topic, "content": content],
                    encoding: .JSON).validate().responseJSON { response in
                        print(response)
                        self.activityIndicator.stopAnimating()
                        self.dismissViewControllerAnimated(true, completion: nil)
                        switch response.result {
                        case .Success:
                            JLToast.makeText("发送成功！").show()
                        case .Failure:
                            JLToast.makeText("发送失败！").show()
                        }
                }
            } else {
                JLToast.makeText("认证失败！").show()
            }
        }
        self.activityIndicator.startAnimating()
        oauth2.authorize()
    }
    @IBAction func returnButtonPushed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension OAuth2 {
    public func request(
        method: Alamofire.Method,
        _ URLString: URLStringConvertible,
        parameters: [String: AnyObject]? = nil,
        encoding: Alamofire.ParameterEncoding = .URL,
        headers: [String: String]? = nil)
        -> Alamofire.Request
    {
        var hdrs = headers
        hdrs = ["Authorization": "Bearer \(accessToken!)", "Content-Type": "application/json"]
        
        print(method)
        print(URLString)
        print(parameters)
        print(encoding)
        print(hdrs)
        return Alamofire.request(
            method,
            URLString,
            parameters: parameters,
            encoding: encoding,
            headers: hdrs)
    }
}
