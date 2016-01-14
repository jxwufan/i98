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

class ALLTableViewController: UITableViewController {
    var refreshView: BreakOutToRefreshView!
    var currentCell: Int = 0
    var userBoardData: [Int]!
    var oauth2: OAuth2CodeGrant!
    var boardNames = [Int: String!]()
    var boardDescriptions = [Int: String!]()
    var boardPosts = [Int: String!]()
    var boardMasters = [Int: String!]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshHeight = CGFloat(100)
        refreshView = BreakOutToRefreshView(scrollView: self.tableView)
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
        var cell = tableView.dequeueReusableCellWithIdentifier("boardListCell") as! BoardListTableViewCell!
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
        performSegueWithIdentifier("showBoardInAll", sender: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController = segue.destinationViewController as! BoardViewController
        destinationViewController.title = boardNames[currentCell]
        destinationViewController.boardId = userBoardData[currentCell]
    }
    
    func getBoardNames() {
        for (var j: Int = 0; j < userBoardData.count; ++j) {
            do {
                let i = j
                let opt = try HTTP.GET("http://api.cc98.org/Board/\(userBoardData[i])", headers: ["Accept": "application/json"])
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
                        self.tableView.reloadData()
                        self.tableView.setNeedsDisplay()
                    })
                }
                
            } catch let error {
                JLToast.makeText("couldn't serialize the paraemeters: \(error)").show()
            }
        }
    }
    
    func getUserBoardData(refreshView: BreakOutToRefreshView) {
        self.userBoardData = [ 114 , 81 , 152 , 182 , 80 , 399 , 562 , 563 , 100 ,
        581 , 198 , 372 , 264 , 144 , 122 , 422 , 146 , 16 ,
        173 , 135 , 357 , 235 , 459 , 339 , 515 , 560 , 572 ,
        101 , 147 , 258 , 261 , 180 , 229 , 256 , 545 , 551 ,
        294 , 248 , 255 , 158 , 58 , 214 ]
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.getBoardNames()
            self.tableView.reloadData()
            refreshView.endRefreshing()
        })
    }
    
}


extension ALLTableViewController {
    
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

extension ALLTableViewController: BreakOutToRefreshDelegate {
    
    func refreshViewDidRefresh(refreshView: BreakOutToRefreshView) {
        // load stuff from the internet
        getUserBoardData(refreshView)
    }
    
}
