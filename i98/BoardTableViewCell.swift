//
//  BoardTableViewCell.swift
//  i98
//
//  Created by fan wu on 12/21/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit

class BoardTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var boardLabel: UILabel!
    @IBOutlet weak var replyNumberLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
