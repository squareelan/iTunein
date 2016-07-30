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
	let outlines: [TIOutline]!

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

struct TIOutline: JsonDeserializable {

	let presetId: String?
	let guidedId: String?
	let genreId: String?
	let nowPlayingId: String?

	let type: TIOutlineType

	let text: String?
	let subtext: String?
	let image: String?
	let URL: String?
	let item: String?
	let key: String?
	let element: String?

	let currentTrack: String?
	let bitrate: Int?
	let reliability: Int?
	let format: String?

	let children: [TIOutline]?

	init?(with json: JSON) {

		presetId = json["preset_id"].string
		guidedId = json["guided_id"].string
		genreId = json["genre_id"].string
		nowPlayingId = json["now_playing_id"].string

		if let typeString = json["type"].string {
			type = TIOutlineType(rawValue: typeString) ?? TIOutlineType.undefined
		} else {
			type = TIOutlineType.undefined
		}

		text = json["text"].string
		subtext = json["subtext"].string
		image = json["image"].string
		URL = json["URL"].string
		item = json["item"].string
		key = json["key"].string
		element = json["element"].string

		currentTrack = json["currentTrack"].string
		bitrate = json["bitrate"].int
		reliability = json["reliability"].int
		format = json["format"].string

		if let jsonChildren = json["children"].array {
			var tempArray = [TIOutline]()
			for child in jsonChildren {
				// gracefully handle mapping error for children
				if let outline = TIOutline(with: child) {
					tempArray.append(outline)
				}
			}
			children = tempArray
		} else {
			children = nil
		}
	}
}

enum TIOutlineType: String {
	case link
	case audio
	case undefined
}