//
//  TIPlaylist.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import SwiftyJSON

struct TIPlayList: Equatable {

	var title: String? = ""
	var subTitle: String? = ""
	var imageUrlStr: String? = ""
	var parentNodeKey: String? = ""

	let playItems: [TIPlayItem]

	init(title: String? = "",
	     subTitle: String? = "",
	     imageUrlStr: String? = "",
	     parentNodeKey: String? = "",
	     playItems: [TIPlayItem]
		) {

		self.title = title
		self.subTitle = subTitle
		self.imageUrlStr = imageUrlStr
		self.playItems = playItems
		self.parentNodeKey = parentNodeKey
	}
}

func ==(lhs: TIPlayList, rhs: TIPlayList) -> Bool {
	return lhs.playItems == rhs.playItems &&
		lhs.title == rhs.title &&
		lhs.subTitle == rhs.subTitle &&
		lhs.imageUrlStr == rhs.imageUrlStr &&
		lhs.parentNodeKey == rhs.parentNodeKey
}

extension TIPlayList: JsonDecodable {

	init?(with json: JSON) {
		var items = [TIPlayItem]()

		for itemJson in json["body"].arrayValue {

			if let item = TIPlayItem(with: itemJson) {
				items.append(item)
			}
		}
		self.playItems = items
	}
}

extension TIPlayList: RealmConvertible {

	func convert() -> TIPlayListRealm {

		let obj = TIPlayListRealm()
		obj.title = title
		obj.subTitle = subTitle
		obj.imageUrlStr = imageUrlStr
		obj.parentNodeKey = parentNodeKey

		let items = playItems.map { $0.convert() }
		for item in items {
			obj.playItems.append(item)
		}
		return obj
	}
}
