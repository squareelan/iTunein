//
//  TIBrowseViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import RxSwift
import AVKit
import AVFoundation

// This class is created for generic table view for displaying
// TuneIn's opml outline items. However, it only provide 2 level depth.
// (Top level will be presented as section and bottom will be row)
final class TIBrowseViewController: UIViewController, ReactiveView {

	@IBOutlet private var tableView: UITableView!
	private let disposeBag = DisposeBag()
	private var player: AVPlayer!

	var viewModel: TIBrowseViewModel! // viewModel should always exist after viewDidLoad

	// MARK: - View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.setNavigationBarHidden(false, animated: false)

		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 40

		setUpRx()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TIBrowseViewController.setUpRx), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
	}

	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if player.status == AVPlayerStatus.Failed {
			print("failed")
		} else if player.status == AVPlayerStatus.ReadyToPlay {
			self.player.play()
		} else if player.status == AVPlayerStatus.Unknown {
			print("unknown")
		}
	}

	func setUpRx() {

		// update view title
		viewModel.title.asObservable().debug("Title")
			.subscribeNext { [weak self] text in self?.title = text }
			.addDisposableTo(disposeBag)

		// show/hide activity indicator
		viewModel.activityCount.asObservable().debug("Activity Count")
			.subscribeNext { [weak self] count in

			if (count > 0) {
				self?.startNetworkActivityIndicator(isInteractionEnabled: false)
			}
			else {
				self?.stoptNetworkActivityIndicator()
			}
		}.addDisposableTo(disposeBag)

		// if new browse item is fetched, show new view for the item.
		viewModel.newBrowseItem.asObservable()
			.filter { $0 != nil }.debug("New Browse Item")
			.subscribeNext { [weak self] browseItem in

			// Covering the case where title is missed out for some outline.
			let title = browseItem!.title ?? self?.viewModel.chosenItem?.text
			self?.showNewBrowseView(with: browseItem!, title: title)
		}.addDisposableTo(disposeBag)

		// if new audio url is assigned, play new audio
		viewModel.newAudioURL.asObservable()
			.filter { $0 != nil }.debug("New Audio")
			.subscribeNext { [weak self] audioURL in

			let asset = AVAsset(URL: audioURL!)
			let avItem = AVPlayerItem(asset: asset)
			self?.player = AVPlayer(playerItem: avItem)

			self?.player.addObserver(self!, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)

//			self?.performSegueWithIdentifier("streamingSegue", sender: audioURL)
		}.addDisposableTo(disposeBag)

		// Hook up for any error
		viewModel.errorEvent.asObservable()
			.filter { $0 != nil }.debug("Error Event")
			.subscribeNext { [weak self] error in

			// probably better to handle recoverable and non-recoverable error differently
			// providing retry option for recoverable error would
			let title = "Network Error"
			let message = "Sorry, we are having an issue. Please try again later."
			let alert = UIAlertController.create(with: title, message: message)
			self?.presentViewController(alert, animated: true, completion: nil)
		}.addDisposableTo(disposeBag)
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

	func showNewBrowseView(with browseItem: TIBrowse, title: String?) {
		let vc: TIBrowseViewController =
			UIStoryboard.mainStoryboard().instantiateViewController()

		let newVM = TIBrowseViewModel(
			browseItem: browseItem,
			title: Variable<String?>(title)
		)
		vc.viewModel = newVM
		self.navigationController?.pushViewController(vc, animated: true)
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
		}
		else {
			cell.subTitleLabel.hidden = true
		}

		if let imageURL = outline.image {
			cell.thumbNailImageView.hidden = false

			// tagging to determine if the cell is reused and image is not valid anymore
			// Due to sections, this might not be a perfect solution. However, probably good enough
			let tag = row * (section+1)
			cell.thumbNailImageView.tag = tag

			// fetch image from URL.
			viewModel.networkService.imageDownloadRequest(with: imageURL) { result in

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
		}
		else {
			cell.thumbNailImageView.hidden = true
		}

		return cell
	}
}

extension TIBrowseViewController: UITableViewDelegate {

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		viewModel.request(for: indexPath.section, row: indexPath.row)
	}
}

