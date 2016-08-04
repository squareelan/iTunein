//
//  Result.swift
//  TICodeChallenge
//
//  Created by Ian on 7/29/16.
//  Copyright © 2016 Yongjun Yoo. All rights reserved.
//

enum Result<T> {
	case success(T)
	case failure(ErrorType)
}
