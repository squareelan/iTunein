//
//  TILoadingViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

final class TILoadingViewController: UIViewController {


	// TODO: create static constants
	let path = "http://opml.radiotime.com/"


	// MARK: - View Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationController?.setNavigationBarHidden(true, animated: false)

		let networkService =
			(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

		// load data for next view
		fetchBrowseMenu(with: networkService, path: path)
	}


	// MARK: - Network Request

	func fetchBrowseMenu(with service: TINetworkService, path: String) {

		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in
			switch result {

			case .success(let value):

				// TODO: refactor it as extension
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let vc = storyboard.instantiateViewControllerWithIdentifier(
					"TIBrowseViewController"
				) as! TIBrowseViewController

				vc.browseItem = value
				vc.temporaryTitle = value.title
				self.navigationController?.setViewControllers([vc], animated: false)
				
			case .failure(let error): print(error)

			}
		}
	}
}