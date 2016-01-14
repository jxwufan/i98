//
//  UserProfileViewController.swift
//  i98
//
//  Created by fan wu on 12/7/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit
import p2_OAuth2
import SwiftyJSON
import SwiftHTTP
import JLToast

class UserProfileViewController: UITableViewController {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    var oauth2: OAuth2CodeGrant!
    @IBOutlet var userProfileTableView: UITableView!
    var autoLogin = false
    
    var messages: JSON!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if autoLogin {
            autoLogin = false
            loginButtonPushed(nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = [
            "client_id": "dc50f411-24b7-4e2e-814e-df9adaf4353e",
            "client_secret": "caf80982-731e-4621-b082-b6adc8f2d09c",
            "authorize_uri": "https://login.cc98.org/OAuth/Authorize",
            "token_uri": "https://login.cc98.org/OAuth/Token",
            "scope": "all",
            "redirect_uris": ["myapp://callback"],   // don't forget to register this scheme
            "keychain": true,     // if you DON'T want keychain integration
            "title": "登录"  // optional title to show in views
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMessages" {
            let dstVC = segue.destinationViewController as! MessageTableViewController
            let index = sender as! NSIndexPath
            
            dstVC.messages = self.messages
            dstVC.type = index.row
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print(indexPath)
        if (indexPath.section == 0) {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        if (indexPath.section == 1) {
            oauth2.afterAuthorizeOrFailure = { wasFailure, error in
                print(wasFailure)
                if (wasFailure == false) {
                    let req = self.oauth2.request(forURL: NSURL(string: "https://api.cc98.org/Message?filter=\(indexPath.row + 1)")!)
                    req.addValue("Application/json", forHTTPHeaderField: "Accept")
                    req.addValue("bytes=0-40", forHTTPHeaderField: "Range")
                    let session = NSURLSession.sharedSession()
                    let task = session.dataTaskWithRequest(req) { data, response, error in
                        if nil != error {
                            JLToast.makeText("获取用户信息失败！").show()
                        } else {
                            let jsonn = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
//                            JLToast.makeText("获取用户信息成功！").show()
                            self.messages = JSON(jsonn)
                            print(self.messages)
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.performSegueWithIdentifier("showMessages", sender: indexPath)
                                self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
                            })
                            self.loginButtonPushed(nil)
                        }
                    }
                    task.resume()
                }
            }
            oauth2.authorize()
        }
    }
    
    func loadUserImage(url: String) {
        do {
            let opt = try HTTP.GET(url)
            opt.start { response in
                if (response.statusCode == 200) {
//                    JLToast.makeText("获取用户头像成功！").show()
                } else {
                    JLToast.makeText("获取用户头像失败！").show()
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.userImageView.image = UIImage(data: response.data)
                    self.userImageView.setNeedsDisplay()
                    self.userProfileTableView.reloadData()
                })
            }
        } catch let error {
            JLToast.makeText("couldn't serialize the paraemeters: \(error)").show()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func loginButtonPushed(sender: UIBarButtonItem!) {
        JLToast.makeText("认证中...").show()
        oauth2.afterAuthorizeOrFailure = { wasFailure, error in
            if (wasFailure == false) {
                let req = self.oauth2.request(forURL: NSURL(string: "https://api.cc98.org/me")!)
                req.addValue("Application/json", forHTTPHeaderField: "Accept")
                let session = NSURLSession.sharedSession()
                let task = session.dataTaskWithRequest(req) { data, response, error in
                    if nil != error {
                        // something went wrong
                            JLToast.makeText("获取用户信息失败！").show()
                    }
                    else {
                        // check the response and the data
                        // you have just received data with an OAuth2-signed request!
                        let jsonn = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
        //                print(json)
//                        JLToast.makeText("获取用户信息成功！").show()
                        let json = JSON(jsonn)
                        print(json)
                        self.userNameLabel.text = json["name"].string
                        self.levelLabel.text = json["level"].string
                        self.groupLabel.text = json["groupName"].string
                        self.timeLabel.text = "最后登录时间：" + json["lastLogOnTime"].string!
                        
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.userNameLabel.setNeedsDisplay()
                            self.levelLabel.setNeedsDisplay()
                            self.groupLabel.setNeedsDisplay()
                            self.timeLabel.setNeedsDisplay()
                        })
                        
                        print(json["portraitUrl"].string)
                        
                        let url = json["portraitUrl"].string!
                        
                        if ((url as NSString).substringWithRange(NSMakeRange(0, 4)) == "http") {
                            self.loadUserImage(url)
                        } else {
                            self.loadUserImage("http://www.cc98.org/" + json["portraitUrl"].string!)
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.userProfileTableView.reloadData()
                        })
                    }
                }
                task.resume()
            }
        }
        oauth2.authorize()
    }
    @IBAction func logoutButtonPushed(sender: UIBarButtonItem) {
        oauth2.forgetTokens()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.userImageView.image = nil
            self.userNameLabel.text = ""
            self.userImageView.setNeedsDisplay()
            self.userProfileTableView.reloadData()
        })
    }

}

