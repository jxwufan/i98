//
//  TopicDetailTableViewController.swift
//  
//
//  Created by fan wu on 12/7/15.
//
//

import UIKit
import JLToast
import SwiftHTTP
import SwiftyJSON
import KCFloatingActionButton

let cellsPerPage = 30

class TopicDetailTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {
    
    @IBOutlet var theView: UIView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    var topicID: String! = "4582141"
    var pageNum: Int! = 0
    var cellsInPage = cellsPerPage
    var userImages = [UIImage!](count: cellsPerPage, repeatedValue: nil)
    @IBOutlet weak var topicTableView: UITableView!
    let textDuration = 0.2
    let defaultImage = UIImage(named: "AC67FDE5-3667-4494-A1E7-78A8C29C1453")
    private var manager = KCFABManager()
    
    var topicData: JSON! = nil
    var next = true
    
    func reloadTable() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.topicTableView.reloadData()
        })
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showReply", sender: indexPath)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showReply" || segue.identifier == "peekReplyInTopic"{
        let index = sender as! NSIndexPath
        let destinationViewController = segue.destinationViewController as! ReplyViewController
        
        destinationViewController.content = topicData[index.row]["content"].string?.stringByReplacingOccurrencesOfString("[upload=jpg]", withString: "[upload=jpg,1]").stringByReplacingOccurrencesOfString("[upload=bmp]", withString: "[upload=bmp,1]").stringByReplacingOccurrencesOfString("[upload=png]", withString: "[upload=png,1]").stringByReplacingOccurrencesOfString("[upload=jpeg]", withString: "[upload=jpeg,1]").stringByReplacingOccurrencesOfString("[img=0]", withString: "[img=1]").stringByReplacingOccurrencesOfString("[upload=gif]", withString: "[upload=gif,1]")
            
        } else if segue.identifier == "showReplyEditor"{
            let dstVC = segue.destinationViewController as! ReplyEditorViewController
            dstVC.topicID = self.topicID
        }
    }
    
    func getTopicData() {
        do {
            print(topicID)
            if let id = topicID {
                let opt = try HTTP.GET("http://api.cc98.org/Post/Topic/\(id)", headers: ["Accept": "application/json", "Range": "bytes=\(pageNum * cellsPerPage)-\(pageNum * cellsPerPage + cellsPerPage - 1)"])
                print("http://api.cc98.org/Post/Topic/\(id)")
                opt.start { response in
                        NSLog("\(response.statusCode)")
                    if (response.statusCode == 200) {
//                        JLToast.makeText("获取数据成功！", duration: self.textDuration).show()
                    } else {
                        JLToast.makeText("获取数据失败！", duration: self.textDuration).show()
                        return
                    }
                    
                    
    //                print(self.topicData[0])
                    
                    let jsonResult = try! NSJSONSerialization.JSONObjectWithData(response.data, options: NSJSONReadingOptions.AllowFragments) as! NSArray
                    
                    
                    if (jsonResult.count == 0) {
                        if (self.pageNum != 0) {
                            self.pageNum = self.pageNum - 1
                        }
                        JLToast.makeText("没有更多数据！", duration: self.textDuration).show()
                    } else {
                        if self.next == true {
                            self.next = false
                            self.tableViewScroolToTop(false)
                        }
                        self.cellsInPage = jsonResult.count
                        self.topicData = JSON(data: response.data, options: NSJSONReadingOptions.AllowFragments, error: nil)
                        self.reloadTable()
                    
                        for i in 0..<cellsPerPage {
                            print("装载头像\(i)")
                            if let id = self.topicData[i]["userId"].int {
                                self.getUserImageByUserId(id, indexPath: NSIndexPath(forRow: i, inSection: 1))
                            }
                        }
                        self.reloadTable()

                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.pageNumberLabel.text = "当前页：\(self.pageNum + 1)"
                            self.pageNumberLabel.setNeedsDisplay()
                            self.pageNumberLabel.reloadInputViews()
                        })
                    }
                }
            }
        } catch let error {
            JLToast.makeText("couldn't serialize the paraemeters: \(error)", duration: self.textDuration).show()
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if !manager.isHidden() {
            manager.hide()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getTopicData()
        if manager.isHidden() {
            manager.show()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        manager._fabWindow = KCFABWindow(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height - 80)))
//        
//        manager._fabWindow.rootViewController = manager.fabController
        
        manager.getButton().addItem("回复", icon: UIImage(named: "re")!, handler: {
          item in
            self.manager.getButton().close()
            self.performSegueWithIdentifier("showReplyEditor", sender: nil)
        })

        if traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            // register UIViewControllerPreviewingDelegate to enable Peek & Pop
            registerForPreviewingWithDelegate(self, sourceView: topicTableView)
        }else {
            // 3DTouch Unavailable : present alertController
//            alertController = UIAlertController(title: "3DTouch Unavailable", message: "Unsupported device.", preferredStyle: .Alert)
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (topicData != nil) {
//            return (topicData.dictionary?.count)!
//            print("lines")
//            print(topicData.dictionary)
//            print(topicData.dictionaryValue)
//            return 10
            return cellsInPage
        } else {
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userReplyCell", forIndexPath: indexPath) as! UserReplyTableViewCell

        if (topicData != nil) {
//            cell.userNameLabel.text = "\(topicData[indexPath.row]["userId"].int!)"
            cell.userNameLabel.numberOfLines = 0
            cell.userNameLabel.text = ""
            if let name = topicData[indexPath.row]["userName"].string {
                cell.userNameLabel.text = name
            }
            cell.userNameLabel.sizeToFit()
            let s = topicData[indexPath.row]["content"].string
            var result = ""
            let space :Character = " ";
            var b = 0
            for character in (s!.characters) {
                if (character == "[") {
                    b = b + 1
                    result.append(space);
                    continue
                }
                if (character == "]") {
                    b = b - 1
                    continue
                }
                if (b == 0) {
                    result.append(character);
                }
                
            }
            cell.userReplayLabel.text = result;
            cell.userReplayLabel.sizeToFit()
            cell.timeLabel.text = topicData[indexPath.row]["time"].string
            cell.timeLabel.sizeToFit()
            cell.replyNumberLabel.text = "\(pageNum * cellsPerPage + indexPath.row + 1) 楼"
//            print(indexPath.row)
            print(topicData[indexPath.row])
            print(topicData[indexPath.row]["id"].string)
            cell.userImage.layer.borderWidth = 1
            cell.userImage.layer.masksToBounds = false
            cell.userImage.layer.borderColor = UIColor.grayColor().CGColor
            cell.userImage.layer.cornerRadius = cell.userImage.frame.height / 2
            cell.userImage.clipsToBounds = true
            cell.userImage.image = userImages[indexPath.row]
            if cell.userImage.image == nil {
                cell.userImage.image = defaultImage
            }
//            cell.userImage.setNeedsDisplay()
        }
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func prePage(sender: UIButton!) {
        if (pageNum != 0) {
            pageNum = pageNum - 1
        } else {
            JLToast.makeText("已经到头！", duration: textDuration).show()
            return
        }
        getTopicData()
        tableViewScrollToBottom(false)
    }
    
    func tableViewScroolToTop(animated: Bool) {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(time, dispatch_get_main_queue(), {
                let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                self.topicTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: animated)
            
        })
        
    }
    
    func tableViewScrollToBottom(animated: Bool) {
        
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(time, dispatch_get_main_queue(), {
            
            let numberOfSections = self.topicTableView.numberOfSections
            let numberOfRows = self.topicTableView.numberOfRowsInSection(numberOfSections-1)
            
            if numberOfRows > 0 {
                let indexPath = NSIndexPath(forRow: numberOfRows-1, inSection: (numberOfSections-1))
                self.topicTableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: animated)
            }
            
        })
    }
    
    @IBAction func nextPage(sender: UIButton!) {
        next = true
        pageNum = pageNum + 1
        getTopicData()
    }
    
    func getUserImageByUserId(id: Int, indexPath: NSIndexPath) {
        do {
            let opt = try HTTP.GET("http://api.cc98.org/User/\(id)", headers: ["Accept": "application/json"])
            opt.start { response in
                if (response.statusCode == 200) {
//                    JLToast.makeText("获取用户头像成功！").show()
                    
                    let json = JSON(try! NSJSONSerialization.JSONObjectWithData(response.data, options: NSJSONReadingOptions.AllowFragments))
                    
                    let url = json["portraitUrl"].string!
                    
                    if ((url as NSString).substringWithRange(NSMakeRange(0, 4)) == "http") {
                        self.loadUserImage(url, indexPath: indexPath)
                    } else {
                        self.loadUserImage("http://www.cc98.org/" + json["portraitUrl"].string!, indexPath: indexPath)
                    }
                } else {
                    JLToast.makeText("获取用户信息失败！").show()
                    return
                }
            }
        } catch let error {
            JLToast.makeText("couldn't serialize the paraemeters: \(error)").show()
        }
    }
    
    func loadUserImage(url: String, indexPath: NSIndexPath) {
        do {
            let opt = try HTTP.GET(url)
            opt.start { response in
                if (response.statusCode == 200) {
//                    JLToast.makeText("获取用户头像成功！").show()
                } else {
                    JLToast.makeText("获取用户头像失败！").show()
                    return
                }
                
                self.reloadTable()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    print("获取\(indexPath.row)成功")
                    let img = UIImage(data: response.data)
                    self.userImages[indexPath.row] = img
                })
            }
        } catch let error {
            JLToast.makeText("couldn't serialize the paraemeters: \(error)").show()
        }
    }
    
    /// Called when the user has pressed a source view in a previewing view controller (Peek).
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Get indexPath for location (CGPoint) + cell (for sourceRect)
        guard let indexPath = topicTableView.indexPathForRowAtPoint(location),
            cell = topicTableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Instantiate VC with Identifier (Storyboard ID)
        guard let previewViewController = storyboard?.instantiateViewControllerWithIdentifier("detailVC") as? ReplyViewController else { return nil }
        
        // Pass datas to the previewing context
//        let previewItem = DataSetted[indexPath.row]
//        
//        previewViewController.detailTitle = previewItem.title
//        previewViewController.detailAnnotation = previewItem.annotation
//        previewViewController.detailLatitude = previewItem.latitude
//        previewViewController.detailLongitude = previewItem.longitude
        
        // Preferred Content Size for Preview (CGSize)
        
        let index = indexPath
        let destinationViewController = previewViewController
        
        destinationViewController.content = topicData[index.row]["content"].string?.stringByReplacingOccurrencesOfString("[upload=jpg]", withString: "[upload=jpg,1]").stringByReplacingOccurrencesOfString("[upload=bmp]", withString: "[upload=bmp,1]").stringByReplacingOccurrencesOfString("[upload=png]", withString: "[upload=png,1]").stringByReplacingOccurrencesOfString("[upload=jpeg]", withString: "[upload=jpeg,1]").stringByReplacingOccurrencesOfString("[img=0]", withString: "[img=1]").stringByReplacingOccurrencesOfString("[upload=gif]", withString: "[upload=gif,1]")
        
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
