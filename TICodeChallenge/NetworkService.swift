//
//  NetworkService.swift
//  TuneOut
//
//  Created by Ian on 8/3/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation
import UIKit

protocol NetworkService {

	func simpleTIGetRequest<T: JsonDecodable>(
		with urlString: String,
		     callback: (Result<T>) -> Void
	) -> NSURLSessionDataTask?

	func imageDownloadRequest(
		with urlString: String,
		     callback: (Result<UIImage>) -> Void
		) -> NSURLSessionDataTask?

	func request<T: JsonDecodable>(
		with url: NSURL,
		     method: HTTPMethod,
		     body: AnyObject?,
		     headers: [String: String]?,
		     callback: (Result<T>) -> Void
		) -> NSURLSessionDataTask?
}