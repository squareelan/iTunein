//
//  TIAudioPlayerViewController.swift
//  TuneOut
//
//  Created by Ian on 8/1/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import RxSwift
import AVFoundation

final class TIAudioPlayerViewController: UIViewController {

	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var favoriteButton: UIButton!
	@IBOutlet private var coverImageView: UIImageView!
	@IBOutlet private var prevButton: UIButton!
	@IBOutlet private var playButton: UIButton!
	@IBOutlet private var nextButton: UIButton!
	@IBOutlet private var volumnSlider: UISlider!
	@IBOutlet private var muteButton: UIButton!
	@IBOutlet private var loadingView: UIActivityIndicatorView!
	@IBOutlet private var noItemView: UIView!

	private let audioManager =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).audioManager

	private let networkService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService
	private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

		if audioManager.playList.playItems.count <= 0 {
			noItemView.hidden = false
		}

		volumnSlider.value = audioManager.volume.value / 2

		setUpRx()

		// need to be initialized after setUpRx.
		muteButton.selected = audioManager.audioPlayer?.muted ?? false

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(TIAudioPlayerViewController.pauseAudio),
			name: AVPlayerItemDidPlayToEndTimeNotification,
			object: nil
		)
    }

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	@IBAction func dismiss(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	@IBAction func playButtonPressed(sender: AnyObject) {
		
		if !audioManager.isPlaying.value {
			playAudio()
		}
		else {
			pauseAudio()
		}
	}

	func playAudio() {
		audioManager.play()
	}

	func pauseAudio() {
		audioManager.pause()
	}

	@IBAction func muteButton(sender: UIButton) {
		if volumnSlider.value > 0 {
			sender.selected = !sender.selected

			audioManager.audioPlayer?.muted = sender.selected
		}
	}

	@IBAction func previousButtonPressed(sender: AnyObject) {
		audioManager.loadPreviousItem()
	}

	@IBAction func nextButtonPressed(sender: AnyObject) {
		audioManager.loadNextItem()
	}

	@IBAction func favoriteButtonPressed(sender: AnyObject) {
		let alert = UIAlertController.create(
			with: nil,
			message: "Favorite feature is not available yet."
		)
		alert.show()
	}
}

extension TIAudioPlayerViewController: ReactiveView {

	func setUpRx() {
		audioManager
			.isReady
			.asObservable()
			.distinctUntilChanged()
			.debug("isReady")
			.subscribeNext { [weak self] ready in
				self?.playButton.enabled = ready
			}.addDisposableTo(disposeBag)

		audioManager
			.isLoading
			.asObservable()
			.distinctUntilChanged()
			.debug("isLoading")
			.subscribeNext { [weak self] loading in
				if loading {
					self?.loadingView.startAnimating()
				}
				else {
					self?.loadingView.stopAnimating()
				}
			}.addDisposableTo(disposeBag)

		Observable
			.combineLatest(
			audioManager.isReady.asObservable(),
			audioManager.isLoading.asObservable()
			) { $0 && !$1 }
			.distinctUntilChanged()
			.debug("combined")
			.subscribeNext { [weak self] bool in

				if bool && !(self?.audioManager.isPlaying.value)! {
					self?.playAudio()
				}
			}.addDisposableTo(disposeBag)

		audioManager
			.title
			.asObservable()
			.distinctUntilChanged { $0 == $1 }
			.debug("title")
			.subscribeNext { [weak self] title in
				self?.titleLabel.text = title
			}.addDisposableTo(disposeBag)

		audioManager
			.albumImageUrl
			.asObservable()
			.distinctUntilChanged { $0 == $1 }
			.debug("image")
			.subscribeNext { [weak self] urlStr in

				guard let urlStr = urlStr else {
					self?.coverImageView.image = UIImage(named: "tuneout")
					return
				}

				self?.networkService
					.imageDownloadRequest(with: urlStr) { [weak self] result in
						switch result {
						case .success(let image):
							self?.coverImageView.image = image

						case .failure(let error):
							print(error)
						}
				}
			}.addDisposableTo(disposeBag)

		Observable.combineLatest(
			audioManager.isPlaying.asObservable(),
			audioManager.isLoading.asObservable()
			) { $0 && !$1 }
			.distinctUntilChanged()
			.debug("play button selected state")
			.bindTo(playButton.rx_selected)
			.addDisposableTo(disposeBag)

		audioManager
			.currentIndex
			.asObservable()
			.filter { $0 != nil }
			.distinctUntilChanged { $0 == $1 }
			.debug("play Item index changed")
			.subscribeNext { [weak self] index in
				self?.prevButton.enabled = (index! > 0)
				self?.nextButton.enabled = (index! < (self?.audioManager.playList.playItems.count)!-1)
			}.addDisposableTo(disposeBag)

		volumnSlider
			.rx_value
			.asObservable()
			.distinctUntilChanged()
			.map { $0 * 2 }		// scale up 2x
			.shareReplayLatestWhileConnected()
			.debug("slider changed")
			.bindTo(audioManager.volume)
			.addDisposableTo(disposeBag)

		volumnSlider
			.rx_value
			.asObservable()
			.distinctUntilChanged()
			.shareReplayLatestWhileConnected()
			.subscribeNext { [weak self] value in

				if value == 0 {
					self?.muteButton.selected = true
				}
				else {
					self?.muteButton.selected = false
					self?.audioManager.audioPlayer?.muted = false

					if value > 0 && value < 0.33 {
						self?.muteButton.setBackgroundImage(UIImage(named: "Low Volume Filled")!, forState: .Normal)
					}
					else if value > 0.33 && value < 0.66 {
						self?.muteButton.setBackgroundImage(UIImage(named: "Medium Volume Filled")!, forState: .Normal)
					}
					else {
						self?.muteButton.setBackgroundImage(UIImage(named: "High Volume Filled")!, forState: .Normal)
					}
				}
			}.addDisposableTo(disposeBag)
	}
}

