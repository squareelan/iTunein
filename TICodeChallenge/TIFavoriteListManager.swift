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

	private let queue = dispatch_queue_create("com.ituneIn.realmBackground", nil)

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

				print("fetched")
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

				print("updated")
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

                // realm object can only be deleted, if object is
                // fetched from same Realm. So grabbing object switch
                // its primary key and delete.
				if let key = list.parentNodeKey,
				   let object = realm.objects(TIPlayListRealm.self)
						.filter("parentNodeKey = '\(key)'").first {
					
					try realm.write {
						realm.delete(object)
					}

					print("removed")
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