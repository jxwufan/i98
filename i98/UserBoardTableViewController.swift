//
//  UserBoardTableViewController.swift
//  i98
//
//  Created by fan wu on 12/11/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit
import p2_OAuth2
import JLToast
import SwiftHTTP
import SwiftyJSON

class UserBoardTableViewController: UITableViewController {
    var refreshView: BreakOutToRefreshView!
    var currentCell: Int = 0
    var userBoardData: JSON! = nil
    var oauth2: OAuth2CodeGrant!
    @IBOutlet var userBoardTableView: UITableView!
    var boardNames = [Int: String!]()
    var boardDescriptions = [Int: String!]()
    var boardPosts = [Int: String!]()
    var boardMasters = [Int: String!]()
    
    
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
        
        let refreshHeight = CGFloat(100)
        refreshView = BreakOutToRefreshView(scrollView: self.userBoardTableView)
        refreshView.delegate = self
        
        // configure the colors of the refresh view
        refreshView.scenebackgroundColor = UIColor.whiteColor()
        refreshView.paddleColor = UIColor.lightGrayColor()
        refreshView.ballColor = UIColor.blackColor()
        refreshView.blockColors = [UIColor.blackColor()]
        
        tableView.addSubview(refreshView)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard userBoardData != nil else {
            return 0
        }
        return userBoardData.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = userBoardTableView.dequeueReusableCellWithIdentifier("boardListCell") as! BoardListTableViewCell!
        if (cell == nil) {
            cell = BoardListTableViewCell()
        }
        print(userBoardData[indexPath.row])
        cell.nameLabel.text = self.boardNames[indexPath.row]
        cell.descriptionLabel.text = self.boardDescriptions[indexPath.row]
        cell.mastersLabel.text = self.boardMasters[indexPath.row]
        cell.postsLabel.text = self.boardPosts[indexPath.row]
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentCell = indexPath.row
        performSegueWithIdentifier("showBoard", sender: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController = segue.destinationViewController as! BoardViewController
        destinationViewController.title = boardNames[currentCell]
        destinationViewController.boardId = userBoardData[currentCell].int
    }
    
    func getBoardNames() {
        for (var j: Int = 0; j < userBoardData.count; ++j) {
            do {
                let i = j
            let opt = try HTTP.GET("http://api.cc98.org/Board/\(userBoardData[i].int!)", headers: ["Accept": "application/json"])
            opt.start { response in
                NSLog("\(response.statusCode)")
                if (response.statusCode == 200) {
//                    JLToast.makeText("获取成功！").show()
                    let data = JSON(data: response.data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                    self.boardNames[i] = data["name"].string
                    self.boardPosts[i] = "\(data["todayPostCount"].int!)"
                    let masters = data["masters"].arrayObject as! [String]!
                    self.boardMasters[i] = "版主： " + masters.joinWithSeparator(", ")
                    self.boardDescriptions[i] = data["description"].string
                    
                    print("获取\(i) \(self.boardNames[i])")
                    print(data)
                } else {
                    JLToast.makeText("获取失败！").show()
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.userBoardTableView.reloadData()
                    self.userBoardTableView.setNeedsDisplay()
                })
            }
                
            } catch let error {
                JLToast.makeText("couldn't serialize the paraemeters: \(error)").show()
            }
        }
    }
    
    func getUserBoardData(refreshView: BreakOutToRefreshView) {
        oauth2.afterAuthorizeOrFailure = { wasFailure, error in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                refreshView.endRefreshing()
                })
            if (wasFailure == false) {
                let req = self.oauth2.request(forURL: NSURL(string: "https://api.cc98.org/Me/CustomBoards")!)
                req.addValue("Application/json", forHTTPHeaderField: "Accept")
                let session = NSURLSession.sharedSession()
                let task = session.dataTaskWithRequest(req) { data, response, error in
                    if nil != error {
                        JLToast.makeText("获取数据失败！").show()
                    }
                    else {
                        // check the response and the data
                        // you have just received data with an OAuth2-signed request!
                        let jsonn = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
        //                print(json)
                        JLToast.makeText("获取数据成功！").show()
                        self.userBoardData = JSON(jsonn)
                        print(self.userBoardData)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.getBoardNames()
                        })
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.userBoardTableView.reloadData()
                        })
                    }
                }
                task.resume()
                
            }
        }
        oauth2.authorize()
    }

}


extension UserBoardTableViewController {
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        refreshView.scrollViewDidScroll(scrollView)
    }
    
    override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        refreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        refreshView.scrollViewWillBeginDragging(scrollView)
    }
}

extension UserBoardTableViewController: BreakOutToRefreshDelegate {
    
    func refreshViewDidRefresh(refreshView: BreakOutToRefreshView) {
        // load stuff from the internet
        getUserBoardData(refreshView)
    }
    
}
