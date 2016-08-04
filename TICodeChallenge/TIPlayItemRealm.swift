//
//  TIPlayItemRealm.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import RealmSwift

final class TIPlayItemRealm: Object {
	dynamic var element: String = ""
	dynamic var url: String = ""
	dynamic var reliability: Int = 0
	dynamic var bitrate: Double = 0
	dynamic var mediaType: String = ""
	dynamic var position: Int = 0
	dynamic var guideId: String = ""
	dynamic var isDirect: Bool = false

	let playList = LinkingObjects(
		fromType: TIPlayListRealm.self,
		property: "playItems"
	)

	override static func primaryKey() -> String? {
		return "guideId"
	}
}

extension TIPlayItemRealm: RealmConvertible {

	func convert() -> TIPlayItem {
		return TIPlayItem(
			element: element,
			url: url,
			reliability: reliability,
			bitrate: bitrate,
			mediaType: mediaType,
			position: position,
			guideId: guideId,
			isDirect: isDirect
		)
	}
}