//
//  UIColor+Extension.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

extension UIColor {
	
	convenience init(hex: String, alpha: CGFloat = 1.0) {
		let scanner = NSScanner(string: hex)
		var color:UInt32 = 0
		scanner.scanHexInt(&color)

		let mask = 0x00000FF
		let r = CGFloat(Float(Int(color >> 16) & mask)/255.0)
		let g = CGFloat(Float(Int(color >> 8) & mask)/255.0)
		let b = CGFloat(Float(Int(color) & mask)/255.0)

		self.init(red: r, green: g, blue: b, alpha: alpha)
	}

	static func TIDefaultBackgroundColor() -> UIColor {
		return UIColor(hex: "DB6965")
	}

	static func TILightBackgroundColor() -> UIColor {
		return UIColor(hex: "FEDDD7")
	}
}