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

		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 40
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

		guard let url = NSURL(string: path.urlDecoded.urlEncoded) else {
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

		let section = indexPath.section
		let row = indexPath.row
		let outline = viewModel.outline(for: section, row: row)

		let cell: TIBrowseTableViewCell = tableView.dequeueResuableCell(forIndexPath: indexPath)

		let title = outline.text
		cell.titleLabel!.text = title

		if let subtitle = outline.subtext {
			cell.subTitleLabel.text = subtitle
			cell.subTitleLabel.hidden = false
		} else {
			cell.subTitleLabel.hidden = true
		}

		if let imageURL = outline.image {
			cell.thumbNailImageView.hidden = false

			// tagging to determine if the cell is reused and image is not valid anymore
			// Due to sections, this might not be a perfect solution. However, probably good enough
			let tag = row * (section+1)
			cell.thumbNailImageView.tag = tag

			// fetch image from URL.
			networkService.imageDownloadRequest(with: imageURL) { result in
				switch result {
				case .success(let image):
					if cell.thumbNailImageView.tag == tag {
						cell.thumbNailImageView.image = image
					}
				case .failure(let error):
					// TODO: refactor and automatically retry
					print(error)
				}
			}
		} else {
			cell.thumbNailImageView.hidden = true
		}

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

