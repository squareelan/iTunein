//
//  TIAppDelegate.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class TIAppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	let networkService = TINetworkServiceManager()
	let audioManager = TIAudioPlaybackManager(playList: TIPlayList(playItems: []))
	let favoriteListManager = TIFavoriteListManager()

	func application(
		application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?
	) -> Bool {

		// apply theme
		let theme = TITheme.Default
		TIThemeManager.applyTheme(theme)

		// setting sharedURLCache to greater capacity (50MB in memory, 100MB in disk)
		let memoryCapacity = 50 * 1024 * 1024 // 50MB
		let diskCapacity = 100 * 1024 * 1024 // 100MB
		let path =
			NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!

		let cache = NSURLCache(
			memoryCapacity: memoryCapacity,
			diskCapacity: diskCapacity,
			diskPath: path
		)
		NSURLCache.setSharedURLCache(cache)

		// enable background audio playback.
		let audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession.setCategory(AVAudioSessionCategoryPlayback)
			try	audioSession.setActive(true)
		}
		catch {
			print(error)
		}


		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

