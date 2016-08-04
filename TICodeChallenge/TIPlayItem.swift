//
//  TIPlayItem.swift
//  TuneOut
//
//  Created by Ian on 8/1/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import SwiftyJSON

struct TIPlayList: JsonDeserializable, Equatable {
	var title: String? = ""
	var imageUrlStr: String? = ""
	let playItems: [TIPlayItem]

	init?(with json: JSON) {
		var items = [TIPlayItem]()

		for itemJson in json["body"].arrayValue {

			if let item = TIPlayItem(with: itemJson) {
				items.append(item)
			}
		}
		self.playItems = items
	}

	init(title: String? = "", imageUrlStr: String? = "", playItems: [TIPlayItem]) {
		self.title = title
		self.imageUrlStr = imageUrlStr
		self.playItems = playItems
	}
}

func ==(lhs: TIPlayList, rhs: TIPlayList) -> Bool {
	return lhs.playItems == rhs.playItems
}


struct TIPlayItem: JsonDeserializable, Equatable {
	let element: String
	let url: String
	let reliability: Int
	let bitrate: Double
	let mediaType: String
	let position: Int
	let guideId: String
	let isDirect: Bool

	init?(with json: JSON) {
		self.element = json["element"].stringValue
		self.url = json["url"].stringValue
		self.reliability = json["reliability"].intValue
		self.bitrate = json["bitrate"].doubleValue
		self.mediaType = json["media_type"].stringValue
		self.position = json["position"].intValue
		self.guideId = json["guide_id"].stringValue
		self.isDirect = json["is_direct"].boolValue
	}
}

func ==(lhs: TIPlayItem, rhs: TIPlayItem) -> Bool {
	return lhs.element == rhs.element &&
		lhs.url == rhs.url &&
		lhs.reliability == rhs.reliability &&
		lhs.bitrate == rhs.bitrate &&
		lhs.mediaType == rhs.mediaType &&
		lhs.position == rhs.position &&
		lhs.guideId == rhs.guideId &&
		lhs.isDirect == rhs.isDirect
}
