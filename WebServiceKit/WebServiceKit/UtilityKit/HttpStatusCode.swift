//
//  HttpStatusCode.swift
//  StartupProjectSampleA
//
//  Created by Towhid on 8/2/15.
//  Copyright (c) 2015 Towhid (m.towhid.islam@gmail.com). All rights reserved.
//

import Foundation

@objc(HttpStatusCode)
public enum HttpStatusCode: Int {
    
    case ok = 200
    case created = 201
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case poxyAuthRequired = 407
    case requestTimeout = 408
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
}
