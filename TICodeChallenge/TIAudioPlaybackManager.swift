//
//  TIAudioPlaybackManager.swift
//  TuneOut
//
//  Created by Ian on 8/2/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import AVFoundation
import MediaPlayer
import RxSwift
import RxCocoa

enum TIAudioPlaybackError: ErrorType {

	// non recoverable errors
	case invalidURL
	case invalidAudio

	static let TINetworkErrorDomain = "com.SQuareElan.TINetworkService"
}

final class TIAudioPlaybackManager: NSObject, TIAudioPlaybackService {

	struct Constants {
		static let AVPLAYER_STATUS_KEY = "status"
		static let AVPLAYER_CURRENT_ITEM_PLAYBACK_LIKELY_TO_KEEP_UP_KEY = "currentItem.playbackLikelyToKeepUp"
		static let AVPLAYER_CURRENT_ITEM_PLAYBACK_BUFFER_EMPTY_KEY = "currentItem.playbackBufferEmpty"
		static let DefaultVolume: Float = 1.0
	}

	// TODO: change to AVQueuePlayer
	var audioPlayer: AVPlayer?
	var playList: TIPlayList {
		didSet {
			if oldValue == playList {
				return
			}
			currentItem = playList.playItems.first
		}
	}

//	private (set) var albumImageUrl = Variable<String?>(nil)
//	private (set) var title = Variable<String?>(nil)
	private (set) var isReady = Variable<Bool>(false)
	private (set) var isLoading = Variable<Bool>(false)
	private (set) var isPlaying = Variable<Bool>(false)
	private (set) var error = Variable<TIAudioPlaybackError?>(nil)
	private (set) var volume = Variable<Float>(AVAudioSession.sharedInstance().outputVolume)

	private (set) var currentIndex = Variable<Int?>(nil)

	private var currentItem: TIPlayItem? {
		didSet {
			// update current Index
			guard let currentItem = currentItem else {
				return
			}

			currentIndex.value = playList.playItems.indexOf({$0 == currentItem})

			// update AVPlayer's play item
			guard let url = NSURL(string: currentItem.url) else {

				// Don't initialize AVplayer if no item is available
				error.value = TIAudioPlaybackError.invalidURL
				return
			}

			setupAudioPlayer(with: url)

			// configure prev and next remote command
			let prevCommandEnable = currentIndex.value > 0
			let nextCommandEnable = currentIndex.value < playList.playItems.count-1

			enablePreviousRemoteCommand(prevCommandEnable)
			enableNextRemoteCommand(nextCommandEnable)
		}
	}

	private let disposeBag = DisposeBag()

	// MARK: - Initializer
	init(playList: TIPlayList) {
		self.playList = playList
	}

	// MARK: - Playback control
	func play() {
		audioPlayer?.play()
	}

	func pause() {
		audioPlayer?.pause()
	}

	func togglePlay() {
		if isPlaying.value {
			pause()
		}
		else {
			play()
		}
	}

	func loadPreviousItem() {
		if let currentIndex = currentIndex.value
			where currentIndex > 0 {
			currentItem = playList.playItems[currentIndex-1]
		}
	}

	func loadNextItem() {
		if let currentIndex = currentIndex.value
			where currentIndex < playList.playItems.count-1 {
			currentItem = playList.playItems[currentIndex+1]
		}
	}

