//
//  TIFavoriteListViewModel.swift
//  TuneOut
//
//  Created by Ian on 8/4/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

final class TIFavoriteListViewModel: NSObject {
	let favoriteListManager =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).favoriteListManager
	let networkService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

	private (set) var favoritePlayLists = Variable<[TIPlayList]>([])

	func fetchFavoriteLists(with service: FavoriteListService) {

		favoriteListManager.getList	{ result in
			switch result {
			case .success(let lists):
				self.favoritePlayLists.value = lists

			case .failure:
				let alert = UIAlertController.create(
					with: nil,
					message: "Failed to get favorite lists. Please try again".localizedString
				)
				alert.show()
			}
		}
	}

	// MARK: - Network Request -

	// MARK: Public
	func loadImage(with service: NetworkService, urlString: String, completion: Result<UIImage> -> ()) {

		// fetch image from URL.
		service.imageDownloadRequest(with: urlString) { result in
			completion(result)
		}
	}
}