//
//  TIPlaylist.swift
//  TuneOut
//
//  Created by Ian on 8/1/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation
import RealmSwift

final class TIPlayListRealm: Object {

	dynamic var title: String? = ""
	dynamic var subTitle: String? = ""
	dynamic var imageUrlStr: String? = ""
	dynamic var parentNodeKey: String? = ""

	let playItems = List<TIPlayItemRealm>()

	override static func primaryKey() -> String? {
		return "parentNodeKey"
	}
}

extension TIPlayListRealm: RealmConvertible {

	func convert() -> TIPlayList {
		return TIPlayList(
			title: title,
			subTitle: subTitle,
			imageUrlStr: imageUrlStr,
			parentNodeKey: parentNodeKey,
			playItems: playItems.map {
				$0.convert()
			}
		)
	}
}


