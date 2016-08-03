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

	dynamic var name: String = ""
	dynamic var playItems = [TIPlayItemRealm]()

// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }

	override static func primaryKey() -> String? {
		return "name"
	}
}

final class TIPlayItemRealm: Object {
	dynamic var element: String = ""
	dynamic var url: String = ""
	dynamic var reliability: Int = 0
	dynamic var bitrate: Int = 0
	dynamic var mediaType: String = ""
	dynamic var position: Int = 0
	dynamic var guideId: String = ""
	dynamic var isDirect: Bool = false

	override static func primaryKey() -> String? {
		return "guideId"
	}
}


