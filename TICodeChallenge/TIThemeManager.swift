//
//  TIThemeManager.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

struct TIThemeManager {

	static func applyTheme(theme: Theme) {
		UIApplication.sharedApplication().delegate?.window??.tintColor = theme.backgroundColor
		UINavigationBar.appearance().barTintColor = theme.backgroundColor
		UINavigationBar.appearance().tintColor = theme.textColor
		UINavigationBar.appearance().titleTextAttributes = [
			NSForegroundColorAttributeName:theme.textColor
		]

//		UITabBar.appearance().barTintColor = theme.backgroundColor
		UITabBar.appearance().tintColor = theme.backgroundColor
	}
}
