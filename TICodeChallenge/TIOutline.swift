//
//  TIOutline.swift
//  iTuneIn
//
//  Created by Yongjun Yoo on 8/4/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import SwiftyJSON

enum TIOutlineType: String {
    case link
    case audio
    case undefined
}

struct TIOutline {

    struct Constants {
        static let MORE_STATIONS_KEY = "nextStations"
        static let MORE_SHOWS_KEY = "nextShows"
    }

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
}

extension TIOutline: JsonDecodable {

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