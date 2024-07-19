//
//  RavenDelegate.swift
//  
//
//  Created by Alex Anderson on 6/15/23.
//

import Foundation

public extension Raven {
    
    class DefaultDelegate: Raven.Delegate {}
    
    protocol Delegate: AnyObject {
        func getHttpHeader<T>(endpoint: Raven.Endpoint<T>) -> [String: String]
        func generateError(fromUrl url: URL, statusCode: HTTPStatusCode, responseData: Data) -> Error
        func decorate(request: URLRequest) -> URLRequest
        
        var jsonEncoder: JSONEncoder { get }
        var jsonDecoder: JSONDecoder { get }
        var networkRequestHandler: NetworkRequestHandler { get }
    }
    
}


// Provide defaults
public extension Raven.Delegate {
    func getHttpHeader<T>(endpoint: Raven.Endpoint<T>) -> [String: String] {
        [:]
    }

    func generateError(fromUrl url: URL, statusCode: HTTPStatusCode, responseData: Data) -> Error {
        RavenError.responseError(statusCode)
    }

    func decorate(request: URLRequest) -> URLRequest { request }

    var jsonEncoder: JSONEncoder { JSONEncoder() }
    var jsonDecoder: JSONDecoder { JSONDecoder() }
    var networkRequestHandler: Raven.NetworkRequestHandler { URLSession.shared }
}
