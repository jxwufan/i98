//
//  BoardListTableViewCell.swift
//  i98
//
//  Created by fan wu on 12/21/15.
//  Copyright © 2015 Fan Wu. All rights reserved.
//

import UIKit

class BoardListTableViewCell: UITableViewCell {

    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var mastersLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
