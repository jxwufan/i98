//
//  MessageTableViewController.swift
//  i98
//
//  Created by fan wu on 12/21/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit
import SwiftyJSON

class MessageTableViewController: UITableViewController, UIViewControllerPreviewingDelegate {

    var messages: JSON!
    var type: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = true
        
        if traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
            // register UIViewControllerPreviewingDelegate to enable Peek & Pop
            registerForPreviewingWithDelegate(self, sourceView: tableView)
        }else {
            // 3DTouch Unavailable : present alertController
            //            alertController = UIAlertController(title: "3DTouch Unavailable", message: "Unsupported device.", preferredStyle: .Alert)
        }

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("messageCell", forIndexPath: indexPath) as! MessageTableViewCell

        // Configure the cell...
        if self.type == 0 {
            cell.authorLabel.text = messages[indexPath.row]["receiverName"].string
        } else {
            cell.authorLabel.text = messages[indexPath.row]["senderName"].string
        }
        cell.titleLabel.text = messages[indexPath.row]["title"].string
        
        let s = messages[indexPath.row]["content"].string
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
        cell.contentLabel.text = result
        
        cell.timeLabel.text = messages[indexPath.row]["sendTime"].string

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showMessage", sender: indexPath)
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMessage" {
            let index = sender as! NSIndexPath
            let dstVC = segue.destinationViewController as! ReplyViewController
            dstVC.content = messages[index.row]["content"].string?.stringByReplacingOccurrencesOfString("[upload=jpg]", withString: "[upload=jpg,1]").stringByReplacingOccurrencesOfString("[upload=bmp]", withString: "[upload=bmp,1]").stringByReplacingOccurrencesOfString("[upload=png]", withString: "[upload=png,1]").stringByReplacingOccurrencesOfString("[upload=jpeg]", withString: "[upload=jpeg,1]").stringByReplacingOccurrencesOfString("[img=0]", withString: "[img=1]").stringByReplacingOccurrencesOfString("[upload=gif]", withString: "[upload=gif,1]")
        }
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
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // Get indexPath for location (CGPoint) + cell (for sourceRect)
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
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
        
        destinationViewController.content = messages[index.row]["content"].string?.stringByReplacingOccurrencesOfString("[upload=jpg]", withString: "[upload=jpg,1]").stringByReplacingOccurrencesOfString("[upload=bmp]", withString: "[upload=bmp,1]").stringByReplacingOccurrencesOfString("[upload=png]", withString: "[upload=png,1]").stringByReplacingOccurrencesOfString("[upload=jpeg]", withString: "[upload=jpeg,1]").stringByReplacingOccurrencesOfString("[img=0]", withString: "[img=1]").stringByReplacingOccurrencesOfString("[upload=gif]", withString: "[upload=gif,1]")
        
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
