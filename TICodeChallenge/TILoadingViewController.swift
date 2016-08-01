//
//  TILoadingViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import RxSwift

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


	// MARK: - Network Request - Move to viewModel if create one.

	func fetchBrowseMenu(with service: TINetworkService, path: String) {

		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in

			switch result {
			case .success(let value):
				let vc: TIBrowseViewController =
					UIStoryboard.mainStoryboard().instantiateViewController()
				let newViewModel = TIBrowseViewModel(
					browseItem: value,
					title: Variable<String?>(value.title)
				)
				vc.viewModel = newViewModel
				self.navigationController?.setViewControllers([vc], animated: false)
				
			case .failure(let error):

				// TODO: change to debug print
				print(error)

				// probably better to handle recoverable and non-recoverable error differently
				// providing retry option for recoverable error would
				let title = "Network Error"
				let message = "Sorry, we are having an issue. Please try again later."
				UIAlertController.create(with: title, message: message)
			}
		}
	}
}