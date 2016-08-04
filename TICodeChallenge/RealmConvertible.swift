//
//  RealmConvertible.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

protocol RealmConvertible {

	associatedtype Element
	func convert() -> Element
}
