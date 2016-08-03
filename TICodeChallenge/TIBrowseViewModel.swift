//
//  TIBrowseViewModel.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import RxSwift

enum BrowseViewError: ErrorType {
	case inavlidAudioUrl
	case undefinedType
}

final class TIBrowseViewModel {

	let networkService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

	// Core data
	let browseItem: TIBrowse
	var chosenItem: TIOutline? = nil

	var title: Variable<String?>
	var activityCount = Variable<Int>(0)
	var newBrowseItem = Variable<TIBrowse?>(nil)
	var newAudioItems = Variable<TIPlayList?>(nil)
	var errorEvent = Variable<ErrorType?>(nil)


	var numberOfSections: Int {
		// if outline item have children, use it for a row.
		// parent outline item becomes section header.
		return browseItem.anyOutlineContainsChildren() ?
			browseItem.outlines.count : 1
	}

	init(browseItem: TIBrowse, title: Variable<String?>) {
		self.browseItem = browseItem
		self.title = title
	}

	func numberOfRows(for section: Int) -> Int {
		if let children = browseItem.outlines[section].children {
			return children.count
		}
		else {
			if !browseItem.anyOutlineContainsChildren() {
				return browseItem.outlines.count
			}
			return 1
		}
	}

	func sectionTitle(for section: Int) -> String? {
		if browseItem.outlines[section].children != nil {
			return browseItem.outlines[section].text
		}
		return nil
	}

	func outline(for section: Int, row: Int) -> TIOutline {
		if let children = browseItem.outlines[section].children {
			return children[row]
		}
		else {
			if !browseItem.anyOutlineContainsChildren() {
				return browseItem.outlines[row]
			}
			return browseItem.outlines[section]
		}
	}

	// MARK: - Network Request

	func request(for section: Int, row: Int) {

		let item = outline(for: section, row: row)
		chosenItem = item     // saving for later reference

		guard let path = item.URL else {
			// Do nothing if no URL is provided.
			return
		}

		switch item.type {
		case .link:
			loadLink(with: networkService, path: path, title: item.text)

		case .audio:
			loadAudio(with: networkService, path: path)

		case .undefined:
			self.errorEvent.value = BrowseViewError.undefinedType

		}
	}

	func loadLink(
		with service: TINetworkService,
		path: String,
		title temporaryTitle: String?
		) {

		self.activityCount.value += 1

		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in

			self.activityCount.value -= 1

			switch result {
			case .success(let value):
				self.newBrowseItem.value = value

			case .failure(let error): print(error)
				self.errorEvent.value = error
			}
		}
	}

	func loadAudio(with service: TINetworkService, path: String) {

		self.activityCount.value += 1

		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIPlayList>) in

			self.activityCount.value -= 1

			switch result {
			case .success(let value):
				self.newAudioItems.value = value

			case .failure(let error): print(error)
			self.errorEvent.value = error
			}
		}
	}

	func loadImage(with urlString: String, completion: Result<UIImage> -> ()) {

		// fetch image from URL.
		networkService.imageDownloadRequest(with: urlString) { result in
			completion(result)
		}
	}
}
