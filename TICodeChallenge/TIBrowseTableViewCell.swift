//
//  TIBrowseTableViewCell.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

class TIBrowseTableViewCell: UITableViewCell {

	@IBOutlet private (set) var thumbNailImageView: UIImageView!
	@IBOutlet private (set) var titleLabel: UILabel!
	@IBOutlet private (set) var subTitleLabel: UILabel!

	override func prepareForReuse() {
		thumbNailImageView.image = UIImage(named: "placeHolderImage")
	}
}
