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

		let action = UIAlertAction(title: "OK".localizedString, style: .Default , handler: nil)
		alert.addAction(action)
		return alert
	}

	// create alert pop up with cancel/dismiss button and action button.
	static func create(
		with title: String?,
		     message: String?,
		     buttonTitle: String?,
		     buttonAction: () -> Void) -> UIAlertController {

		let alert = UIAlertController(
			title: title,
			message: message,
			preferredStyle: .Alert
		)

		let action = UIAlertAction(title: buttonTitle, style: .Default) { action in
			buttonAction()
		}
		
		alert.addAction(action)
		return alert
	}

	static func getGeneralNetworkErrorAlert() -> UIAlertController{
		let title = "Network Error".localizedString
		let message = "Sorry, we are having an issue. Please try again later.".localizedString
		return UIAlertController.create(with: title, message: message)
	}

	static func getGeneralAudioErrorAlert() -> UIAlertController{
		let title = "Playback Error".localizedString
		let message = "Sorry, we cannot play this audio stream. Please try again later.".localizedString
		return UIAlertController.create(with: title, message: message)
	}

	func show() {
		self.present(true, completion: nil)
	}

	func present(animated: Bool, completion: (() -> Void)?) {
		guard let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController else {
			print("There is no viewController to present alert")
			return
		}

		self.present(from: rootVC, animated: animated, completion: completion)
	}

	func present(from viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
		switch viewController {

		case is UINavigationController:
			if let vc = (viewController as! UINavigationController).visibleViewController {
				self.present(from: vc, animated: animated, completion: completion)
			}

		case is UITabBarController:
			if let vc = (viewController as! UITabBarController).selectedViewController {
				self.present(from: vc, animated: animated, completion: completion)
			}

		default:
			viewController.presentViewController(self, animated: animated, completion: completion)
		}
	}
}
