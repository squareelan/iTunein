//
//  TIAudioPlaybackService.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

protocol TIAudioPlaybackService {
	var audioPlayer: AVPlayer? { get set }
	var playList: TIPlayList { get set }

	var currentIndex: Variable<Int?> { get }
	var volume: Variable<Float> { get }
	var error: Variable<TIAudioPlaybackError?> { get }
	var isReady: Variable<Bool> { get }
	var isLoading: Variable<Bool> { get }
	var isPlaying: Variable<Bool> { get }


	func play()
	func pause()
	func togglePlay()
	func loadPreviousItem()
	func loadNextItem()
}