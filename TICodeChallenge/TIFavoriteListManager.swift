//
//  TIFavoriteListManager.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation
import RealmSwift

struct TIFavoriteListManager: FavoriteListService {

	private let queue = dispatch_queue_create("com.codechallenge.realm", nil)

	func toggleFavorite(
		list: TIPlayList,
		completion: Result<Bool> -> Void
		) {

		getList { result in
			switch result {
			case .success(var lists):

				let matching = lists.filter {
					$0.parentNodeKey == list.parentNodeKey
				}

				if let match = matching.first {
					self.removeList(match) { result in
						switch result {
						case .success: completion(.success(true))
						case .failure(let error): completion(.failure(error))
						}
					}
				}
				else {
					// if not exist add it.
					lists.append(list)
					// persist it
					self.updateList(to: lists) { result in
						switch result {
						case .success: completion(.success(true))
						case .failure(let error): completion(.failure(error))
						}
					}
				}

			case .failure(let error):
				completion(.failure(error))
			}
		}

	}

	func getList(completion: Result<[TIPlayList]> -> Void) {

		dispatch_async(queue) {
			do {
				let realm = try Realm()
				let playLists = realm.objects(TIPlayListRealm)

				var items = [TIPlayList]()
				for playlist in playLists {
					let item = playlist.convert()
					items.append(item)
				}

				dispatch_async(dispatch_get_main_queue()) {
					completion(.success(items))
				}
			}
			catch let error as NSError {
				dispatch_async(dispatch_get_main_queue()) {
					completion(.failure(error))
				}
			}
		}
	}

	func updateList(
		to newLists: [TIPlayList],
		   completion: (Result<Bool>) -> Void
		) {

		dispatch_async(queue) {

			do {
				let realm = try Realm()

				realm.beginWrite()
				for list in newLists {
					realm.add(list.convert(), update: true)
				}
				try realm.commitWrite()

				dispatch_async(dispatch_get_main_queue()) {
					completion(.success(true))
				}
			} catch let error as NSError {
				dispatch_async(dispatch_get_main_queue()) {
					completion(.failure(error))
				}
			}
		}
	}

	func removeList(
		list: TIPlayList,
		completion: Result<Bool> -> Void
		) {

		dispatch_async(queue) {
			
			do {
				let realm = try Realm()

				if let key = list.parentNodeKey,
				   let object = realm.objects(TIPlayListRealm.self)
						.filter("parentNodeKey = '\(key)'").first {
					
					try realm.write {
						realm.delete(object)
					}

					dispatch_async(dispatch_get_main_queue()) {
						completion(.success(true))
					}
				}
				else {
					dispatch_async(dispatch_get_main_queue()) {
						// no object to delete.
						completion(.success(false))
					}
				}
			}
			catch let error as NSError {
				dispatch_async(dispatch_get_main_queue()) {
					completion(.failure(error))
				}
			}
		}
	}
}