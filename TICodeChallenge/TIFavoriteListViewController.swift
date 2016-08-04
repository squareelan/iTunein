//
//  TIFavoriteListViewController.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class TIFavoriteListViewController: UIViewController {

	@IBOutlet private var tableView: UITableView!
	var viewModel = TIFavoriteListViewModel()
	private let disposeBag = DisposeBag()

    // MARK: - View life cycle
	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 40

		setUpRx()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		viewModel.fetchFavoriteLists(with: viewModel.favoriteListManager)
	}

}

// MARK: - ReactiveView
extension TIFavoriteListViewController: ReactiveView {

	func setUpRx() {
		viewModel
			.favoritePlayLists
			.asObservable()
			.debug("favorite list update")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] _ in
				self?.tableView.reloadData()
			}.addDisposableTo(disposeBag)
	}
}

// MARK: - UITableViewDataSource
extension TIFavoriteListViewController: UITableViewDataSource {

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.favoritePlayLists.value.count
	}

	func tableView(
		tableView: UITableView,
		cellForRowAtIndexPath indexPath: NSIndexPath
		) -> UITableViewCell {

		let playList = viewModel.favoritePlayLists.value[indexPath.row]
		let cell: TIGeneralTableViewCell = tableView.dequeueResuableCell(forIndexPath: indexPath)

		cell.titleLabel!.text = playList.title

		if let subtitle = playList.subTitle {
			cell.subTitleLabel.text = subtitle
			cell.subTitleLabel.hidden = false
		}
		else {
			cell.subTitleLabel.hidden = true
		}

		// TODO: Refactor this using local caching
		if let imageURL = playList.imageUrlStr {
			cell.thumbNailImageView.hidden = false

			// tagging to determine if the cell is reused and image is not valid anymore
			// Due to sections, this might not be a perfect solution. However, probably good enough
			let tag = indexPath.row
			cell.thumbNailImageView.tag = tag

			// fetch image from URL.
			viewModel.loadImage(with: viewModel.networkService,  urlString: imageURL) { result in
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

	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return CGFloat.min
	}
}

// MARK: - UITableViewDelegate
extension TIFavoriteListViewController: UITableViewDelegate {

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		let playList = viewModel.favoritePlayLists.value[indexPath.row]
		let player: TIAudioPlayerViewController
			= UIStoryboard.mainStoryboard().instantiateViewController()
		let audioManager = (UIApplication.sharedApplication().delegate as! TIAppDelegate).audioManager
		audioManager.playList = playList
		self.presentViewController(player, animated: true, completion: nil)
	}
}

