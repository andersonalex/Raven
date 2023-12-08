//
//  RavenEndpoint.swift
//  
//
//  Created by Alex Anderson on 5/30/23.
//

import Foundation

public struct EmptyResponse: Decodable {}

public struct RavenEndpoint<ResponseDataType: Decodable> {

    enum RequestBody {
        case dict(BodyDictionary)
        case encodable(any Encodable)
    }

    let httpMethod: HTTPMethod
    let requestBody: RequestBody?
    let relativePath: String
    let urlParameters: [String: CustomStringConvertible?]
    let responseDataType: ResponseDataType.Type

    public init(
        httpMethod: HTTPMethod,
        path: String,
        requestBody: BodyDictionary,
        urlParameters: [String : CustomStringConvertible?] = [:],
        responseDataType: ResponseDataType.Type = EmptyResponse.self
    ) {
        self.httpMethod = httpMethod
        self.requestBody = .dict(requestBody)
        self.relativePath = path
        self.urlParameters = urlParameters
        self.responseDataType = responseDataType
    }

    public init(
        httpMethod: HTTPMethod,
        path: String,
        urlParameters: [String : CustomStringConvertible?] = [:],
        responseDataType: ResponseDataType.Type = EmptyResponse.self
    ) {
        self.httpMethod = httpMethod
        self.requestBody = nil
        self.relativePath = path
        self.urlParameters = urlParameters
        self.responseDataType = responseDataType
    }

    public init(
        httpMethod: HTTPMethod,
        path: String,
        requestBody: some Encodable,
        urlParameters: [String : CustomStringConvertible?] = [:],
        responseDataType: ResponseDataType.Type = EmptyResponse.self
    ) {
        self.httpMethod = httpMethod
        self.requestBody = .encodable(requestBody)
        self.relativePath = path
        self.urlParameters = urlParameters
        self.responseDataType = responseDataType
    }

    func url(fromBase baseURL: URL) -> URL? {
        let trimmedPath = relativePath.trimmingCharacters(in: .init(charactersIn: "/"))
        let fullURL = baseURL.appendingPathComponent(trimmedPath)

        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: true)
        components?.queryItems = urlParameters
            .filter { $0.value != nil }
            .flatMap { item in
                if let values = item.value as? [CustomStringConvertible] {
                    return values.map { URLQueryItem(name: item.key, value: $0.description) }
                } else {
                    return [URLQueryItem(name: item.key, value: item.value?.description)]
                }
            }

        return components?.url
    }
}

public protocol BodyDictionary {}

extension String: BodyDictionary {}
extension Int: BodyDictionary {}
extension Float: BodyDictionary {}
extension Double: BodyDictionary {}
extension Bool: BodyDictionary {}
extension Dictionary: BodyDictionary where Key == String, Value == BodyDictionary {}
