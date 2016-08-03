//
//  TIAudioPlaybackManager.swift
//  TuneOut
//
//  Created by Ian on 8/2/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import AVFoundation
import RxSwift
import RxCocoa

final class TIAudioPlaybackManager: NSObject {

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

	private (set) var albumImageUrl = Variable<String?>(nil)
	private (set) var title = Variable<String?>(nil)
	let isReady = Variable<Bool>(false)
	let isLoading = Variable<Bool>(false)
	let isPlaying = Variable<Bool>(false)
	let error = Variable<ErrorType?>(nil)
	let volume = Variable<Float>(Constants.DefaultVolume)
//	let muted = Variable<Bool>(false)

	private (set) var currentIndex = Variable<Int?>(nil)

	private (set) var currentItem: TIPlayItem? {
		didSet {
			// update current Index
			guard let currentItem = currentItem else {
				return
			}

			currentIndex.value = playList.playItems.indexOf({$0 == currentItem})

			// update AVPlayer's play item
			guard let url = NSURL(string: currentItem.url) else {

				// Don't initialize AVplayer if no item is available
				return
			}

			setupAudioPlayer(with: url)
		}
	}

//	var volume: Float = Constants.DefaultVolume {
//		didSet {
//			audioPlayer?.volume = volume
//		}
//	}


	private let disposeBag = DisposeBag()


	init(playList: TIPlayList) {
		self.playList = playList
	}

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

	private func setupAudioPlayer(with url: NSURL) {

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
		asset.loadValuesAsynchronouslyForKeys(keys) {

			for key in keys {
				var error: NSError?
				let keyStatus = asset.statusOfValueForKey(key, error: &error)
				guard keyStatus != .Failed && error == nil else {

					// TODO: Alert that this can't be operated
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
		else {
			// rx_observe is simple KVO wrapper. Listening for status change.
			audioPlayer = AVPlayer(playerItem: playerItem)
			audioPlayer!
				.rx_observe(AVPlayerStatus.self, Constants.AVPLAYER_STATUS_KEY)
				.filter { $0 != nil }
				.shareReplayLatestWhileConnected()
				.debug("AudioPlayer Status Changed")
				.subscribeNext{ [weak self] status in
//					self?.playerStatus.value = status
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

			volume
				.asObservable()
				.distinctUntilChanged()
				.debug("volume update")
				.subscribeNext { [weak self] newVolume in
					self?.audioPlayer!.volume = newVolume
				}.addDisposableTo(disposeBag)
		}
	}
}
