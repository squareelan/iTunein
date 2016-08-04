//
//  FavoriteListService.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation

protocol FavoriteListService {

	func toggleFavorite(
		list: TIPlayList,
		completion: Result<Bool> -> Void)

	func getList(completion: Result<[TIPlayList]> -> Void)

	func updateList(
		to newLists: [TIPlayList],
		   completion: (Result<Bool>
		) -> Void)

	func removeList(
		list: TIPlayList,
		completion: Result<Bool> -> Void)
}