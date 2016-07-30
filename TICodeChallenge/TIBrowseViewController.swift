//
//  TIBrowseViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit

// This class is created for generic table view for displaying
// TuneIn's opml outline items. However, it only provide 2 level depth.
// (Top level will be presented as section and bottom will be row)
final class TIBrowseViewController: UIViewController {

	// Core data for this view.
	var browseItem: TIBrowse!
	var temporaryTitle: String?
	let networkService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService

	@IBOutlet private var tableView: UITableView!

	// MARK: - View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.setNavigationBarHidden(false, animated: false)
		title = browseItem.title ?? temporaryTitle

		tableView.sectionIndexColor = UIColor.blueColor()
		tableView.sectionIndexBackgroundColor = UIColor.greenColor()
	}

	func isChildrenExist(outlines: [TIOutline]) -> Bool {
		var bool = false
		for outline in outlines {
			if outline.children != nil {
				bool = true
				break
			}
		}
		return bool
	}

	func getOutline(from indexPath: NSIndexPath) -> TIOutline {
		if let children = browseItem.outlines[indexPath.section].children {
			return children[indexPath.row]
		}
		else {
			if !isChildrenExist(browseItem.outlines) {
				return browseItem.outlines[indexPath.row]
			}
			return browseItem.outlines[indexPath.section]
		}
	}

	// MARK: - Network Request

	func loadLink(service: TINetworkService, path: String) {

		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in
			switch result {

			case .success(let value):
				// TODO: refactor
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let vc = storyboard.instantiateViewControllerWithIdentifier("TIBrowseViewController") as! TIBrowseViewController

				vc.temporaryTitle = self.temporaryTitle
				vc.browseItem = value
				self.navigationController?.pushViewController(vc, animated: true)

			// TODO: error handling
			case .failure(let error): print(error)
				//						switch(error) {
				//
				//						}
			}
		}
	}

	func loadAudio(service: TINetworkService, path: String) {

	}
}

// MARK: - UITableView

extension TIBrowseViewController: UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		// if outline item have children, use it for a row.
		// parent outline item becomes section header.
		if let children = browseItem.outlines[section].children {
			return children.count
		}
		else {
			if !isChildrenExist(browseItem.outlines) {
				return browseItem.outlines.count
			}
			return 1
		}
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {

		guard let outlines = browseItem.outlines else {
			return 0
		}

		return isChildrenExist(outlines) ? outlines.count : 1
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if browseItem.outlines[section].children != nil {
			return browseItem.outlines[section].text
		}
		return nil
	}

	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if browseItem.outlines[section].children == nil {
			return CGFloat.min
		}
		return tableView.sectionHeaderHeight
	}

	func tableView(
		tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath
	) -> UITableViewCell {

		// TODO: static constant for identifier
		let cell = tableView.dequeueReusableCellWithIdentifier(
			"browseItemCell",
			forIndexPath: indexPath
		)

		let title = getOutline(from: indexPath).text
		cell.textLabel!.text = title

		return cell
	}
}

extension TIBrowseViewController: UITableViewDelegate {

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

		let item = getOutline(from: indexPath)
		guard let path = item.URL else {
			// TODO: alert popup
			return
		}

		// Covering the case where title is missed out for some outline.
		temporaryTitle = item.text

		switch item.type {
		case .link:
			loadLink(networkService, path: path)
		case .audio:
			print("Not implemted yet")
		case .undefined:
			print("Wrong type")
		}

	}
}

