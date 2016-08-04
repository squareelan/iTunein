//
//  TIPlayItem.swift
//  TuneOut
//
//  Created by Ian on 8/1/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import SwiftyJSON

struct TIPlayItem: Equatable {
	let element: String
	let url: String
	let reliability: Int
	let bitrate: Double
	let mediaType: String
	let position: Int
	let guideId: String
	let isDirect: Bool
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

extension TIPlayItem: JsonDecodable {

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

extension TIPlayItem: RealmConvertible {

	func convert() -> TIPlayItemRealm {

		let obj = TIPlayItemRealm()
		obj.element = element
		obj.url = url
		obj.reliability = reliability
		obj.bitrate = bitrate
		obj.mediaType = mediaType
		obj.position = position
		obj.guideId = guideId
		obj.isDirect = isDirect
		return obj
	}
}