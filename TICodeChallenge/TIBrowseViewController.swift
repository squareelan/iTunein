//
//  TIBrowseViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

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

		self.startNetworkActivityIndicator(isInteractionEnabled: false)
		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in

			self.stoptNetworkActivityIndicator()

			switch result {
			case .success(let value):

				let storyboard = UIStoryboard.mainStoryboard()
				guard let vc: TIBrowseViewController = storyboard.instantiateViewController() else {
					// error handling?
					return
				}

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

	func loadAudio(with path: String) {
		guard let url = NSURL(string: path) else {
			// TODO: alert view
			print("can't play music. wrong url")
			return
		}

		performSegueWithIdentifier("streamingSegue", sender: url)
	}


	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "streamingSegue" {
			guard let url = sender as? NSURL else {
				print("can't play music. wrong or missing url")
				return
			}

			guard let destination =
				segue.destinationViewController as? AVPlayerViewController else {
				print("can't open streaming player. Wrong player is assigned")
				return
			}

			destination.player = AVPlayer(URL: url)
		}
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

		tableView.deselectRowAtIndexPath(indexPath, animated: true)

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
			loadAudio(with: path)
		case .undefined:
			print("Wrong type")
		}

	}
}

