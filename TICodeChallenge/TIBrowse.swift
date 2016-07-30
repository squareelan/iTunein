//
//  TIBrowse.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import SwiftyJSON

struct TIBrowse: JsonDeserializable {
	let title: String?
	let outlines: [TIBrowserOutline]!

	init?(with json: JSON) {
		guard let body = json["body"].array
			where json["head"].isExists() else {
			return nil
		}

		title = json["head"]["title"].string

		var tempOutlines = [TIBrowserOutline]()
		for item in body {
			guard let outline = TIBrowserOutline(with: item) else {
				return nil
			}
			tempOutlines.append(outline)
		}
		outlines = tempOutlines
	}
}

struct TIBrowserOutline: JsonDeserializable {
	let type: String?
	let text: String?
	let URL: String?
	let key: String?
	let element: String?

	init?(with json: JSON) {
		type = json["type"].string
		text = json["text"].string
		URL = json["URL"].string
		key = json["key"].string
		element = json["element"].string
	}
}