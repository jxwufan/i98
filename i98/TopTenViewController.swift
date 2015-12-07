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

class TopTenViewController: UITableViewController {
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
        var cell: UITableViewCell! = topTenTableView.dequeueReusableCellWithIdentifier("cell")
        if (cell == nil) {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "cell")
        }
        cell.textLabel?.text = topTenData[indexPath.row]["title"].string
        cell.detailTextLabel?.text = topTenData[indexPath.row]["authorName"].string
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentCell = indexPath.row
        performSegueWithIdentifier("showTopTenTopicDetail", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
    
    func getTopTenInfoArray(refreshView: BreakOutToRefreshView) {
        do {
            let opt = try HTTP.GET("http://api.cc98.org/topic/hot", headers: ["Accept": "application/json"])
            opt.start { response in
//                    NSLog("\(response.statusCode)")
                refreshView.endRefreshing()
                if (response.statusCode == 200) {
                    JLToast.makeText("获取成功！").show()
                } else {
                    JLToast.makeText("获取失败！").show()
                    return
                }
                self.topTenData = JSON(data: response.data, options: NSJSONReadingOptions.AllowFragments, error: nil)
//                print(self.topTenData[0])
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.topTenTableView.reloadData()
                })
            }
        } catch let error {
            JLToast.makeText("couldn't serialize the paraemeters: \(error)").show()
        }
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

