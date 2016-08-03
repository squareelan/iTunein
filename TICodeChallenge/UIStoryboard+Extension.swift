//
//  UIStoryboard+Extension.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

struct StoryboardName {
	static let main = "Main"
}

struct TabBarControllerIdentifier {
	static let rootTabBar = "rootTabBarController"
}

enum SegueIdentifier {
	static let showAudioPlayer = "showAudioPlayerSegue"
	static let showMainPage = "showMainPageSegue"
}

extension UIStoryboard {

	class func mainStoryboard() -> UIStoryboard {
		return UIStoryboard(name: StoryboardName.main, bundle: nil)
	}

	func instantiateViewController<T: UIViewController>() -> T {

		guard let vc = instantiateViewControllerWithIdentifier(T.identifier) as? T else {
			// This error is non recoverable.
			fatalError("Cannot find TableViewCell for the identifier")
		}
		return vc
	}
}
