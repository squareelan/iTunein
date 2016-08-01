//
//  UIAlertController+Extension.swift
//  TuneOut
//
//  Created by Ian on 7/31/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

extension UIAlertController {

	// simple alert pop up with OK button.
	static func create(with title: String?, message: String?) -> UIAlertController{
		let alert = UIAlertController(
			title: title,
			message: message,
			preferredStyle: .Alert
		)

		let action = UIAlertAction(title: "OK", style: .Default , handler: nil)
		alert.addAction(action)
		return alert
	}

	// create alert pop up with cancel/dismiss button and action button.
	static func create(
		with title: String?,
		     message: String?,
		     buttonTitle: String?,
		     buttonAction: () -> Void) -> UIAlertController {

		let alert = UIAlertController.create(with: title, message: message)
		let action = UIAlertAction(title: buttonTitle, style: .Default) { action in
			buttonAction()
		}
		alert.addAction(action)
		return alert
	}
}
