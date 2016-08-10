//
//  DownloadService.swift
//  iTuneIn
//
//  Created by Ian on 8/10/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation

protocol DownloadService {
	func download(
		with urlString: String,
		     id: String,
		     completion: (Result<NSURL>) -> ()
		) -> NSURLSessionDownloadTask?
}