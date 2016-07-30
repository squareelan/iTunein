//
//  TINetworkService.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

import Foundation
import SwiftyJSON

enum TINetworkError: ErrorType {
	case networkError(error: NSError)
	case serverError(code: Int)
	case noResponse
	case failedObjectMapping
	case invalidURL
	case invalidBody
	case invalidResponse

	static let TINetworkErrorDomain = "com.SQuareElan.TINetworkService"
}

struct TINetworkService {

	func simpleTIGetRequest<T: JsonDeserializable>(
		with url: String,
		callback: (Result<T>) -> Void
	) -> NSURLSessionDataTask? {


		// URL check
		guard let components = NSURLComponents(string: url) else {
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
			headers: nil, callback: callback
		)
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
		let dataTask = session.dataTaskWithRequest(urlRequest) { (data, response, err) in

			// validate for Error
			if let err = err {
				dispatch_async(dispatch_get_main_queue(), {
					callback(.failure(TINetworkError.networkError(error: err)))
				})
				return
			}

			// validate for data and response
			guard let data = data, let response = response as? NSHTTPURLResponse else {
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
}
