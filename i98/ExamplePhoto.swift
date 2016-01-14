//
//  ExamplePhoto.swift
//  NYTPhotoViewer
//
//  Created by Mark Keefe on 3/20/15.
//  Copyright (c) 2015 The New York Times. All rights reserved.
//

import UIKit
import NYTPhotoViewer

class ExamplePhoto: NSObject, NYTPhoto {

    var image: UIImage?
    var imageData: NSData?
    var placeholderImage: UIImage?
    let attributedCaptionTitle: NSAttributedString!
    let attributedCaptionSummary: NSAttributedString! = NSAttributedString(string: "", attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
    let attributedCaptionCredit: NSAttributedString! = NSAttributedString(string: "", attributes: [NSForegroundColorAttributeName: UIColor.darkGrayColor()])

    init(imageData: NSData?, attributedCaptionTitle: NSAttributedString) {
        self.imageData = imageData
        self.attributedCaptionTitle = attributedCaptionTitle
        super.init()
    }

    convenience init(attributedCaptionTitle: NSAttributedString) {
        self.init(imageData: nil, attributedCaptionTitle: attributedCaptionTitle)
    }

}
