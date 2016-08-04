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

    // later change this to be injected for testibility, and more abstraction.
	let networkService =
        (UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

	// Core data
	let browseItem: TIBrowse
	var chosenItem: TIOutline? = nil

	var title: Variable<String?>
	private (set) var activityCount = Variable<Int>(0)
	private (set) var newBrowseItem = Variable<TIBrowse?>(nil)
	private (set) var newAudioItems = Variable<TIPlayList?>(nil)
	private (set) var errorEvent = Variable<ErrorType?>(nil)

	var numberOfSections: Int {
		// if outline item have children, use it for a row.
		// parent outline item becomes section header.
		return browseItem.anyOutlineContainsChildren() ?
			browseItem.outlines.count : 1
	}

    // MARK: - Initializer
	init(browseItem: TIBrowse, title: Variable<String?>) {
		self.browseItem = browseItem
		self.title = title
	}

    // MARK: - Public Method
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

	// MARK: - Network Request -

	// MARK: Public
    func loadImage(
        with service: NetworkService,
             urlString: String,
             completion: Result<UIImage> -> ()
        ) {

		// fetch image from URL.
		service.imageDownloadRequest(with: urlString) { result in
			completion(result)
		}
	}

    func loadRequest(for section: Int, row: Int, service: NetworkService) {

		let item = outline(for: section, row: row)
		chosenItem = item     // saving for later reference

		guard let path = item.URL else {
			// Do nothing if no URL is provided.
			return
		}

		switch item.type {
		case .link:
			loadLink(with: service, path: path, title: item.text)

		case .audio:
			loadAudio(with: service, path: path)

		case .undefined:
			self.errorEvent.value = BrowseViewError.undefinedType

		}
	}

	// MARK: Private
	private func loadLink(
		with service: NetworkService,
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

	private func loadAudio(with service: NetworkService, path: String) {

		self.activityCount.value += 1

		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIPlayList>) in

			self.activityCount.value -= 1

			switch result {
			case .success(var value):
				value.title = self.chosenItem?.text
				value.imageUrlStr = self.chosenItem?.image
				value.subTitle = self.chosenItem?.subtext
				value.parentNodeKey = self.chosenItem?.nowPlayingId
				self.newAudioItems.value = value

			case .failure(let error): print(error)
			self.errorEvent.value = error
			}
		}
	}
}
