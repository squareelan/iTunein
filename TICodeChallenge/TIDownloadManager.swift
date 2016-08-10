//
//  TIDownloadManager.swift
//  iTuneIn
//
//  Created by Ian on 8/10/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

enum DownloadError: ErrorType {
	case generalError
}

import Foundation

final class TIDownloadManager: DownloadService {

	func download(with urlString: String, id: String, completion: (Result<NSURL>) -> ()) -> NSURLSessionDownloadTask? {

		guard let urlComponent = NSURLComponents(string: urlString),
			let url =  urlComponent.URL else {
			// failed
			completion(.failure(DownloadError.generalError))
			return nil
		}

		let session = NSURLSession.sharedSession()
		let task = session.downloadTaskWithURL(url) { tempLocation, response, error in

			// move it to permanant location
			let fileManager = NSFileManager.defaultManager()
			guard let tempLocation = tempLocation  else {

				// error handling
				dispatch_async(dispatch_get_main_queue()) {
					completion(.failure(DownloadError.generalError))
				}
				return
			}

			let path =
				NSSearchPathForDirectoriesInDomains(
					.DownloadsDirectory,
					.UserDomainMask,
					true
				).first!
			let itemPath = "\(path)/\(id)"
			guard let itemUrl = NSURL(string: itemPath) else {

				// error Handling
				dispatch_async(dispatch_get_main_queue()) {
					completion(.failure(DownloadError.generalError))
				}
				return
			}


			if !fileManager.fileExistsAtPath(itemPath) {
				do {

					try fileManager.moveItemAtURL(tempLocation, toURL: itemUrl)
				}
				catch let err as NSError {

					// error Handling
					dispatch_async(dispatch_get_main_queue()) {
						completion(.failure(err))
					}
				}
			}

			dispatch_async(dispatch_get_main_queue()) {
				// pass permanant location back
				completion(.success(itemUrl))
			}
		}

		return task
	}
}