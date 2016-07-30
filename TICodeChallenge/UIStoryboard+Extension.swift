//
//  UIStoryboard+Extension.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

enum Storyboard: CustomStringConvertible {

	struct Constants {
		static let mainStoryboardName = "Main"
	}

	case main

	var description: String {
		switch self {
		case .main: return Constants.mainStoryboardName
		}
	}
}

extension UIStoryboard {

	class func mainStoryboard() -> UIStoryboard {
		return UIStoryboard(name: Storyboard.main.description, bundle: nil)
	}

	func instantiateViewController<T: UIViewController>() -> T? {

		guard let vc = instantiateViewControllerWithIdentifier(T.identifier) as? T else {
			// return nil for not matching ViewController
			return nil
		}
		return vc
	}
}
