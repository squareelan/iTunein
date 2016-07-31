//
//  Identifiable.swift
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

extension UITableViewCell: Identifiable {
	static var identifier: String {
		return String(self)
	}
}
