//
//  BoardViewController.swift
//  i98
//
//  Created by fan wu on 12/11/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit
import JLToast
import SwiftHTTP
import SwiftyJSON

let boardCellsPerPage = 20

class BoardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate{
    
    var boardId: Int!
    @IBOutlet weak var boardTable: UITableView!
    @IBOutlet weak var pageLabel: UILabel!
    var pageNum: Int! = 0
    var boardData: JSON! = nil
    var cellsInPage = 0
    let textDuration = 0.2

    override func viewDidLoad() {
        super.viewDidLoad()

        if traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            // register UIViewControllerPreviewingDelegate to enable Peek & Pop
            registerForPreviewingWithDelegate(self, sourceView: boardTable)
        }else {
            // 3DTouch Unavailable : present alertController
            //            alertController = UIAlertController(title: "3DTouch Unavailable", message: "Unsupported device.", preferredStyle: .Alert)
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        getBoardData()
    }
    
    func reloadTable() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.pageLabel.text = "当前页：\(self.pageNum + 1)"
            self.pageLabel.setNeedsDisplay()
            self.boardTable.reloadData()
        })
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showBoardTopicDetail", sender: indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let index = sender as! NSIndexPath
        let destinationViewController = segue.destinationViewController as! TopicDetailTableViewController
        destinationViewController.topicID = "\(boardData[index.row]["id"].int!)"
        destinationViewController.title = boardData[index.row]["title"].string
    }
    
    func getBoardData() {
        do {
            print(boardId)
            if let id = boardId {
                let opt = try HTTP.GET("http://api.cc98.org/Topic/Board/\(boardId)", headers: ["Accept": "application/json", "Range": "bytes=\(pageNum * boardCellsPerPage)-\(pageNum * boardCellsPerPage + boardCellsPerPage - 1)"])
                opt.start { response in
                        NSLog("\(response.statusCode)")
                    if (response.statusCode == 200) {
//                        JLToast.makeText("获取数据成功！", duration: self.textDuration).show()
                    } else {
                        JLToast.makeText("获取数据失败！", duration: self.textDuration).show()
                        return
                    }
                    
                    
                    let jsonResult = try! NSJSONSerialization.JSONObjectWithData(response.data, options: NSJSONReadingOptions.AllowFragments) as! NSArray
                    
                    
                    if (jsonResult.count == 0) {
                        if (self.pageNum != 0) {
                            self.pageNum = self.pageNum - 1
                        }
                        JLToast.makeText("没有更多数据！", duration: self.textDuration).show()
                    } else {
                        self.cellsInPage = jsonResult.count
                        self.boardData = JSON(data: response.data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                        print(self.boardData)
                        self.reloadTable()
                    }
                }
            }
        } catch let error {
            JLToast.makeText("couldn't serialize the paraemeters: \(error)", duration: self.textDuration).show()
        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (boardData != nil) {
            return cellsInPage
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("boardCell", forIndexPath: indexPath) as! BoardTableViewCell
        if (boardData != nil) {
            cell.titleLabel!.text = boardData[indexPath.row]["title"].string
            cell.titleLabel!.sizeToFit()
            cell.userLabel.text = boardData[indexPath.row]["authorName"].string
            cell.userLabel.sizeToFit()
            cell.timeLabel.text = boardData[indexPath.row]["createTime"].string
            cell.replyNumberLabel.text = "\(boardData[indexPath.row]["replyCount"].int!)"
        }
        
        
        
        return cell
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func prePage(sender: AnyObject) {
        if (pageNum != 0) {
            pageNum = pageNum - 1
        } else {
            JLToast.makeText("已经到头！", duration: textDuration).show()
            return
        }
        getBoardData()
        tableViewScrollToBottom(false)
    }
    
    @IBAction func nextPage(sender: AnyObject) {
        pageNum = pageNum + 1
        getBoardData()
        self.boardTable.setContentOffset(CGPointMake(0, 0), animated: false)
    }
    
    func tableViewScrollToBottom(animated: Bool) {
        
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(time, dispatch_get_main_queue(), {
            
            let numberOfSections = self.boardTable.numberOfSections
            let numberOfRows = self.boardTable.numberOfRowsInSection(numberOfSections-1)
            
            if numberOfRows > 0 {
                let indexPath = NSIndexPath(forRow: numberOfRows-1, inSection: (numberOfSections-1))
                self.boardTable.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: animated)
            }
            
        })
    }
    
    /// Called when the user has pressed a source view in a previewing view controller (Peek).
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Get indexPath for location (CGPoint) + cell (for sourceRect)
        guard let indexPath = self.boardTable.indexPathForRowAtPoint(location),
            cell = boardTable.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Instantiate VC with Identifier (Storyboard ID)
        guard let previewViewController = storyboard?.instantiateViewControllerWithIdentifier("topicDetailVC") as? TopicDetailTableViewController else { return nil }
        
        
        let index = indexPath
        let destinationViewController = previewViewController
        
        destinationViewController.title = self.boardData[indexPath.row]["title"].string
        destinationViewController.topicID = "\(self.boardData[indexPath.row]["id"].int!)"
        
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
