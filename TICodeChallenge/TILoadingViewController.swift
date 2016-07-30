//
//  TILoadingViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/30/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

final class TILoadingViewController: UIViewController {

	let path = "http://opml.radiotime.com/"

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationController?.setNavigationBarHidden(true, animated: false)

		// load data for next view
		fetchBrowseMenu()
	}

	func fetchBrowseMenu() {

		let networkService =
			(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

		networkService.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in
			switch result {

			case .success(let value):

				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let vc = storyboard.instantiateViewControllerWithIdentifier(
					"TIBrowseViewController"
				) as! TIBrowseViewController

				vc.browseItem = value
				self.navigationController?.setViewControllers([vc], animated: false)
				
			case .failure(let error): print(error)
//						switch(error) {
//		
//						}
			}
		}
	}
}