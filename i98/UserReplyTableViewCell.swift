//
//  userReplyTableViewCell.swift
//  i98
//
//  Created by fan wu on 12/8/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit

class UserReplyTableViewCell: UITableViewCell {
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var replyNumberLabel: UILabel!
    @IBOutlet weak var userReplayLabel: UILabel!

    @IBOutlet weak var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
