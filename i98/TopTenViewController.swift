//
//  TopTenViewController.swift
//  i98
//
//  Created by fan wu on 12/7/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit
import JLToast
import SwiftHTTP
import SwiftyJSON

class TopTenViewController: UITableViewController, UIViewControllerPreviewingDelegate {
    var refreshView: BreakOutToRefreshView!
    var currentCell: Int = 0
    var topTenData: JSON! = nil
    @IBOutlet var topTenTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshHeight = CGFloat(100)
        refreshView = BreakOutToRefreshView(scrollView: tableView)
        refreshView.delegate = self
        
        // configure the colors of the refresh view
        refreshView.scenebackgroundColor = UIColor.whiteColor()
        refreshView.paddleColor = UIColor.lightGrayColor()
        refreshView.ballColor = UIColor.blackColor()
        refreshView.blockColors = [UIColor.blackColor()]
        
        tableView.addSubview(refreshView)
        
        if traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            // register UIViewControllerPreviewingDelegate to enable Peek & Pop
            registerForPreviewingWithDelegate(self, sourceView: tableView)
        }else {
            // 3DTouch Unavailable : present alertController
            //            alertController = UIAlertController(title: "3DTouch Unavailable", message: "Unsupported device.", preferredStyle: .Alert)
        }
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard topTenData != nil else {
            return 0
        }
        return topTenData.count
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = topTenTableView.dequeueReusableCellWithIdentifier("cell") as! BoardTableViewCell!
        if (cell == nil) {
            cell = BoardTableViewCell(style: .Subtitle, reuseIdentifier: "cell")
        }
        
        cell.titleLabel.text = topTenData[indexPath.row]["title"].string
        cell.titleLabel.sizeToFit()
        cell.boardLabel.text = topTenData[indexPath.row]["boardName"].string
        cell.boardLabel.sizeToFit()
        cell.userLabel.text = topTenData[indexPath.row]["authorName"].string
        cell.userLabel.sizeToFit()
        cell.timeLabel.text = topTenData[indexPath.row]["createTime"].string
        cell.timeLabel.sizeToFit()
        cell.replyNumberLabel.text = "\(topTenData[indexPath.row]["replyCount"].int!)"
        cell.replyNumberLabel.sizeToFit()
        
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentCell = indexPath.row
        performSegueWithIdentifier("showTopTenTopicDetail", sender: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
//    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        let height = self.calculateHeightForString(topTenData[indexPath.row]["title"].string!)
//        return height + 70
//    }
    
    func calculateHeightForString(inString:String) -> CGFloat
    {
        var messageString = inString
        var attributes = ["UIFont": UIFont.systemFontOfSize(15.0)]
        let attrString:NSAttributedString? = NSAttributedString(string: messageString, attributes: attributes)
        var rect:CGRect = attrString!.boundingRectWithSize(CGSizeMake(300.0,CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context:nil )//hear u will get nearer height not the exact value
        var requredSize:CGRect = rect
        return requredSize.height  //to include button's in your tableview
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController = segue.destinationViewController as! TopicDetailTableViewController
        print(topTenData[currentCell])
        destinationViewController.title = self.topTenData[currentCell]["title"].string
        destinationViewController.topicID = "\(self.topTenData[currentCell]["id"].int!)"
    }
    
    func getTopTenInfoArray(refreshView: BreakOutToRefreshView) {
        do {
            let opt = try HTTP.GET("http://api.cc98.org/topic/hot", headers: ["Accept": "application/json"])
            opt.start { response in
                NSLog("\(response.statusCode)")
                if (response.statusCode == 200) {
                    JLToast.makeText("获取成功！").show()
                    self.topTenData = JSON(data: response.data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                } else {
                    JLToast.makeText("获取失败！").show()
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.topTenTableView.reloadData()
                    refreshView.endRefreshing()
                    self.topTenTableView.setNeedsDisplay()
                })
            }
        } catch let error {
            JLToast.makeText("couldn't serialize the paraemeters: \(error)").show()
        }
    }
    
    /// Called when the user has pressed a source view in a previewing view controller (Peek).
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Get indexPath for location (CGPoint) + cell (for sourceRect)
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Instantiate VC with Identifier (Storyboard ID)
        guard let previewViewController = storyboard?.instantiateViewControllerWithIdentifier("topicDetailVC") as? TopicDetailTableViewController else { return nil }
        
        
        let index = indexPath
        let destinationViewController = previewViewController
        
        print(topTenData[currentCell])
        destinationViewController.title = self.topTenData[indexPath.row]["title"].string
        destinationViewController.topicID = "\(self.topTenData[indexPath.row]["id"].int!)"
        
        previewViewController.preferredContentSize = CGSize(width: 0.0, height: 0.0)
        
        // Current context Source.
        previewingContext.sourceRect = cell.frame
        
        return previewViewController
    }
    /// Called to let you prepare the presentation of a commit (Pop).
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        // Presents viewControllerToCommit in a primary context
        showViewController(viewControllerToCommit, sender: self)
    }
    

}


extension TopTenViewController {
    
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

extension TopTenViewController: BreakOutToRefreshDelegate {
    
    func refreshViewDidRefresh(refreshView: BreakOutToRefreshView) {
        // load stuff from the internet
        getTopTenInfoArray(refreshView)
    }
    
}

