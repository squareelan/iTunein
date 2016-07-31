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

	@IBOutlet private var tableView: UITableView!

	var viewModel: TIBrowseViewModel! // viewModel should always exist after viewDidLoad
	let networkService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService


	// MARK: - View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.setNavigationBarHidden(false, animated: false)
		title = viewModel.title
	}

	// MARK: - Network Request

	func loadLink(
		service: TINetworkService,
		path: String,
		title temporaryTitle: String?
	) {

		self.startNetworkActivityIndicator(isInteractionEnabled: false)
		service.simpleTIGetRequest(
			with: path
		) { (result: Result<TIBrowse>) in

			self.stoptNetworkActivityIndicator()

			switch result {
			case .success(let value):

				let vc: TIBrowseViewController =
					UIStoryboard.mainStoryboard().instantiateViewController()

				// Covering the case where title is missed out for some outline.
				let title = value.title ?? temporaryTitle
				let newVM = TIBrowseViewModel(browseItem: value, title: title)
				vc.viewModel = newVM

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
		return viewModel.numberOfRows(for: section)
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return viewModel.numberOfSections
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return viewModel.sectionTitle(for: section)
	}

	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if viewModel.browseItem.outlines[section].children == nil {
			return CGFloat.min
		}
		return tableView.sectionHeaderHeight
	}

	func tableView(
		tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath
	) -> UITableViewCell {

		// TODO: static constant for identifier
		let cell: TIBrowseTableViewCell = tableView.dequeueResuableCell(forIndexPath: indexPath)

		let title = viewModel.outline(
			for: indexPath.section,
			row: indexPath.row).text

		cell.textLabel!.text = title

		return cell
	}
}

extension TIBrowseViewController: UITableViewDelegate {

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		let item = viewModel.outline(for: indexPath.section, row: indexPath.row)
		guard let path = item.URL else {
			// TODO: alert popup
			return
		}

		switch item.type {
		case .link:
			loadLink(networkService, path: path, title: item.text)
		case .audio:
			loadAudio(with: path)
		case .undefined:
			print("Wrong type")
		}

	}
}

