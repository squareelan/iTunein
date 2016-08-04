//
//  TITheme.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

enum TITheme: Theme {
	case Default, light

	var backgroundColor: UIColor {
		switch self {
		case .Default:
			return UIColor.TIDefaultBackgroundColor()
		case .light:
			return UIColor.TILightBackgroundColor()
		}
	}

	var textColor: UIColor {
		switch self {
		case .Default, .light:
			return UIColor.whiteColor()
		}
	}
}