	// MARK: - Audio item set up
	private func setupAudioPlayer(with url: NSURL) {

		// cleaning up residual error
		error.value = nil

		// instantiate asset, play item, player.
		let asset = AVURLAsset(URL: url)
		let keys = [
			"tracks",
			"playable",
			"duration",
			"preferredRate",
			"preferredVolume",
			"commonMetadata",
			"availableMediaCharacteristicsWithMediaSelectionOptions"
		]

		// preload some values
		asset.loadValuesAsynchronouslyForKeys(keys) { [weak self] Void in

			for key in keys {
				var error: NSError?
				let keyStatus = asset.statusOfValueForKey(key, error: &error)
				guard keyStatus != .Failed && error == nil else {

					// create invalid error for now. Specific error for each key
					// would be helpful
					self?.error.value = TIAudioPlaybackError.invalidAudio
					return
				}
			}

//			print("Playable: \(asset.playable)")
//			print("tracks: \(asset.tracks)")
//			print("duration: \(asset.duration)")
//			print("preferredRate: \(asset.preferredRate)")
//			print("preferredVolume: \(asset.preferredVolume)")
//			print("commonMetadata: \(asset.commonMetadata)")
//			print("availableMediaCharacteristicsWithMediaSelectionOptions: \(asset.availableMediaCharacteristicsWithMediaSelectionOptions)")
		}

		let playerItem = AVPlayerItem(asset: asset)

		// if audioPlayer exist, just swap playItem
		if let player = audioPlayer {
			player.pause()
			player.replaceCurrentItemWithPlayerItem(playerItem)
		}

		// first time set up
		else {

			setUpMediaCommand()

			// rx_observe is simple KVO wrapper. Listening for status change.
			audioPlayer = AVPlayer(playerItem: playerItem)
			audioPlayer!
				.rx_observe(AVPlayerStatus.self, Constants.AVPLAYER_STATUS_KEY)
				.filter { $0 != nil }
				.shareReplayLatestWhileConnected()
				.debug("AudioPlayer Status Changed")
				.subscribeNext{ [weak self] status in
					self?.isReady.value = (status! == .ReadyToPlay)
				}.addDisposableTo(disposeBag)

			audioPlayer!
				.rx_observe(Bool.self, Constants.AVPLAYER_CURRENT_ITEM_PLAYBACK_LIKELY_TO_KEEP_UP_KEY)
				.filter { $0 != nil }
				.shareReplayLatestWhileConnected()
				.debug("Likely To Keep up")
				.subscribeNext{ [weak self] likelyToKeepUp in
					self?.isLoading.value = !likelyToKeepUp!
				}.addDisposableTo(disposeBag)


			audioPlayer!
				.rx_observe(Bool.self, Constants.AVPLAYER_CURRENT_ITEM_PLAYBACK_BUFFER_EMPTY_KEY)
				.filter { $0 != nil }
				.shareReplayLatestWhileConnected()
				.debug("Buffer empty")
				.subscribeNext{ [weak self] bufferEmpty in
					self?.isLoading.value = bufferEmpty!
				}.addDisposableTo(disposeBag)

			audioPlayer!
				.rx_observe(Float.self, "rate")
				.shareReplayLatestWhileConnected()
				.debug("audio player rate")
				.subscribeNext { [weak self] rate in
					self?.isPlaying.value = rate > 0
				}.addDisposableTo(disposeBag)

			AVAudioSession.sharedInstance()
				.rx_observe(Float.self, "outputVolume")
				.distinctUntilChanged { $0 == $1 }
				.filter{ $0 != nil }
				// Adding very small delay to prevent update cycle
				.throttle(0.025, scheduler: MainScheduler.instance)
				.debug("outputVolume")
				.observeOn(MainScheduler.instance)
				.subscribeNext { [weak self] volume in
					self?.volume.value = volume!
				}.addDisposableTo(disposeBag)

			volume
				.asObservable()
				.distinctUntilChanged()
				.debug("volume update")
				.observeOn(MainScheduler.instance)
				.subscribeNext { [weak self] newVolume in
					self?.audioPlayer!.volume = newVolume

					let volumeView = MPVolumeView()
					for view in volumeView.subviews {
						guard let slider = view as? UISlider else {
							continue
						}
						slider.setValue(newVolume, animated: false)
					}
				}.addDisposableTo(disposeBag)

			isReady
				.asObservable()
				.subscribeNext { [weak self] ready in
					self?.enablePlayRemoteCommand(ready)
					self?.enablePauseRemoteCommand(ready)
				}.addDisposableTo(disposeBag)
		}
	}

	// MARK: - Media remote command
	private func setUpMediaCommand() {

		let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()

		commandCenter.previousTrackCommand.addTarget(
			self,
			action: #selector(TIAudioPlaybackManager.loadPreviousItem)
		)

		commandCenter.playCommand.addTarget(
			self,
			action: #selector(TIAudioPlaybackManager.play)
		)

		commandCenter.pauseCommand.addTarget(
			self,
			action: #selector(TIAudioPlaybackManager.pause)
		)

		commandCenter.nextTrackCommand.addTarget(
			self,
			action: #selector(TIAudioPlaybackManager.loadNextItem)
		)
	}

	private func enablePreviousRemoteCommand(enabled: Bool) {
		MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.enabled = enabled
	}

	private func enablePlayRemoteCommand(enabled: Bool) {
		MPRemoteCommandCenter.sharedCommandCenter().playCommand.enabled = enabled
	}

	private func enablePauseRemoteCommand(enabled: Bool) {
		MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.enabled = enabled
	}

	private func enableNextRemoteCommand(enabled: Bool) {
		MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.enabled = enabled
	}
}
