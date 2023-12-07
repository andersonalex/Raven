//
//  RavenDelegate.swift
//  
//
//  Created by Alex Anderson on 6/15/23.
//

import Foundation

public protocol RavenDelegate: AnyObject {
    func getHttpHeader<T>(endpoint: Endpoint<T>) -> Dictionary<String, String>
    func generateError(fromUrl url: URL, statusCode: HTTPStatusCode, responseData: Data) -> Error
    func decorate(request: URLRequest) -> URLRequest

    var jsonEncoder: JSONEncoder { get }
    var jsonDecoder: JSONDecoder { get }
}

// Provide defaults
public extension RavenDelegate {
    func getHttpHeader<T>(endpoint: Endpoint<T>) -> Dictionary<String, String> {
        [:]
    }

    func generateError(fromUrl url: URL, statusCode: HTTPStatusCode, responseData: Data) -> Error {
        RavenError.responseError
    }

    func decorate(request: URLRequest) -> URLRequest { request }

    var jsonEncoder: JSONEncoder { JSONEncoder() }
    var jsonDecoder: JSONDecoder { JSONDecoder() }
}
