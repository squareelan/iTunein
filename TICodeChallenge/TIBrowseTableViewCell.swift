//
//  TIBrowseTableViewCell.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

class TIBrowseTableViewCell: UITableViewCell {

	@IBOutlet var thumbNailImageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var subTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

	override func prepareForReuse() {
		thumbNailImageView.image = UIImage(named: "placeHolderImage")
	}
}
