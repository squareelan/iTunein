//
//  TIBrowseViewController.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import RxSwift
import AVFoundation

// This class is created for generic table view for displaying
// TuneIn's opml outline items. However, it only provide 2 level depth.
// (Top level will be presented as section and bottom will be row)
final class TIBrowseViewController: UIViewController {

	@IBOutlet private var tableView: UITableView!
	private let disposeBag = DisposeBag()

	var viewModel: TIBrowseViewModel! // viewModel should always exist after viewDidLoad

	// MARK: - View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 40

		setUpRx()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		navigationController?.setNavigationBarHidden(false, animated: false)
		
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

// MARK: - ReactiveView
extension TIBrowseViewController: ReactiveView {
	
	func setUpRx() {

		// update view title
		viewModel
			.title
			.asObservable()
			.debug("Title")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] text in self?.title = text }
			.addDisposableTo(disposeBag)

		// show/hide activity indicator
		viewModel
			.activityCount
			.asObservable()
			.debug("Activity Count")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] count in
				if (count > 0) {
					self?.startNetworkActivityIndicator(isInteractionEnabled: false)
				}
				else {
					self?.stoptNetworkActivityIndicator()
				}
			}.addDisposableTo(disposeBag)

		// if new browse item is fetched, show new view for the item.
		viewModel
			.newBrowseItem
			.asObservable()
			.filter { $0 != nil }
			.debug("New Browse Item")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] browseItem in

				// Covering the case where title is missed out for some outline.
				let title = browseItem!.title ?? self?.viewModel.chosenItem?.text
				self?.showNewBrowseView(with: browseItem!, title: title)
			}.addDisposableTo(disposeBag)

		// if new audio url is assigned, play new audio
		viewModel
			.newAudioItems
			.asObservable()
			.filter { $0 != nil }
			.debug("New Audio")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] audioItems in

				let player: TIAudioPlayerViewController
					= UIStoryboard.mainStoryboard().instantiateViewController()
				let audioManager = (UIApplication.sharedApplication().delegate as! TIAppDelegate).audioManager
				audioManager.playList = audioItems!

				self?.presentViewController(player, animated: true, completion: nil)
			}.addDisposableTo(disposeBag)

		// Hook up for any error
		viewModel.errorEvent.asObservable()
			.filter { $0 != nil }
			.debug("Error Event")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] error in

				// probably better to handle recoverable and non-recoverable error differently
				// providing retry option for recoverable error would
				let alert = UIAlertController.getGeneralNetworkErrorAlert()
				self?.presentViewController(alert, animated: true, completion: nil)
			}.addDisposableTo(disposeBag)



		viewModel
			.showDownloadPopup
			.asObservable()
			.filter { $0 == true }
			.debug("Download Pop up")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] _ in
				self?.viewModel.showDownloadPopup.value = false

				let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
				let playAction = UIAlertAction(title: "Play", style: .Default) { _ in
					guard let service = self?.viewModel.networkService,
						let path = self?.viewModel.chosenItem?.URL else {
						return
					}
					self?.viewModel.loadAudio(with: service, path: path)
				}

				let downloadAction = UIAlertAction(title: "Download", style: .Default) { _ in

					guard let service = self?.viewModel.downloadService,
						let path = self?.viewModel.chosenItem?.URL,
						let id = self?.viewModel.chosenItem?.nowPlayingId else {
							return
					}

					self?.viewModel.downloadAudio(with: service, path: path, id: id)
				}
				alert.addAction(playAction)
				alert.addAction(downloadAction)
				self?.presentViewController(alert, animated: true, completion: nil)
			}.addDisposableTo(disposeBag)
	}
}

// MARK: - UITableViewDataSource
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

		let cell: TIGeneralTableViewCell = tableView.dequeueResuableCell(forIndexPath: indexPath)

		let title = outline.text
		cell.titleLabel!.text = title

		if let subtitle = outline.subtext {
			cell.subTitleLabel.text = subtitle
			cell.subTitleLabel.hidden = false
		}
		else {
			cell.subTitleLabel.hidden = true
		}


		// TODO: Refactor this using local caching
		if let imageURL = outline.image {
			cell.thumbNailImageView.hidden = false

			// tagging to determine if the cell is reused and image is not valid anymore
			// Due to sections, this might not be a perfect solution. However, probably good enough
			let tag = row * (section+1)
			cell.thumbNailImageView.tag = tag

			// fetch image from URL.
            viewModel.loadImage(
                with: viewModel.networkService,
                urlString: imageURL
            ) { result in

				switch result {
				case .success(let image):
					if cell.thumbNailImageView.tag == tag {
						cell.thumbNailImageView.image = image
					}

				case .failure(let error):
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

// MARK: - UITableViewDelegate
extension TIBrowseViewController: UITableViewDelegate {

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

		tableView.deselectRowAtIndexPath(indexPath, animated: true)

        viewModel.loadRequest(
            for: indexPath.section,
            row: indexPath.row,
            service: viewModel.networkService
        )
	}
}

