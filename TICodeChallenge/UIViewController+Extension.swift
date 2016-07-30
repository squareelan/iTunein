//
//  UIViewController+Extension.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

protocol Identifiable {
	static var identifier: String { get }
}

extension UIViewController: Identifiable {
	static var identifier: String {
		return String(self)
	}
}

extension UIViewController {

	func startNetworkActivityIndicator(
		isInteractionEnabled enabled: Bool
	) {
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		self.view.userInteractionEnabled = enabled
	}

	func stoptNetworkActivityIndicator() {
		UIApplication.sharedApplication().networkActivityIndicatorVisible = false

		if !self.view.userInteractionEnabled {
			self.view.userInteractionEnabled = true // always enable UserInteraction
		}
	}
}