//
//  TIBrowseViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

final class TIBrowseViewController: UIViewController {

	var browseItem: TIBrowse!

	let path = "http://opml.radiotime.com/"

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.title = self.browseItem.title
	}

	func fetchBrowseMenu() {

		let networkService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

		networkService.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in
			switch result {

			case .success(let value): self.browseItem = value

			case .failure(let error): print(error)
//				switch(error) {
//					
//				}
			}
		}
	}
}

extension TIBrowseViewController: UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return browseItem.outlines.count
	}

	func tableView(
		tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath
	) -> UITableViewCell {

		let cell = tableView.dequeueReusableCellWithIdentifier(
			"browseItemCell",
			forIndexPath: indexPath
		)

		cell.textLabel!.text = browseItem.outlines![indexPath.row].text!
		return cell
	}
}

