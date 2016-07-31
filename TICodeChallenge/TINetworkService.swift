//
//  TINetworkService.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

enum TINetworkError: ErrorType {
	case networkError(error: NSError)
	case serverError(code: Int)
	case noResponse
	case invalidDownloadLocation
	case failedObjectMapping
	case invalidURL
	case invalidBody
	case invalidResponse
	case invalidData

	static let TINetworkErrorDomain = "com.SQuareElan.TINetworkService"
}

final class TINetworkService {

	func simpleTIGetRequest<T: JsonDeserializable>(
		with urlString: String,
		callback: (Result<T>) -> Void
	) -> NSURLSessionDataTask? {

		// decoding and reEncoding due to data inconsistency
		// (URL fields in outline is sometimes encoded and sometimes not)
		let decoded = urlString.urlDecoded

		// URL check
		guard let components = NSURLComponents(string: decoded.urlEncoded) else {
			callback(.failure(TINetworkError.invalidURL))
			return nil
		}


		// render=json query
		if var queryItems = components.queryItems {

			// if other query exists, add to them.
			queryItems.append(
				NSURLQueryItem(
					name: "render", value: "json"
				)
			)
			components.queryItems = queryItems
		}
		else {
			components.queryItems = [NSURLQueryItem(
				name: "render", value: "json"
			)]
		}

		// final check with url (should never caught here)
		guard let url = components.URL else {
			callback(.failure(TINetworkError.invalidURL))
			return nil
		}

		return self.request(
			with: url,
			method: HTTPMethod.GET,
			body: nil,
			headers: nil,
			callback: callback
		)
	}

	func imageDownloadRequest(
		with urlString: String,
		callback: (Result<UIImage>) -> Void
	) -> NSURLSessionDataTask? {

		// decoding and reEncoding due to data inconsistency
		// (URL fields in outline is sometimes encoded and sometimes not)
		let decoded = urlString.urlDecoded

		guard let url = NSURL(string: decoded.urlEncoded) else {
			callback(.failure(TINetworkError.invalidURL))
			return nil
		}

		// create NSURLMutableRequest
		let urlRequest = NSMutableURLRequest(URL: url)
		urlRequest.HTTPMethod = HTTPMethod.GET.description

		// for image with is static, use more aggressive cache policy
		urlRequest.cachePolicy = NSURLRequestCachePolicy.ReturnCacheDataElseLoad

		let session = NSURLSession.sharedSession()
		let dataTask = session.dataTaskWithRequest(urlRequest) {
			[weak self] (data, response, error) in

			self?.validate(with: response, error: error, callback: callback)

			guard let data = data, let image = UIImage(data: data) else {
				dispatch_async(dispatch_get_main_queue(), {
					callback(.failure(TINetworkError.invalidData))
				})
				return
			}

			dispatch_async(dispatch_get_main_queue(), {
				callback(.success(image))
			})
		}

		dataTask.resume()

		return dataTask
	}

	func request<T: JsonDeserializable>(
		with url: NSURL,
		method: HTTPMethod,
		body: AnyObject?,
		headers: [String: String]?,
		callback: (Result<T>) -> Void
	) -> NSURLSessionDataTask? {

		// create NSURLMutableRequest
		let urlRequest = NSMutableURLRequest(URL: url)
		urlRequest.HTTPMethod = method.description


		// add bodyData
		if let body = body {

			// check if body is a valid json object
			guard NSJSONSerialization.isValidJSONObject(body) else {
				callback(.failure(TINetworkError.invalidBody))
				return nil
			}

			do {
				let body = try NSJSONSerialization.dataWithJSONObject(
					body,
					options: NSJSONWritingOptions(rawValue: 0)
				)
				urlRequest.HTTPBody = body
			} catch _ {
				callback(.failure(TINetworkError.invalidBody))
				return nil
			}
		}


		// add headers
		if let headers = headers {
			for header in headers {
				urlRequest.addValue(header.0, forHTTPHeaderField: header.1)
			}
		}


		// create dataTask
		let session = NSURLSession.sharedSession()
		let dataTask = session.dataTaskWithRequest(urlRequest) {
			[weak self] (data, response, error) in

			self?.validate(with: response, error: error, callback: callback)

			guard let data = data else {
				dispatch_async(dispatch_get_main_queue(), {
					callback(.failure(TINetworkError.invalidData))
				})
				return
			}

			do {
				let nsJson = try NSJSONSerialization.JSONObjectWithData(
					data,
					options: NSJSONReadingOptions.AllowFragments
				)

				// map json to object
				let swfityJson = JSON(nsJson)
				guard let object = T(with: swfityJson) else {
					dispatch_async(dispatch_get_main_queue(), {
						callback(.failure(TINetworkError.failedObjectMapping))
					})
					return
				}

				// Success!!
				print("[🐙\(TINetworkService.self)] response: \(nsJson)")
				dispatch_async(dispatch_get_main_queue(), {
					callback(.success(object))
				})

			} catch (let jsonError) {

				// json deserialization fail
				dispatch_async(dispatch_get_main_queue(), {
					callback(.failure(jsonError))
				})
			}
		}
		dataTask.resume()
		
		return dataTask
	}

	private func validate<T>(
		with response: NSURLResponse?,
		error: NSError?,
		callback: (Result<T>) -> Void
	) {

		// validate for Error
		if let error = error {
			dispatch_async(dispatch_get_main_queue(), {
				callback(.failure(TINetworkError.networkError(error: error)))
			})
			return
		}

		// validate for data and response
		guard let response = response as? NSHTTPURLResponse else {
			dispatch_async(dispatch_get_main_queue(), {
				callback(.failure(TINetworkError.noResponse))
			})
			return
		}

		// validate for response's status code
		guard response.statusCode >= 200 && response.statusCode < 300 else {
			dispatch_async(dispatch_get_main_queue(), {
				callback(.failure(TINetworkError.serverError(code: response.statusCode)))
			})
			return
		}
	}
}



