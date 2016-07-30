//
//  HttpMethod.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

enum HTTPMethod: String, CustomStringConvertible {

	case GET
	case POST
	case PUT
	case DELETE
	case OPTIONS
	case TRACE
	case CONNECT
	case HEAD

	var description: String {
		return self.rawValue
	}
}
