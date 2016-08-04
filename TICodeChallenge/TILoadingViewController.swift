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
	private let path = "http://opml.radiotime.com/"

	// MARK: - View Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.setNavigationBarHidden(true, animated: false)

		let networkService =
			(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

		// load data for next view
		fetchBrowseMenu(with: networkService, path: path)
	}

//	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//		if segue.identifier == SegueIdentifier.showMainPage {
//			guard let viewModel = sender as? TIBrowseViewModel else {
//				// non recoverable
//				fatalError("Can't instantiate main page. Missing ViewModel...")
//			}
//
//			guard let destination = segue.destinationViewController as? UITabBarController else {
//				// non recoverable
//				fatalError("Wrong destination view controller is fetched. Expecting UITabBarController")
//			}
//
//			for vc in destination.viewControllers! {
//				if let vc = vc as? TIBrowseViewController {
//					vc.viewModel = viewModel
//					destination.selectedViewController = vc
//					break
//				}
//			}
//		}
//	}

	// MARK: - Network Request - Move to viewModel if create one.

	func fetchBrowseMenu(with service: NetworkService, path: String) {

		service.simpleTIGetRequest(
			with: path
		) { [weak self] (result: Result<TIBrowse>) in

			switch result {
			case .success(let value):

				guard let tabBarController = UIStoryboard.mainStoryboard()
					.instantiateViewControllerWithIdentifier(
						TabBarControllerIdentifier.rootTabBar) as? UITabBarController,
					let navController = tabBarController.viewControllers?[0]
						as? UINavigationController,
					let topVc = navController.topViewController as? TIBrowseViewController else {

					// unrecoverable error
					fatalError("Could not instantiate proper view controller")
				}

				let newViewModel = TIBrowseViewModel(
					browseItem: value,
					title: Variable<String?>(value.title)
				)
				topVc.viewModel = newViewModel

				(UIApplication.sharedApplication().delegate as! TIAppDelegate)
					.window?.rootViewController = tabBarController

			case .failure(let error):

				// TODO: change to debug print
				print(error)

				// probably better to handle recoverable and non-recoverable error differently
				// providing retry option for recoverable error would
				let title = "Network Error".localizedString
				let message = "Sorry, we are having an issue. Please try again later.".localizedString
				let alert = UIAlertController.create(
					with: title,
					message: message,
					buttonTitle: "Retry".localizedString,
					buttonAction: {
						self?.fetchBrowseMenu(with: service, path: path)
					}
				)

				alert.show()
			}
		}
	}
}