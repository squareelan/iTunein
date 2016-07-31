//
//  UITableView+Extension.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

extension UITableView {

	func dequeueResuableCell<T: UITableViewCell where T: Identifiable>(
		forIndexPath indexPath: NSIndexPath) -> T {

		guard let cell = dequeueReusableCellWithIdentifier(
			T.identifier,
			forIndexPath: indexPath) as? T else {

			// This error is non recoverable.
			fatalError("Cannot find TableViewCell for the identifier")
		}

		return cell
	}
}