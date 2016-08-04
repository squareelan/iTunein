//
//  String+Extension.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation

extension String {
	
	var localizedString: String {
		return NSLocalizedString(self, comment: "")
	}

	var urlEncoded: String {
		return self.stringByAddingPercentEncodingWithAllowedCharacters(
			NSCharacterSet.URLQueryAllowedCharacterSet()) ?? ""
	}

	var urlDecoded: String {
		return self.stringByRemovingPercentEncoding ?? ""
	}
}