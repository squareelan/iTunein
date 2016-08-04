//
//  TIBrowse.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import SwiftyJSON

struct TIBrowse {

	let title: String?
	let outlines: [TIOutline]!

	func anyOutlineContainsChildren() -> Bool {

		// checking if there is another level of depth
		var bool = false
		for outline in outlines {
			if outline.children != nil {
				bool = true
				break
			}
		}
		return bool
	}
}

extension TIBrowse: JsonDecodable {
    
    init?(with json: JSON) {
        guard let body = json["body"].array
            where json["head"].isExists() else {
                return nil
        }

        title = json["head"]["title"].string

        var tempOutlines = [TIOutline]()
        for item in body {
            guard let outline = TIOutline(with: item) else {
                return nil
            }
            tempOutlines.append(outline)
        }
        outlines = tempOutlines
    }
}