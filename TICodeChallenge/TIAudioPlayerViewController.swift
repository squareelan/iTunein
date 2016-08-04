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

	// MARK: - IBOutlet
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

	// MARK: - Private property
	private let audioManager: TIAudioPlaybackService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).audioManager
	private let networkService =
		(UIApplication.sharedApplication().delegate as! TIAppDelegate).networkService
	private let disposeBag = DisposeBag()

	// MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

		// Configuring initial view state

		// if there is no selected item, don't initialize.
		if audioManager.playList.playItems.count <= 0 {
			noItemView.hidden = false
		}

		// sets up title, cover image, and binding.
		else {
			titleLabel.text = audioManager.playList.title
			loadCoverImage(
				with: networkService,
				urlString: audioManager.playList.imageUrlStr
			)

			setUpRx()
			
			NSNotificationCenter.defaultCenter().addObserver(
				self,
				selector: #selector(TIAudioPlayerViewController.pauseAudio),
				name: AVPlayerItemDidPlayToEndTimeNotification,
				object: nil
			)
		}
    }

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func loadCoverImage(with service: TINetworkService, urlString: String?) {
		guard let urlStr = urlString else {
			coverImageView.image = UIImage(named: "tuneout")
			return
		}

		service.imageDownloadRequest(with: urlStr) { [weak self] result in
			switch result {
			case .success(let image):
				self?.coverImageView.image = image

			case .failure(let error):
				print(error)
			}
		}
	}

	// MARK: - Public method
	func playAudio() {
		audioManager.play()
	}

	func pauseAudio() {
		audioManager.pause()
	}

	// MARK: - IBAction
	@IBAction private func dismiss(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	@IBAction private func playButtonPressed(sender: AnyObject) {
		
		if !audioManager.isPlaying.value {
			playAudio()
		}
		else {
			pauseAudio()
		}
	}

	@IBAction private func muteButton(sender: UIButton) {
		if volumnSlider.value > 0 {
			sender.selected = !sender.selected

			audioManager.audioPlayer?.muted = sender.selected
		}
	}

	@IBAction private func previousButtonPressed(sender: AnyObject) {
		audioManager.loadPreviousItem()
	}

	@IBAction private func nextButtonPressed(sender: AnyObject) {
		audioManager.loadNextItem()
	}

	@IBAction private func favoriteButtonPressed(sender: AnyObject) {
		let alert = UIAlertController.create(
			with: nil,
			message: "Favorite feature is not available yet.".localizedString
		)
		alert.show()
	}
}

extension TIAudioPlayerViewController: ReactiveView {

	// TODO: create ViewModel instead of directly binding with audioManager
	func setUpRx() {

		// MARK: - Main UI state -
//		audioManager
//			.title
//			.asObservable()
//			.distinctUntilChanged { $0 == $1 }
//			.debug("title")
//			.observeOn(MainScheduler.instance)
//			.subscribeNext { [weak self] title in
//				self?.titleLabel.text = title
//			}.addDisposableTo(disposeBag)

//		audioManager
//			.albumImageUrl
//			.asObservable()
//			.distinctUntilChanged { $0 == $1 }
//			.debug("image")
//			.observeOn(MainScheduler.instance)
//			.subscribeNext { [weak self] urlStr in
//
//				guard let urlStr = urlStr else {
//					self?.coverImageView.image = UIImage(named: "tuneout")
//					return
//				}
//
//				self?.networkService
//					.imageDownloadRequest(with: urlStr) { [weak self] result in
//						switch result {
//						case .success(let image):
//							self?.coverImageView.image = image
//
//						case .failure(let error):
//							print(error)
//						}
//				}
//			}.addDisposableTo(disposeBag)

		audioManager
			.isLoading
			.asObservable()
			.distinctUntilChanged()
			.debug("isLoading")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] loading in
				if loading {
					self?.loadingView.startAnimating()
				}
				else {
					self?.loadingView.stopAnimating()
				}
			}.addDisposableTo(disposeBag)

		audioManager
			.error
			.asObservable()
			.filter { $0 != nil }
			.debug("audio error")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] error in
				let alert = UIAlertController.getGeneralAudioErrorAlert()
				self?.presentViewController(alert, animated: true, completion: nil)
			}.addDisposableTo(disposeBag)

		// MARK: - Media control state -
		audioManager
			.isReady
			.asObservable()
			.distinctUntilChanged()
			.debug("isReady")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] ready in
				self?.playButton.enabled = ready
			}.addDisposableTo(disposeBag)

		audioManager
			.isPlaying
			.asObservable()
			.distinctUntilChanged()
			.debug("isPlaying")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] playing in
				self?.playButton.selected = playing
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
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] index in
				self?.prevButton.enabled = (index! > 0)
				self?.nextButton.enabled = (index! < (self?.audioManager.playList.playItems.count)!-1)
			}.addDisposableTo(disposeBag)

		Observable
			.combineLatest(
				audioManager.isReady.asObservable(),
				audioManager.isLoading.asObservable()
			) { $0 && !$1 }
			.distinctUntilChanged()
			.debug("combined")
			.observeOn(MainScheduler.instance)
			.subscribeNext { [weak self] bool in

				if bool && !(self?.audioManager.isPlaying.value)! {
					self?.playAudio()
				}
			}.addDisposableTo(disposeBag)


		// MARK: - Volume control -
		audioManager
			.volume
			.asObservable()
			.shareReplayLatestWhileConnected()
			.debug("volume to slider")
			.bindTo(volumnSlider.rx_value)
			.addDisposableTo(disposeBag)

		volumnSlider
			.rx_value
			.asObservable()
			.shareReplayLatestWhileConnected()
			// Adding very small delay before updating value to manager
			// This is work around to prevent old value is being assigned
			// back.
			.throttle(0.025, scheduler: MainScheduler.instance)
			.debug("slider to volume")
			.bindTo(audioManager.volume)
			.addDisposableTo(disposeBag)

		audioManager
			.volume
			.asObservable()
			.distinctUntilChanged()
			.shareReplayLatestWhileConnected()
			.debug("Volume icon update")
			.observeOn(MainScheduler.instance)
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

