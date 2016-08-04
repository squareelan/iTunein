//
//  JsonDecodable.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import SwiftyJSON

protocol JsonDecodable {
	init?(with json: JSON)
}