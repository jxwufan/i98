//
//  ViewController.swift
//  NYTPhotoViewer-Swift
//
//  Created by Mark Keefe on 3/20/15.
//  Copyright (c) 2015 The New York Times. All rights reserved.
//

import UIKit
import JLToast
import NYTPhotoViewer
import JavaScriptCore
import KCFloatingActionButton

class ReplyViewController: UIViewController, NYTPhotosViewControllerDelegate{

    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var contentTextView: UITextView!
    
    
    var photosProvider: PhotosProvider!
    private var photos: [ExamplePhoto]!
    var content: String!
    var imageUrls: [String]!
    private var manager = KCFABManager()
    
    override func viewDidAppear(animated: Bool) {
        contentTextView.setContentOffset(CGPointMake(0, 0), animated: true)
    }
    
    func updateImagesOnPhotosViewController(photosViewController: NYTPhotosViewController, afterDelayWithPhotos: [ExamplePhoto]) {
        
//        let delayTime = dispatch_time(DISPATCH_TIME_NOW, 5 * Int64(NSEC_PER_SEC))
//        
//        dispatch_after(delayTime, dispatch_get_main_queue()) {
//            for photo in self.photos {
//                if photo.image == nil {
//                    photo.image = UIImage(named: PrimaryImageName)
//                    photosViewController.updateImageForPhoto(photo)
//                }
//            }
//        }
    }
    
    @IBAction func buttonTapped(sender: UIButton!) {
        manager.getButton().close()
        if (imageUrls.count == 0) {
            JLToast.makeText("这里没有图可以显示").show()
        } else {
            let photosViewController = NYTPhotosViewController(photos: self.photos)
            photosViewController.delegate = self
            presentViewController(photosViewController, animated: true, completion: { void in
                self.manager.show()
                })

            updateImagesOnPhotosViewController(photosViewController, afterDelayWithPhotos: photos)
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
        if manager.isHidden() {
            manager.show()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.getButton().addItem("一键看图", icon: UIImage(named: "eye-icon")!, handler: { item in
            self.buttonTapped(nil)
        })
        
        contentTextView.text = content
        print(content)
        photosProvider = PhotosProvider()
        
        //TODO: add photos
        imageUrls = self.getImageUrls(content)
        
        photos = self.photosProvider.getImages(imageUrls)
        
        
        let jsLocation = NSBundle.mainBundle().pathForResource("ubb", ofType: "js")!
        var jsCode: String
        do {
            jsCode = try String(contentsOfFile: jsLocation)
        } catch {
            jsCode = ""
        }
        
//        jsCode = "var ubb = function(str) { return str;}"
        
        let context = JSContext()
        print("eval")
        print(context.evaluateScript(jsCode))
        let parse = context.objectForKeyedSubscript("ubbcode")
        print(jsCode)
        print(parse.description)
        print("Javascript")
        var string = parse.callWithArguments([content]).toString()
        print(string)
        let quo = context.objectForKeyedSubscript("ubb")
        print(content)
        print(string)
        
        let font = UIFont.systemFontOfSize(16)
        
        let attributedString = try! NSMutableAttributedString(data: string.dataUsingEncoding(NSUnicodeStringEncoding, allowLossyConversion: false)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
        attributedString.addAttributes([NSFontAttributeName: UIFont.systemFontOfSize(16)], range: NSMakeRange(0, (attributedString.string as NSString).length))
        
        contentTextView.attributedText = attributedString
        contentTextView.textColor = UIColor.darkGrayColor()
    }
    
    func getImageUrls(var content : String)-> [String] {
        var result: [String] = []
        
        content = content + "                                                                                   "
        
        do {
            
            var begin = 0
            let pattern1 = "https?://(?:[a-z0-9\\-]+\\.)+[a-z]{2,6}(?:/[^/#?]+)+\\.(?:jpg|gif|png|jpeg|bmp)"
            let regex1 = try NSRegularExpression(pattern: pattern1, options: NSRegularExpressionOptions.CaseInsensitive)
            
            var res1 = regex1.rangeOfFirstMatchInString(content, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(begin,content.characters.count))
            while (true) {
                let myNSString = content as NSString
                if (res1.location + res1.length >= content.characters.count) {
                    break;
                }
                result.append(myNSString.substringWithRange(NSMakeRange(res1.location, res1.length)))
                begin = res1.location+res1.length
                if (begin >= content.characters.count) {
                    break
                }
                
                res1 = regex1.rangeOfFirstMatchInString(content, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(begin,content.characters.count-begin))
                print(res1)
                if (res1.length == 0) {
                    break
                }
            }
        }
        catch {
            print(error)
        }
        return result
    }
    
    // MARK: - NYTPhotosViewControllerDelegate
    
    func photosViewController(photosViewController: NYTPhotosViewController!, handleActionButtonTappedForPhoto photo: NYTPhoto!) -> Bool {

        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            let shareActivityViewController = UIActivityViewController(activityItems: [photo.image!], applicationActivities: nil)
            
            shareActivityViewController.completionWithItemsHandler = {(activityType: String?, completed: Bool, items: [AnyObject]?, error: NSError?) in
                if completed {
                    photosViewController.delegate?.photosViewController!(photosViewController, actionCompletedWithActivityType: activityType!)
                }
            }

            shareActivityViewController.popoverPresentationController?.barButtonItem = photosViewController.rightBarButtonItem
            photosViewController.presentViewController(shareActivityViewController, animated: true, completion: nil)

            return true
        }
        
        return false
    }
    
    func photosViewController(photosViewController: NYTPhotosViewController!, referenceViewForPhoto photo: NYTPhoto!) -> UIView! {
//        if photo as? ExamplePhoto == photos[NoReferenceViewPhotoIndex] {
//            /** Swift 1.2
//             *  if photo as! ExamplePhoto == photos[PhotosProvider.NoReferenceViewPhotoIndex]
//             */
//            return nil
//        }
        return nil
    }
    
    func photosViewController(photosViewController: NYTPhotosViewController!, loadingViewForPhoto photo: NYTPhoto!) -> UIView! {
//        if photo as! ExamplePhoto == photos[CustomEverythingPhotoIndex] {
//            let label = UILabel()
//            label.text = "Custom Loading..."
//            label.textColor = UIColor.greenColor()
//            return label
//        }
        return nil
    }
    
    func photosViewController(photosViewController: NYTPhotosViewController!, captionViewForPhoto photo: NYTPhoto!) -> UIView! {
//        if photo as! ExamplePhoto == photos[CustomEverythingPhotoIndex] {
//            let label = UILabel()
//            label.text = "Custom Caption View"
//            label.textColor = UIColor.whiteColor()
//            label.backgroundColor = UIColor.redColor()
//            return label
//        }
        return nil
    }
    
    func photosViewController(photosViewController: NYTPhotosViewController!, didNavigateToPhoto photo: NYTPhoto!, atIndex photoIndex: UInt) {
        print("Did Navigate To Photo: \(photo) identifier: \(photoIndex)")
    }
    
    func photosViewController(photosViewController: NYTPhotosViewController!, actionCompletedWithActivityType activityType: String!) {
        print("Action Completed With Activity Type: \(activityType)")
    }

    func photosViewControllerDidDismiss(photosViewController: NYTPhotosViewController!) {
        print("Did dismiss Photo Viewer: \(photosViewController)")
    }
}
